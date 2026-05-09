# Initializing a Paperclip Instance

This document describes how to bootstrap a fresh Paperclip deployment — i.e. create the first instance admin so you can log in.

## When is this needed?

Only once per deployment, when the health endpoint reports:

```json
{"bootstrapStatus": "bootstrap_pending"}
```

Visit `https://paperclip.ailtir.ai/api/health` to confirm.

## How it works

The bootstrap process runs a one-off Fargate task using the current task definition. The task:

1. Writes a minimal config to `/tmp` (ephemeral — avoids volume permission issues)
2. Runs `paperclipai auth bootstrap-ceo` against the Aurora DB
3. Prints a one-time invite URL to CloudWatch logs
4. Exits

No ECS Exec or SSM agent required.

## Run it

From the `paperclip` repo root:

```sh
make docker-init
```

This calls [`scripts/docker-init.sh`][init-script], which runs the one-off ECS task and waits for it to complete, then prints the invite URL directly to your terminal.

## Claim the instance

Visit the invite URL printed by `make docker-init`:

```
https://paperclip.ailtir.ai/invite/pcp_bootstrap_<token>
```

Sign up with your email. You will be promoted to instance admin automatically.

The invite expires in **72 hours**. If it expires before you use it, run `make docker-init` again — it will revoke the old invite and create a new one.

## Prerequisites

- AWS credentials with ECS and CloudWatch Logs access (`ailtir-admin` profile)
- The paperclip ECS service must be running and healthy
- `aws` CLI installed

[init-script]: scripts/docker-init.sh
