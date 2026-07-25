---
name: build-install-cli
description: Build and globally install the Paperclip CLI from the latest Ailtir branch source, then verify the executable, version, and installed source. Use when asked to build, install, reinstall, or refresh the local `paperclipai` CLI from this repository rather than installing the published npm package.
---

# Build and Install the Paperclip CLI

Build an installable CLI package from the current `origin/ailtir` source and
install it globally. Do not publish packages, create commits, or push branches.

## Preconditions

1. Resolve the repository root with `git rev-parse --show-toplevel` and work
   from it.
2. Read the repository `AGENTS.md` before running the workflow.
3. Require `git status --porcelain` to be empty. Stop rather than switching
   branches or updating through unrelated local changes.
4. Switch to `ailtir`, fetch it, and update only by fast-forward:

   ```sh
   git switch ailtir
   git fetch origin ailtir
   git merge --ff-only origin/ailtir
   ```

5. Record the source and expected CLI version:

   ```sh
   source_commit=$(git rev-parse HEAD)
   expected_version=$(node -p "require('./cli/package.json').version")
   package_manager=$(node -p "require('./package.json').packageManager")
   ```

   Require `$package_manager` to start with `pnpm@`. Use the declared version
   even when a global or asdf-managed `pnpm` command is unavailable.

## Build and Install

1. Create a temporary detached worktree at `$source_commit`. Build there
   because the npm packaging script temporarily replaces `cli/package.json`.
2. Install the locked workspace dependencies with the repository-declared
   package manager:

   ```sh
   npx -y "$package_manager" install --frozen-lockfile
   ```

3. Build the publishable CLI package. A plain workspace CLI build is
   insufficient because its esbuild output externalizes transitive npm
   dependencies that are materialized only by the packaging step.

   ```sh
   npx -y "$package_manager" exec bash ./scripts/build-npm.sh --skip-typecheck
   ```

4. Pack and install the generated tarball:

   ```sh
   (cd cli && npm pack --pack-destination "$artifact_dir")
   npm install -g "$artifact_dir"/paperclipai-*.tgz
   hash -r
   ```

5. Remove the detached worktree and temporary artifacts. Confirm the main
   worktree is still clean.

## Verification

Run every check:

```sh
command -v paperclipai
test "$(paperclipai --version)" = "$expected_version"
paperclipai --help >/dev/null
npm ls -g paperclipai --depth=0
test "$(git rev-parse HEAD)" = "$source_commit"
test -z "$(git status --porcelain)"
```

Require `npm ls -g` to show `paperclipai@$expected_version`. An asdf shim path
from `command -v` is valid when the version and global package listing agree.

## Failure Handling

- Stop if the branch cannot be fast-forwarded or the worktree is not clean.
- Treat dependency installation or CLI build failures as blocking.
- Some optional native dependencies may report compilation failures and fall
  back to JavaScript. Treat them as warnings only when the package-manager
  command itself exits successfully.
- If installation succeeds but the executable is not found, run the active
  Node manager's reshim operation, refresh the shell command cache, and retry
  the verification. Do not install the registry package as a fallback.
- Do not edit manifests or lockfiles to force an installation unless the user
  explicitly asks for a packaging fix.

## Completion

Report the branch, full source commit, installed CLI version, verification
results, and whether the worktree remains clean.
