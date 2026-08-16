# Changelog

All notable changes to this project are documented in this file, following
[Keep a Changelog](https://keepachangelog.com/) and pre-1.0 [SemVer](https://semver.org/).

## [Unreleased]

### Fixed

- Toolchain and global cache restores are now non-fatal (`continue-on-error`):
  a truncated or corrupt cache download (e.g. `gtar: Cannot write: Illegal
  byte sequence` from a partial zstd stream on macOS) can no longer fail the
  whole job.
- Added a `validate` step that checks a cache-restored toolchain actually runs
  (`zig version`) before using it; an invalid restore falls back to a fresh
  SHA-verified download, and the cache is re-saved so the next run heals.

## [1.0.0] - 2026-08-14

### Added

- Composite action with no Node runtime (immune to Node runtime deprecations).
- `version` input: exact release, `latest`, or `master` (nightly).
- Version resolution from the official `ziglang.org/download/index.json` manifest.
- SHA-256 verification of every download against the manifest.
- Toolchain and Zig global cache directory caching (`use-cache`, `cache-key` inputs).
- `zig-version` and `cache-hit` outputs.
- Test workflow covering 6 GitHub-hosted runners (macOS/Linux/Windows x arm64/x64)
  across pinned, latest, and master versions.
