#!/usr/bin/env bash
set -euo pipefail

pr=${1:?Usage: fetch-pr.sh PR_NUMBER}
case "$pr" in *[!0-9]* | "") echo "PR number must be numeric" >&2; exit 2 ;; esac
repo=$(git rev-parse --show-toplevel)
cd "$repo"
ref="refs/ailtir/pr/$pr"
git fetch upstream "pull/$pr/head:$ref"
base=$(git merge-base master "$ref")
jq -n \
  --arg pr "$pr" \
  --arg ref "$ref" \
  --arg head "$(git rev-parse "$ref")" \
  --arg base "$base" \
  --argjson commits "$(git rev-list --reverse "$base..$ref" | jq -R . | jq -s .)" \
  '{pr:($pr|tonumber),ref:$ref,head:$head,base:$base,commits:$commits}'
