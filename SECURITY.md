# Security Policy

## Supported versions

| Version | Supported          |
|---------|--------------------|
| v1      | :white_check_mark: |

## Reporting a vulnerability

Please do not open public issues for security concerns. Report vulnerabilities
privately to maintainers instead — see the repository owner's contact details.
Include:

- The affected version and release tag.
- A description of the vulnerability and its impact.
- Steps to reproduce, if possible.

We aim to acknowledge reports within 3 business days and to ship a fix in the
next release once a fix is validated.

## Toolchain integrity

The action verifies the SHA-256 checksum of every Zig download against the
official `ziglang.org/download/index.json` manifest before extraction. If the
checksum fails to verify, the action aborts — do not disable or bypass this
check.