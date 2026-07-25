#!/usr/bin/env bash
set -euo pipefail

repo=$(git rev-parse --show-toplevel)
cd "$repo"
test -z "$(git status --porcelain)" || {
  echo "Paperclip worktree is not clean" >&2
  exit 1
}
test "$(git remote get-url origin)" = "https://github.com/Team-Ailtir/paperclip.git"
test "$(git remote get-url upstream)" = "https://github.com/paperclipai/paperclip.git"
upstream_sha=$(git ls-remote upstream refs/heads/master | awk '{print $1}')
origin_master=$(git ls-remote origin refs/heads/master | awk '{print $1}')
origin_ailtir=$(git ls-remote origin refs/heads/ailtir | awk '{print $1}')
test -n "$upstream_sha"
test -n "$origin_master"
test -n "$origin_ailtir"
jq -n \
  --arg upstreamMaster "$upstream_sha" \
  --arg originMaster "$origin_master" \
  --arg originAiltir "$origin_ailtir" \
  --arg localMaster "$(git rev-parse master)" \
  --arg localAiltir "$(git rev-parse ailtir)" \
  '{upstreamMaster:$upstreamMaster,originMaster:$originMaster,originAiltir:$originAiltir,localMaster:$localMaster,localAiltir:$localAiltir}'
