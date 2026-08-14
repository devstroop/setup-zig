#!/usr/bin/env bash
# setup-posix.sh — resolve and install the Zig compiler (Linux/macOS + resolve for Windows).
#
# Usage:
#   setup-posix.sh resolve   # env: INPUT_VERSION
#                            # emits zig-version, url, shasum, platform via $GITHUB_OUTPUT
#   setup-posix.sh install   # env: DOWNLOAD_URL, EXPECTED_SHA256
#                            # extracts to $RUNNER_TOOL_CACHE/setup-zig and prepends bin to $GITHUB_PATH
#
# Downloads come from ziglang.org/download/index.json, which is the canonical
# manifest of every release and the current nightly build, including per-platform
# tarball URLs and SHA-256 checksums.

set -euo pipefail

INDEX_URL="${INDEX_URL:-https://ziglang.org/download/index.json}"

python() {
    if command -v python3 >/dev/null 2>&1; then
        python3 "$@"
    else
        python "$@"
    fi
}

platform_key() {
    local os arch
    case "${RUNNER_OS:-$(uname -s)}" in
        Linux) os="linux" ;;
        macOS|Darwin) os="macos" ;;
        *) echo "setup-zig: unsupported OS: ${RUNNER_OS:-$(uname -s)}" >&2; exit 1 ;;
    esac
    case "${RUNNER_ARCH:-$(uname -m)}" in
        X86|x86) arch="x86" ;;
        X64|x86_64|amd64) arch="x86_64" ;;
        ARM|arm) arch="arm" ;;
        ARM64|aarch64|arm64) arch="aarch64" ;;
        *) echo "setup-zig: unsupported arch: ${RUNNER_ARCH:-$(uname -m)}" >&2; exit 1 ;;
    esac
    echo "${arch}-${os}"
}

fetch_index() {
    local tmp
    tmp="$(mktemp)"
    curl -fsSL --retry 3 --retry-delay 2 "$INDEX_URL" -o "$tmp"
    echo "$tmp"
}

emit() { # name value
    if [ -n "${GITHUB_OUTPUT:-}" ]; then
        echo "$1=$2" >> "$GITHUB_OUTPUT"
    else
        echo "$1=$2"
    fi
}

resolve() {
    local platform
    platform="$(platform_key)"
    local index
    index="$(fetch_index)"
    # Resolves the requested version and prints: resolved<TAB>url<TAB>shasum
    local info
    info="$(INPUT_VERSION="$INPUT_VERSION" platform="$platform" python - "$index" <<'PYEOF'
import json, os, sys

index_path = sys.argv[1]
requested = os.environ["INPUT_VERSION"] or "latest"
platform = os.environ["platform"]

with open(index_path) as f:
    index = json.load(f)

if requested == "latest":
    def key(v):
        return tuple(int(p) for p in v.split("."))
    releases = sorted((v for v in index if v != "master"), key=key)
    requested = releases[-1]
elif requested == "master":
    requested = "master"

if requested not in index:
    avail = ", ".join(sorted(v for v in index if v != "master"))
    sys.exit(f"setup-zig: version '{requested}' not found (available: latest, master, {avail})")

entry = index[requested]
plat = entry.get(platform)
if plat is None:
    avail = ", ".join(sorted(k for k in entry if isinstance(entry[k], dict) and "tarball" in entry[k]))
    sys.exit(f"setup-zig: no Zig build for platform '{platform}' (available: {avail})")

print(f"{entry.get('version') or requested}\t{plat['tarball']}\t{plat.get('shasum', '')}")
PYEOF
)"
    rm -f "$index"

    local resolved url shasum
    resolved="$(printf '%s\n' "$info" | cut -f1)"
    url="$(printf '%s\n' "$info" | cut -f2)"
    shasum="$(printf '%s\n' "$info" | cut -f3)"
    if [ -z "$resolved" ] || [ -z "$url" ]; then
        echo "setup-zig: failed to resolve a Zig build for platform '$platform'" >&2
        exit 1
    fi
    emit "zig-version" "$resolved"
    emit "platform" "$platform"
    emit "url" "$url"
    emit "shasum" "$shasum"
    echo "setup-zig: resolved version '$resolved' for '$platform'"
    echo "setup-zig: $url"
}

verify_sha256() { # file expected
    local actual
    if command -v sha256sum >/dev/null 2>&1; then
        actual="$(sha256sum "$1" | awk '{print $1}')"
    else
        actual="$(shasum -a 256 "$1" | awk '{print $1}')"
    fi
    actual="$(printf '%s' "$actual" | tr '[:upper:]' '[:lower:]')"
    expected="$(printf '%s' "$2" | tr '[:upper:]' '[:lower:]')"
    if [ "$actual" != "$expected" ]; then
        echo "setup-zig: SHA-256 mismatch for $1" >&2
        echo "  expected: $expected" >&2
        echo "  actual:   $actual" >&2
        exit 1
    fi
}

install() {
    local tool_cache="${RUNNER_TOOL_CACHE:?RUNNER_TOOL_CACHE is required}"
    # Global var: the EXIT trap must reference it after the function's
    # locals (incl. tmp) have gone out of scope.
    SETUP_ZIG_TMP="$(mktemp -d)"
    trap 'rm -rf "$SETUP_ZIG_TMP"' EXIT

    local archive="$SETUP_ZIG_TMP/zig-archive"
    echo "setup-zig: downloading $DOWNLOAD_URL"
    curl -fsSL --retry 3 --retry-delay 2 -o "$archive" "$DOWNLOAD_URL"

    verify_sha256 "$archive" "$EXPECTED_SHA256"

    case "$DOWNLOAD_URL" in
        *.zip)
            if [ "$(uname -s)" = "Linux" ]; then
                (cd "$SETUP_ZIG_TMP" && unzip -q "$archive")
            else
                (cd "$SETUP_ZIG_TMP" && tar -xf "$archive")
            fi
            ;;
        *.tar.xz)
            (cd "$SETUP_ZIG_TMP" && tar -xJf "$archive")
            ;;
        *)
            echo "setup-zig: unsupported archive: $DOWNLOAD_URL" >&2
            exit 1
            ;;
    esac

    local zig_dir
    zig_dir="$(find "$SETUP_ZIG_TMP" -maxdepth 1 -type d -name 'zig-*' | head -n 1)"
    if [ -z "$zig_dir" ]; then
        echo "setup-zig: extracted archive contains no 'zig-*' directory" >&2
        exit 1
    fi

    mkdir -p "$tool_cache/setup-zig"
    rm -rf "$tool_cache/setup-zig/zig"  # avoid nesting into a stale install
    mv "$zig_dir" "$tool_cache/setup-zig/zig"
    local installed="$tool_cache/setup-zig/zig"
    local bin_dir
    # Zig >= 0.15 ships the binary at the archive root (zig/zig);
    # older releases use zig/bin/zig.
    if [ -x "$installed/zig" ]; then
        bin_dir="$installed"
    elif [ -x "$installed/bin/zig" ]; then
        bin_dir="$installed/bin"
    else
        echo "setup-zig: zig binary not found under $installed (tried zig/ and bin/)" >&2
        exit 1
    fi
    "$bin_dir/zig" version >/dev/null
    echo "$bin_dir" >> "$GITHUB_PATH"
    echo "setup-zig: installed to $installed"
}

mode="${1:-}"
case "$mode" in
    resolve) resolve ;;
    install) install ;;
    *) echo "usage: $0 <resolve|install>" >&2; exit 2 ;;
esac
