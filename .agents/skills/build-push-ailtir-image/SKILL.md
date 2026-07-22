---
name: build-push-ailtir-image
description: Stamp, build, and publish a Paperclip Docker image to Ailtir's AWS ECR repository, then commit and push the recorded package versions. Use when asked to build, publish, or push a new Ailtir Paperclip image, but not when asked to deploy an already-published image.
---

# Build and Push an Ailtir Image

Stamp one clean, pushed `ailtir` source commit, build and publish that immutable
SHA tag, then commit the stamp. Do not deploy it from this skill.

The order is mandatory:

```text
version-stamp → docker-build → docker-push → git commit/push
```

Do not create a commit between `docker-build` and `docker-push`. Both Make
invocations must resolve the same source commit SHA.

## Constants

- AWS account: `890742582948`
- AWS region: `eu-west-1`
- Source branch: `ailtir`

## Preconditions

1. Resolve the repository root with `git rev-parse --show-toplevel` and work
   from it.
2. Require `git branch --show-current` to return `ailtir`.
3. Require `git status --porcelain` to be empty. Never include unrelated
   changes in an image or stamp commit.
4. Fetch `origin ailtir` and require local HEAD to equal `origin/ailtir`.
5. Run `aws sts get-caller-identity` and require account `890742582948`.
   Stop on an unexpected account.
6. Record the source tag before changing the worktree:

   ```sh
   build_sha=$(git rev-parse --short=9 HEAD)
   source_commit=$(git rev-parse HEAD)
   ```

## Publish Workflow

1. Stamp the tracked server, CLI, and UI manifests:

   ```sh
   make version-stamp
   ```

2. Require the only changed files to be `server/package.json`,
   `cli/package.json`, and `ui/package.json`. Require all three versions to
   equal the expected source version:

   ```sh
   base_version=$(node -p "require('./server/package.json').version.replace(/-[0-9a-f]+$/i, '')")
   expected_version="${base_version}-${build_sha}"
   test "$(node -p "require('./server/package.json').version")" = "$expected_version"
   test "$(node -p "require('./cli/package.json').version")" = "$expected_version"
   test "$(node -p "require('./ui/package.json').version")" = "$expected_version"
   ```

3. Build the stamped worktree. `make docker-build` deliberately accepts these
   three generated modifications and tags the image with `$build_sha`:

   ```sh
   make docker-build
   ```

4. Verify the local immutable and `latest` tags exist and the built image
   contains the expected version:

   ```sh
   docker image inspect "paperclip:latest" "paperclip:$build_sha" >/dev/null
   image_version=$(docker run --rm --entrypoint node paperclip:latest \
     -p "require('/app/server/package.json').version")
   test "$image_version" = "$expected_version"
   ```

5. Authenticate after the successful build, then push through the Makefile.
   The Makefile owns ECR repository resolution and pushes both the immutable
   source tag and `latest`:

   ```sh
   ailtir-admin docker login
   AWS_REGION=eu-west-1 make docker-push
   ```

6. Confirm HEAD still equals `$source_commit`. Then commit exactly the three
   stamped manifests and push the stamp commit:

   ```sh
   test "$(git rev-parse HEAD)" = "$source_commit"
   git add server/package.json cli/package.json ui/package.json
   git diff --cached --name-only
   git commit -m "Stamp package versions for Ailtir image $build_sha"
   git push origin ailtir
   ```

7. Require the worktree to be clean and local `ailtir` to equal
   `origin/ailtir`.

## Failure Handling

- Before `docker-push`, stop without committing and report the failed gate.
- After `docker-push`, preserve the published immutable tag. If the stamp
  commit or push fails, report that the image exists but its recording commit
  is incomplete; retry only the commit/push portion without rebuilding.
- Never deploy or delete an image from this skill.

## Completion

Report the source commit, immutable image tag, visible package version, stamp
commit, and push result. Hand the immutable source tag to
`deploy-ailtir-image`.
