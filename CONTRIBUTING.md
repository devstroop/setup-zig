# Contributing

Thanks for considering contributing to setup-zig.

## Development

- **Repository layout**: `action.yml` (composite action definition),
  `scripts/` (shell implementations), `.fixtures/` (Zig fixtures used by the
  test workflow), `.github/workflows/test.yml`.
- **No Node runtime**: the action is shell-only. Do not migrate it to a
  JavaScript action.
- **Test changes locally**: run the posix scripts directly:

  ```bash
  INPUT_VERSION=0.15.2 bash scripts/setup-posix.sh resolve
  DOWNLOAD_URL=<url> EXPECTED_SHA256=<shasum> \
    RUNNER_TOOL_CACHE=/tmp/tool RUNNER_TEMP=/tmp GITHUB_PATH=/tmp/path \
    bash scripts/setup-posix.sh install
  ```

- **Self-test matrix**: the test workflow exercises the action on six
  GitHub-hosted runners (macOS/Linux/Windows × arm64/x64) with pinned,
  `latest`, and `master` versions. Any new runner layout must be added there.

## Adding a feature

1. Open an issue describing the problem and the proposed change.
2. Keep v1 inputs backward compatible; new inputs must default to the current
   behavior.
3. Update README inputs/outputs tables and the CHANGELOG.
4. Add test coverage to `.github/workflows/test.yml`.

## Releasing

- Bump the version in `CHANGELOG.md`.
- Tag `v1` (moving) and `v1.x.y` on the release commit, and push tags.