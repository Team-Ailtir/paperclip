---
name: build-push-ailtir-image
description: Build and publish an immutable Paperclip image from a clean Ailtir source commit while stamping package versions only inside an isolated build worktree. Use when publishing a synchronized Ailtir build; do not deploy the image or commit generated package versions.
---

# Build and Push an Ailtir Image

Publish one clean, pushed `ailtir` source commit. Package-version stamping is a
build artifact and must never create a commit on the downstream patch queue.

## Preconditions

1. Require the main checkout to be clean, on `ailtir`, and equal to
   `origin/ailtir`.
2. Require the root `CHANGELOG.md` current state to identify this maintenance
   cycle.
3. Run `aws sts get-caller-identity`; require account `890742582948`.
4. Record the full source commit and its nine-character image tag.

## Publish

Run `scripts/build-and-push.sh` from this skill directory. It must:

1. create a detached temporary worktree at the source commit;
2. run `make version-stamp` only there;
3. verify exactly the server, CLI, and UI manifests changed;
4. build and tag the Docker image with the clean source SHA;
5. verify the embedded package version contains that SHA;
6. authenticate through `ailtir-admin docker login`;
7. push the immutable tag and `latest` through the Makefile;
8. query and return the immutable ECR digest;
9. remove the temporary worktree and leave the main checkout unchanged.

Never commit the stamped manifests. Never deploy `latest`.

## Failure handling

Before push, stop and preserve build diagnostics. After push, preserve the
immutable tag and digest. A retry may reuse the same tag only when its ECR
digest matches the locally verified image; otherwise stop rather than
overwriting an immutable identity.

## Completion

Report source commit, image tag, digest, embedded version, and confirmation
that the main `ailtir` worktree remains clean and unchanged. Hand the immutable
tag to `deploy-ailtir-image`.
