#!/usr/bin/env bash
set -euo pipefail

repo=$(git rev-parse --show-toplevel)
cd "$repo"
test "$(git branch --show-current)" = ailtir
test -z "$(git status --porcelain)"
git fetch origin ailtir
test "$(git rev-parse HEAD)" = "$(git rev-parse origin/ailtir)"
account=$(aws sts get-caller-identity --query Account --output text)
test "$account" = 890742582948

source_commit=$(git rev-parse HEAD)
image_tag=$(git rev-parse --short=9 HEAD)
build_dir=$(mktemp -d)
cleanup() {
  git worktree remove --force "$build_dir" >/dev/null 2>&1 || true
}
trap cleanup EXIT
git worktree add --detach "$build_dir" "$source_commit" >/dev/null

cd "$build_dir"
make version-stamp
changed=$(git status --short | awk '{print $2}' | sort)
expected=$(printf '%s\n' cli/package.json server/package.json ui/package.json | sort)
test "$changed" = "$expected"
expected_version=$(node -p "require('./server/package.json').version")
case "$expected_version" in *-"$image_tag") ;; *) exit 1 ;; esac

make docker-build
docker image inspect "paperclip:$image_tag" >/dev/null
image_version=$(docker run --rm --entrypoint node "paperclip:$image_tag" \
  -p "require('/app/server/package.json').version")
test "$image_version" = "$expected_version"

ailtir-admin docker login
AWS_REGION=eu-west-1 make docker-push
repository_name=$(aws ecr describe-repositories --region eu-west-1 | jq -er \
  '[.repositories[] | select(.repositoryName | startswith("paperclip-"))]
   | if length == 1 then .[0].repositoryName else error("expected one paperclip-* repository") end')
digest=$(aws ecr describe-images \
  --repository-name "$repository_name" \
  --image-ids "imageTag=$image_tag" \
  --region eu-west-1 \
  --query 'imageDetails[0].imageDigest' \
  --output text)
test -n "$digest"
test "$digest" != None

cd "$repo"
test "$(git rev-parse HEAD)" = "$source_commit"
test -z "$(git status --porcelain)"
jq -n \
  --arg sourceCommit "$source_commit" \
  --arg imageTag "$image_tag" \
  --arg imageDigest "$digest" \
  --arg packageVersion "$image_version" \
  '{sourceCommit:$sourceCommit,imageTag:$imageTag,imageDigest:$imageDigest,packageVersion:$packageVersion}'
