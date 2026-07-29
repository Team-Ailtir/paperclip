# Ailtir Paperclip Changelog

This file records the state of Team Ailtir's downstream Paperclip deployment.
Upstream Paperclip release notes remain in [`releases/`][releases].

<!-- AILTIR-CURRENT:START -->
## Current State

- Upstream base: `ca92f727c5f7e4a6e5d23d05fef188bee9066b81`
- Ailtir source: `82072cc54`
- Image tag: `not published`
- Image digest: `not published`
- Infrastructure commit: `not deployed`
- Live version: `not deployed`
- Verification: pending

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
| Candidate-branch CI gate | Ailtir | `6fe067e9a` | downstream-only | 2026-07-25 |
| Preserve imported company goals | [upstream PR #10245](https://github.com/paperclipai/paperclip/pull/10245) | `1a17b5f4e` | proposed upstream | 2026-07-25 |
| Honor imported-agent approval policy | [upstream PR #10246](https://github.com/paperclipai/paperclip/pull/10246) | `8b014c73d` | proposed upstream | 2026-07-25 |
| Finalize pending agents before approvals | [upstream PR #10246](https://github.com/paperclipai/paperclip/pull/10246) | `0d46440f6` | proposed upstream | 2026-07-25 |
| Resolve Claude Bedrock defaults | [upstream PR #10247](https://github.com/paperclipai/paperclip/pull/10247) | `41421f48f` | proposed upstream | 2026-07-25 |
| Resolve Bedrock defaults before hire approval | [upstream PR #10247](https://github.com/paperclipai/paperclip/pull/10247) | `77f0343e1` | proposed upstream | 2026-07-25 |
| Atomic new-company imports | [upstream PR #10248](https://github.com/paperclipai/paperclip/pull/10248) | `028ccbdff` | proposed upstream | 2026-07-25 |
| Claude Sonnet 5 static catalog | [upstream PR #10280](https://github.com/paperclipai/paperclip/pull/10280) | `d7c06de6b`, `92a05c1e0` | proposed upstream; head `02c177c24` | pending |
| Tolerate unsupported ACP effort control | [upstream issue #10175](https://github.com/paperclipai/paperclip/issues/10175), [PR #10436](https://github.com/paperclipai/paperclip/pull/10436) | `eb86b60af` | proposed upstream; head `bef552d90`; CI green; Greptile 5/5 | pending |
<!-- AILTIR-CURRENT:END -->

## History

### 2026-07-29 13:44 UTC

Updated the portability unavailable-model fixture after Sonnet 5 became a supported Bedrock catalog entry; focused regression passed.

### 2026-07-29 13:18 UTC

Reconciled downstream worktree provisioning with the rebased CLI source-config requirement; focused entrypoint and workspace runtime tests: 103 passed.

### 2026-07-29 12:58 UTC

Synchronized the Ailtir patch queue to pinned upstream `ca92f727c`, integrated reviewed Sonnet 5 catalog PR #10280 at head `02c177c24`, and accelerated the green Greptile 5/5 ACP effort fix PR #10436 at head `bef552d90`. Focused tests: 17 adapter catalog tests and 87 ACPX engine tests.

### 2026-07-25 15:07 UTC

Validated ASDL import, approval, label-queue Claude/Bedrock execution, disabled heartbeat state, and persistence after forced ECS replacement.

### 2026-07-25 12:28 UTC

Synchronized against pinned upstream cca2806e5 (no new upstream commits), added four importer/Bedrock fixes proposed in upstream PRs #10245-#10248, and preserved recovery tag ailtir-pre-rebase-20260725T120454Z.

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
