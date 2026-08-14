# Changelog

All notable changes to this project are documented in this file, following
[Keep a Changelog](https://keepachangelog.com/) and pre-1.0 [SemVer](https://semver.org/).

## [Unreleased]

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
