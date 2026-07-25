# Ailtir Paperclip Changelog

This file records the state of Team Ailtir's downstream Paperclip deployment.
Upstream Paperclip release notes remain in [`releases/`][releases].

<!-- AILTIR-CURRENT:START -->
## Current State

- Upstream base: `cca2806e57c272ed919b1cde224d3d2a23d2f668`
- Ailtir source: `0ef3cd83dad73d681c7aa3f046d41da4e98b1669`
- Image tag: `0ef3cd83d`
- Image digest: `sha256:b42232768efb99ccae0ab498ec40044b38e81f5623ddf38d4f7cf5546a5aa33d`
- Infrastructure commit: `94376648e857510d81e37765e058f2040942d336`
- Live version: `0.3.1-0ef3cd83d`
- Verification: full tests, build, typecheck, ECR, Pulumi, ECS, live health, database backup, and CLI passed

## Active Downstream Patches

| Patch | Public source | Local commit | Upstream state | First deployed |
| --- | --- | --- | --- | --- |
| Ailtir deployment customizations | Ailtir | `ab33a771b` | downstream-only | before 2026-07-22 |
| CLI parity consolidation | Ailtir | `7f74580f9` | downstream-only | before 2026-07-22 |
| Ailtir image workflows | Ailtir | `8ea4c6548` | downstream-only | 2026-07-22 |
| Persisted deployment config | Ailtir | `28890bdd0` | downstream-only | 2026-07-22 |
| Local CLI workflow | Ailtir | `72812795f` | downstream-only | 2026-07-25 |
| Downstream maintenance workflow | Ailtir | `b21cf6bce` | downstream-only | 2026-07-25 |
| Preserve Cursor sandbox PATH | [upstream PR #10239](https://github.com/paperclipai/paperclip/pull/10239) | `fd633c40d` | proposed upstream | 2026-07-25 |
<!-- AILTIR-CURRENT:END -->

## History

### 2026-07-25 07:14 UTC

Deployed normalized Ailtir source `0ef3cd83d` through infrastructure `94376648e`; verified ECS, live health, healthy database backups, and local CLI.

### 2026-07-25

- Fixed Cursor sandbox command PATH preservation, reported it as upstream
  issue #10238, and proposed upstream PR #10239.
- Synchronized `master` with upstream at `cca2806e5`, rebuilt the downstream
  patch queue, and retired five package-version-only commits. Recovery tag:
  `ailtir-recovery-20260725-063535`.
- Established the downstream maintenance ledger before synchronizing with the
  latest upstream `master`.

[releases]: releases/
