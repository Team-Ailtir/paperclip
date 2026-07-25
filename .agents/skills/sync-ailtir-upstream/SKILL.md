---
name: sync-ailtir-upstream
description: Safely mirror paperclipai/paperclip master into Team-Ailtir master and rebase the Ailtir downstream patch queue. Use for upstream synchronization, ailtir rebases, consolidation of accelerated PRs that later landed upstream, or preparation before any Ailtir fix or deployment.
---

# Sync Ailtir Upstream

Treat `master` as a read-only upstream mirror and `ailtir` as a rebased patch
queue.

## Preconditions

1. Require the worktree to be clean and all remotes to match:
   `origin=Team-Ailtir/paperclip`, `upstream=paperclipai/paperclip`.
2. Run `scripts/preflight.sh`.
3. Capture the current `ailtir` tip, merge base, and upstream SHA.
4. Create and push recovery tag
   `ailtir-pre-rebase-YYYYMMDDTHHMMSSZ` at the old tip.

## Mirror master

Fetch both remotes with pruning. Switch to `master`, require it to contain no
local-only commits, fast-forward it to the captured `upstream/master`, and push
the explicit `master:master` ref to `origin`. Never merge downstream work into
`master`.

## Rebase ailtir

Switch to `ailtir` and run the ordinary rebase onto `master`. Do not use
`--reapply-cherry-picks`; exact upstream equivalents should be skipped.

For every conflict:

- drop a patch only after the upstream commit/PR and behavior cover it;
- preserve Ailtir-only intent rather than choosing one side mechanically;
- resolve modified upstream versions against the new API and tests;
- never retain both implementations merely to finish the rebase.

Afterward, compare the old and new stacks with `git range-diff`, require
`master` to be an ancestor, inspect `git cherry`, and run the full repository
verification.

Commit the verified candidate locally, then push that exact commit to
`ailtir-candidate/YYYYMMDDTHHMMSSZ`. Require the downstream `Ailtir CI`
workflow's aggregate check to pass for that commit. Only then push the same
commit to `ailtir:ailtir` with `--force-with-lease`. Confirm the remote
`ailtir` tip equals the CI-verified candidate SHA, then delete the remote
candidate branch.

GitHub Actions is a verification gate only. Build, image publication,
infrastructure mutation, deployment, and CLI installation remain local
workflows and must never be added to Ailtir CI.

## Initial normalization

On the first run, drop historical package-version-only commits, fold follow-up
skill refinements into their owning logical changes when safe, and retain only
current downstream behavior. The recovery tag is the rollback reference.
