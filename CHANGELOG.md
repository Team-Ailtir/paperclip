# Ailtir Paperclip Changelog

This file records the state of Team Ailtir's downstream Paperclip deployment.
Upstream Paperclip release notes remain in [`releases/`][releases].

<!-- AILTIR-CURRENT:START -->
## Current State

- Upstream base: `cca2806e57c272ed919b1cde224d3d2a23d2f668`
- Ailtir source: `pending normalized tip`
- Image tag: `c95d8daa4`
- Image digest: `unknown`
- Infrastructure commit: `00d246e`
- Live version: `0.3.1-c95d8daa4`
- Verification: normalized patch queue awaiting full verification and deployment

## Active Downstream Patches

| Patch | Public source | Local commit | Upstream state | First deployed |
| --- | --- | --- | --- | --- |
| Ailtir deployment customizations | Ailtir | `ab33a771b` | downstream-only | before 2026-07-22 |
| CLI parity consolidation | Ailtir | `7f74580f9` | downstream-only | before 2026-07-22 |
| Ailtir image workflows | Ailtir | `8ea4c6548` | downstream-only | 2026-07-22 |
| Persisted deployment config | Ailtir | `28890bdd0` | downstream-only | 2026-07-22 |
| Local CLI workflow | Ailtir | `72812795f` | downstream-only | not deployed |
| Downstream maintenance workflow | Ailtir | `b21cf6bce` | downstream-only | not deployed |
<!-- AILTIR-CURRENT:END -->

## History

### 2026-07-25

- Synchronized `master` with upstream at `cca2806e5`, rebuilt the downstream
  patch queue, and retired five package-version-only commits. Recovery tag:
  `ailtir-recovery-20260725-063535`.
- Established the downstream maintenance ledger before synchronizing with the
  latest upstream `master`.

[releases]: releases/
