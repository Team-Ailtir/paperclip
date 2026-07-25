---
name: update-ailtir-changelog
description: Maintain the root Ailtir CHANGELOG.md as the authoritative current-state and deployment ledger. Use after upstream synchronization, downstream patch changes, image publication, production deployment, rollback decisions, or verification changes.
---

# Update the Ailtir Changelog

Use `scripts/update-changelog.py`; do not edit generated current-state markers
by hand.

Before a build, record the pinned upstream SHA, source SHA, active patch table,
and a synchronization history entry. Commit and push so the image is built
from a clean, recorded source commit.

After deployment, record the exact source SHA, image tag/digest, infrastructure
commit, live version, deployment time, and verification summary. Append a
newest-first deployment entry, then commit and push.

Validate every recorded value against Git, ECR, infrastructure, ECS, and the
live health endpoint. Use `unknown` rather than guessing. Remove a patch from
the active table only after upstream absorption is verified; retain its
retirement in history.
