---
name: maintain-ailtir
description: Run the complete Team-Ailtir Paperclip downstream maintenance cycle. Use when synchronizing the fork with paperclipai/paperclip, rebasing the ailtir patch queue, publishing and deploying an Ailtir image, or refreshing the authoritative downstream changelog.
---

# Maintain Ailtir

Run one pinned, auditable maintenance cycle. An explicit invocation authorizes
deployment after every gate passes; it does not create a schedule.

## Preconditions

1. Work in the `Team-Ailtir/paperclip` fork.
2. Read these sibling skills completely:
   - `sync-ailtir-upstream`
   - `update-ailtir-changelog`
   - `build-push-ailtir-image`
   - `deploy-ailtir-image`
   - `build-install-cli`
3. Require clean Paperclip and infrastructure worktrees.
4. Capture state with `scripts/inspect-state.py`. Pin the reported upstream
   SHA for this cycle even if upstream moves later.

## Cycle

1. Execute `sync-ailtir-upstream`.
2. Update the changelog current patch inventory and append a synchronization
   event. Commit and push it before building.
3. Install locked dependencies with the declared package manager.
4. Run `pnpm typecheck`, `pnpm test:run`, and `pnpm build`.
5. Push the exact source commit to an `ailtir-candidate/<timestamp>` branch,
   require the read-only `Ailtir CI` aggregate check to pass, promote that
   commit to `origin/ailtir`, and delete the candidate branch.
6. Execute `build-push-ailtir-image` locally; its clean source SHA is the image
   tag. GitHub Actions must not publish the image.
7. Execute `deploy-ailtir-image` locally and automatically.
8. Verify production health, version, database backup status, the synchronized
   bug regression when applicable, and the locally linked CLI.
9. Update the changelog with the image digest, infrastructure commit, live
   version, and verification. Commit and push the post-deployment record.

## Failure policy

Do not bypass a failed gate. Diagnose whether it is an upstream regression,
downstream patch, build, migration, infrastructure, configuration, or runtime
failure. Fix forward, restart at the earliest invalidated gate, and continue
until production succeeds. Preserve the previous image identity but do not
roll back automatically. Ask for help only when further progress needs user
judgment, credentials, or broader authority.

## Completion

Report the pinned upstream SHA, rebased source SHA, active patches, image tag
and digest, infrastructure commit, ECS task, live version, CLI version, tests,
retries, and final changelog commit.
