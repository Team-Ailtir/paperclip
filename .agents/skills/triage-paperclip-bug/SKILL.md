---
name: triage-paperclip-bug
description: Reproduce and classify a Paperclip defect, search upstream issues and PRs, and select the strongest verifiable fix. Use when a Paperclip bug is observed in source or production and it is not yet clear whether it is known, fixed upstream, Ailtir-specific, infrastructure-related, or configuration-related.
---

# Triage a Paperclip Bug

Synchronize first unless the task explicitly requires preserving the failing
revision.

1. Record the exact symptom, version, deployment mode, inputs, logs, and
   expected behavior.
2. Reproduce against updated `master`; then compare `ailtir`.
3. Search open and closed upstream issues and PRs using exact errors, route or
   symbol names, and behavioral descriptions. Read bodies, patches, comments,
   checks, reviews, and current head SHAs.
4. Classify the cause as upstream source, Ailtir patch, infrastructure,
   configuration, or external dependency.
5. Evaluate every plausible PR in an isolated worktree. Prefer the smallest
   patch that fixes the reproduction without regression; upstream review state
   informs risk but is not a prerequisite.
6. Produce an evidence table and one selected action.

Use `integrate-paperclip-pr` for a selected fix. If no issue and complete fix
exist, use `contribute-paperclip-fix`.

Never infer that a title matches. Never silently change models, providers, or
security posture as a workaround.
