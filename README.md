# Setup Zig

Install the [Zig](https://ziglang.org) compiler in GitHub Actions, and cache the
Zig build cache across runs. Version-agnostic: works with any Zig project and any
Zig version — pinned releases, `latest`, or nightly `master`.

A **composite action** (shell only, no Node runtime), so it is immune to Node
runtime deprecations and needs no `dist/` build step.

## Usage

```yaml
steps:
  - uses: actions/checkout@v5

  - uses: devstroop/setup-zig@v1
    with:
      version: 0.15.2   # optional; default 'latest'

  - run: zig version
  - run: zig build test
```

### Matrix usage

```yaml
jobs:
  build:
    strategy:
      matrix:
        os: [ubuntu-latest, ubuntu-24.04-arm, macos-15, macos-15-intel, windows-latest, windows-11-arm]
    runs-on: ${{ matrix.os }}
    steps:
      - uses: devstroop/setup-zig@v1
        with:
          version: 0.15.2
          cache-key: ${{ matrix.os }}   # one cache per matrix cell
```

## Inputs

| Input       | Default    | Description                                                                 |
|-------------|------------|-----------------------------------------------------------------------------|
| `version`   | `latest`   | Zig version: exact release (e.g. `0.15.2`), `latest`, or `master` (nightly). |
| `use-cache` | `true`     | Cache the downloaded toolchain and the Zig global cache directory.          |
| `cache-key` | `''`       | Extra component appended to the global-cache key (e.g. matrix variables).   |

## Outputs

| Output        | Description                                        |
|---------------|----------------------------------------------------|
| `zig-version` | Resolved Zig version that was installed.           |
| `cache-hit`   | `"true"` when the toolchain was restored from cache. |

## How it works

1. **Resolve** — fetches `ziglang.org/download/index.json` (the canonical
   manifest of every release and the nightly build) and resolves the requested
   version + the correct archive for the runner (`runner.os` × `runner.arch`).
2. **Restore** — the toolchain and the Zig global cache directory are restored
   from GitHub Actions cache (two independent keys).
3. **Download & verify** — on a cache miss the archive is downloaded (3 retries)
   and its **SHA-256 is verified against the manifest** before extraction.
4. **Install** — extracts into `$RUNNER_TOOL_CACHE/setup-zig` and prepends its
   `bin` directory to `PATH`. The Zig global cache is redirected to the cached
   directory via `ZIG_GLOBAL_CACHE_DIR`.
5. **Save** — both caches are saved for the next run.

## Cache keys

| Cache                | Key                                                                |
|----------------------|--------------------------------------------------------------------|
| Toolchain            | `setup-zig-toolchain-<os>-<arch>-<version>`                        |
| Zig global cache     | `setup-zig-global-cache-<os>-<arch>-<cache-key>` (prefix-restored) |

## Supported platforms

| Runner                     | Platform key     |
|----------------------------|------------------|
| `macos-15`                 | `aarch64-macos`  |
| `macos-15-intel`           | `x86_64-macos`   |
| `ubuntu-latest`            | `x86_64-linux`   |
| `ubuntu-24.04-arm`         | `aarch64-linux`  |
| `windows-latest`           | `x86_64-windows` |
| `windows-11-arm`           | `aarch64-windows`|

Zig releases are downloaded from the official `ziglang.org/download` URLs.

## Roadmap (not in v1)

- `minimum_zig_version` auto-resolution from `build.zig.zon`
- Custom download mirrors
- Zig cache size limits

## License

[MIT](LICENSE)
