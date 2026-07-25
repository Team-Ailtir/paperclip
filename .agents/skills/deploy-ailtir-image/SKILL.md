---
name: deploy-ailtir-image
description: Automatically deploy a verified immutable Paperclip image from Ailtir's AWS ECR repository through the sibling infrastructure repository, verify production, update the downstream changelog, then build and install the local CLI. Use after every successful Ailtir synchronization and image publication.
---

# Deploy an Ailtir Image

Deploy one explicit immutable Paperclip image tag through Pulumi, then verify
the ECS task and live health endpoint. A successful synchronized build is
authorization to continue without another confirmation. Never deploy `latest`.

## Constants

- AWS account: `890742582948`
- AWS region: `eu-west-1`
- ECR repository: the single repository named `paperclip-*`
- ECS cluster: `cluster-services-70768bd`
- ECS task family: `task-family-paperclip`
- Live health URL: `https://paperclip.ailtir.ai/api/health`
- Infrastructure branch: `main`

## Required Input

Require an explicit nine-character hexadecimal image tag. Do not recover a tag
from `latest`, local Docker state, or commit history. The build skill's output
is the preferred handoff.

## Preconditions

1. Run `aws sts get-caller-identity` and require account `890742582948`.
2. Read the live health payload before changing infrastructure. Require
   `databaseBackup.enabled` and `databaseBackup.status == "ok"`. Record the
   current image tag as the fix-forward reference.
3. Resolve exactly one ECR repository whose name starts with `paperclip-`.
   Stop when none or more than one match; do not guess. Query that repository
   for the requested tag and record its digest. Stop if it does not exist.

   ```sh
   repository_name=$(aws ecr describe-repositories --region eu-west-1 | jq -er \
     '[.repositories[] | select(.repositoryName | startswith("paperclip-"))] | if length == 1 then .[0].repositoryName else error("expected exactly one paperclip-* ECR repository") end')
   image_digest=$(aws ecr describe-images \
     --repository-name "$repository_name" \
     --image-ids "imageTag=$image_tag" \
     --region eu-west-1 \
     --query 'imageDetails[0].imageDigest' \
     --output text)
   test -n "$image_digest"
   test "$image_digest" != "None"
   ```
4. Resolve the infrastructure repository. Prefer `$AILTIR_INFRA_REPO` when set;
   otherwise use the `../infrastructure` sibling of the Paperclip repository.
   Resolve `skill_dir` as the directory containing this `SKILL.md`.
5. Require the infrastructure worktree to be clean and on `main`.
6. Run `git pull --ff-only origin main`, then require local HEAD to equal
   `origin/main`. Stop on local-only commits or divergence.

## Deployment Workflow

1. Record the existing tag in `src/service_paperclip.py` for rollback.
2. Run the bundled updater from this skill directory:

   ```sh
   python3 "$skill_dir/scripts/set-paperclip-image-tag.py" \
     --infrastructure-repo "$infrastructure_repo" \
     --tag "$image_tag"
   ```

3. Require the only worktree change to be `src/service_paperclip.py`. Inspect
   the diff and confirm it changes only the Paperclip image tag.
4. Run `make preview` in the infrastructure repository. Inspect the complete
   preview. Continue only when the changes are the expected Paperclip task
   definition/service rollout. Stop on unrelated resource changes or failures.
5. Commit and push the desired state:

   ```sh
   git add src/service_paperclip.py
   git commit -m "feat: deploy paperclip image $image_tag"
   git push origin main
   ```

6. Apply the already-previewed change:

   ```sh
   make up
   ```

7. Resolve the Paperclip ECS service ARN from `service-paperclip`, wait for it
   to become stable, and then inspect the running task definition. Require its
   container image to end in `:$image_tag`:

   ```sh
   service_arn=$(aws ecs list-services \
     --cluster cluster-services-70768bd \
     --region eu-west-1 \
     --query "serviceArns[?contains(@, 'service-paperclip')]|[0]" \
     --output text)
   test -n "$service_arn"
   test "$service_arn" != "None"
   aws ecs wait services-stable \
     --cluster cluster-services-70768bd \
     --services "$service_arn" \
     --region eu-west-1
   task_arn=$(aws ecs list-tasks \
     --cluster cluster-services-70768bd \
     --service-name "$service_arn" \
     --desired-status RUNNING \
     --region eu-west-1 \
     --query 'taskArns[0]' \
     --output text)
   task_definition=$(aws ecs describe-tasks \
     --cluster cluster-services-70768bd \
     --tasks "$task_arn" \
     --region eu-west-1 \
     --query 'tasks[0].taskDefinitionArn' \
     --output text)
   running_image=$(aws ecs describe-task-definition \
     --task-definition "$task_definition" \
     --region eu-west-1 \
     --query "taskDefinition.containerDefinitions[?name=='paperclip'].image|[0]" \
     --output text)
   test "${running_image##*:}" = "$image_tag"
   ```

8. Request the live health URL. Require HTTP success, `status: ok`, and a
   `version` or `serverVersion` containing the requested tag:

   ```sh
   health_json=$(curl -fsS https://paperclip.ailtir.ai/api/health)
   echo "$health_json" | jq -e '.status == "ok"' >/dev/null
   live_version=$(echo "$health_json" | jq -r '.version // .serverVersion // empty')
   case "$live_version" in
     *"$image_tag"*) ;;
     *) echo "Unexpected live version: $live_version" >&2; exit 1 ;;
   esac
   ```

9. Return to the Paperclip repository. Read the sibling
   `build-install-cli` skill at
   `.agents/skills/build-install-cli/SKILL.md` in full and execute its complete
   workflow. Require its CLI build, global link, version, help, and clean
   worktree checks to pass. Record the installed CLI version and global link
   target.

## Failure and Fix Forward

Do not report success until ECR, Pulumi, ECS, live health, the relevant
regression, and the local CLI agree. If any gate fails:

1. Report the exact failed gate.
2. Preserve both the requested and previous tags plus diagnostic output.
3. Classify and fix the source, integration, build, migration, infrastructure,
   configuration, or runtime cause.
4. Rebuild when source changed and repeat from the earliest invalidated gate.
5. Continue until production succeeds. Do not roll back automatically. Ask for
   help only when progress needs user judgment, credentials, or broader scope.

If step 9 fails after production verification succeeded, do not roll back the
deployment. Report that production is healthy on the requested tag, identify
the failed CLI build or installation gate, and leave the CLI failure available
for a targeted retry with `build-install-cli`.

After every successful deployment, execute `update-ailtir-changelog` with the
source SHA, image tag/digest, infrastructure commit, live version, and
verification result. Commit and push that record to `ailtir`.

## Completion

Report the infrastructure commit, image tag and digest, ECS service/task
identity, live version, health result, installed CLI version, and global CLI
link target. Do not report the entire workflow complete until the local CLI
verification passes.
