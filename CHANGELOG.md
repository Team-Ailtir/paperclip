# Ailtir Paperclip Changelog

This file records the state of Team Ailtir's downstream Paperclip deployment.
Upstream Paperclip release notes remain in [`releases/`][releases].

<!-- AILTIR-CURRENT:START -->
## Current State

- Upstream base: `7985c1e000932d66a4f5385bf38488bca610afff`
- Ailtir source: `c4ebe36da5e5bcc42282a12f512aaab23b151a21`
- Image tag: `c95d8daa4`
- Image digest: `unknown`
- Infrastructure commit: `00d246e`
- Live version: `0.3.1-c95d8daa4`
- Verification: live health reports `ok`; downstream maintenance migration pending

## Active Downstream Patches

| Patch | Public source | Local commit | Upstream state | First deployed |
| --- | --- | --- | --- | --- |
| Ailtir deployment customizations | Ailtir | `bed4a7b83` | downstream-only | before 2026-07-22 |
| CLI parity consolidation | Ailtir | `22b805a31` | verify during next sync | before 2026-07-22 |
| Ailtir image workflows | Ailtir | `211bba595` | downstream-only | 2026-07-22 |
| Persisted deployment config | Ailtir | `c95d8daa4` | verify during next sync | 2026-07-22 |
| Local CLI workflow | Ailtir | `0fc8528b4` | downstream-only | not deployed |
<!-- AILTIR-CURRENT:END -->

## History

### 2026-07-25

- Established the downstream maintenance ledger before synchronizing with the
  latest upstream `master`.

[releases]: releases/
