---
name: integrate-paperclip-pr
description: Validate and cherry-pick an unmerged upstream Paperclip pull request into the Ailtir patch queue with provenance and regression evidence. Use when Ailtir needs an upstream fix before paperclipai/paperclip merges it.
---

# Integrate a Paperclip PR

1. Execute `sync-ailtir-upstream`.
2. Fetch the PR with `scripts/fetch-pr.sh PR_NUMBER`.
3. Inspect the public issue, PR body, current head SHA, commit series, diff,
   checks, reviews, unresolved comments, and merge conflicts.
4. Test the unmodified PR in an isolated worktree against the reproduced bug.
5. Select the minimum complete commit series. If `master` already contains the
   behavior, do not cherry-pick it.
6. On `ailtir`, cherry-pick commits in order with `-x`. Do not merge the PR
   branch or flatten contributor attribution.
7. Resolve downstream conflicts semantically, rerun the regression and full
   gates, and record the PR/head/test evidence in `CHANGELOG.md`.
8. Push only through the maintenance workflow.

When upstream later merges the fix, ordinary rebase should drop an exact
equivalent. If upstream rewrites it, use `range-diff` and regression evidence
before dropping the accelerated patch.
