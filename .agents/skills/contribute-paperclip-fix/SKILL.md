---
name: contribute-paperclip-fix
description: Report a new upstream Paperclip bug, implement its focused fix from upstream master, open a compliant PR, and accelerate the same commits into Ailtir. Use after triage finds no adequate public issue and fix PR.
---

# Contribute a Paperclip Fix

1. Execute `sync-ailtir-upstream`.
2. Create a public `paperclipai/paperclip` issue from the applicable template.
   Include a minimal reproduction, expected behavior, exact commit/version,
   deployment mode, impact, and sanitized evidence.
3. Create a dedicated Git worktree from the pinned `upstream/master` SHA.
   Name the branch descriptively without private ticket identifiers.
4. Implement the smallest complete fix and regression test.
5. Read and execute `prepare-paperclip-pr` fully. Push the feature branch to
   `origin` and open the PR against `paperclipai/paperclip:master`, linking the
   public issue.
6. Reach the repository’s required local checks, CI, and Greptile standard.
7. Cherry-pick the reviewed commits into `ailtir` with `-x`, preserving author
   attribution. Record the issue, PR, head SHA, and tests in `CHANGELOG.md`.
8. Continue through the normal build and deployment cycle.

Never merge the upstream PR yourself. Never expose private Paperclip issue IDs,
instance URLs, credentials, or production data in the public issue or PR.
