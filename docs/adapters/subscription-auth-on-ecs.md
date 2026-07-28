---
title: Subscription auth on ECS
summary: Run claude_local / codex_local / gemini_local against local subscriptions (no AWS Bedrock, no API keys) by seeding credentials onto the container's EFS home
---

The `claude_local`, `codex_local`, and `gemini_local` adapters all choose their auth
mode implicitly: subscription is the automatic fallback whenever the provider's
Bedrock/API-key environment variables are **absent** and the CLI's credential home is
logged in. For a *local* execution target — the CLI spawned as an in-container
subprocess, which is the default for heartbeat runs — each CLI inherits the container's
`$HOME` and reads its credentials directly:

| Adapter | Credential file (under `$HOME`) | Resulting billing |
|---------|----------------------------------|-------------------|
| `claude_local` | `~/.claude/.credentials.json` | `provider=anthropic`, `biller=anthropic`, `billingType=subscription` |
| `codex_local`  | `~/.codex/auth.json`          | `provider=openai`, `biller=chatgpt`, `billingType=subscription` |
| `gemini_local` | `~/.gemini/` (OAuth + `settings.json`) | `provider=google`, `biller=google`, `billingType=subscription` |

On the Ailtir ECS/Fargate deployment `$HOME=/paperclip`, backed by a read-write EFS
access point. Seeding the credential files there is a one-time step per subscription:
because EFS is read-write, each CLI's automatic token refresh persists back to EFS and
survives task restarts.

> The Bedrock path (`CLAUDE_CODE_USE_BEDROCK=1`, `ANTHROPIC_MODEL=eu.anthropic.*`, the
> Bedrock IAM policy, and the `bedrock-runtime` VPC endpoint) has been removed from the
> `infrastructure` repo. With those gone, `claude_local` runs in subscription mode using
> the short model ID configured per agent (e.g. `claude-sonnet-4-6`).

## Prerequisites (already in place)

- **Egress:** the paperclip service security group already allows 443 → `0.0.0.0/0`
  via the NAT gateway, so the CLIs can reach `api.anthropic.com`, OpenAI, and Google.
- **ECS Exec:** the paperclip service runs with `enable_execute_command=True` and has the
  SSM VPC endpoints + `AmazonSSMManagedInstanceCore`, so you can shell into the running
  task to write the credential files.

## Seeding procedure

Required for the currently-assigned adapter (`claude_local`). Seed `codex_local` /
`gemini_local` only when you actually assign an agent to them.

1. Log in locally on your workstation so the source files exist:
   - `claude login`  → `~/.claude/.credentials.json`
   - `codex login`   → `~/.codex/auth.json`
   - `gemini auth login` → `~/.gemini/` (OAuth creds + `settings.json`)

2. Open a shell in the running task (region `eu-west-1`):

   ```sh
   aws ecs execute-command \
     --cluster <cluster> --task <task-id> \
     --container paperclip --interactive --command "/bin/sh"
   ```

3. Recreate each credential file under `/paperclip`. The files are small, so a
   base64 round-trip is the simplest transfer. On your workstation:

   ```sh
   base64 -w0 ~/.claude/.credentials.json   # copy the output
   ```

   Inside the task shell:

   ```sh
   mkdir -p /paperclip/.claude
   printf '%s' '<pasted-base64>' | base64 -d > /paperclip/.claude/.credentials.json
   chmod 600 /paperclip/.claude/.credentials.json
   chown -R 1000:1000 /paperclip/.claude
   ```

   Repeat for `~/.codex/auth.json` → `/paperclip/.codex/auth.json` and the contents of
   `~/.gemini/` → `/paperclip/.gemini/` (include `settings.json` so the CLI knows which
   auth type to use).

4. Force a new deployment so runs start from the seeded `$HOME`:

   ```sh
   aws ecs update-service --cluster <cluster> --service <service> --force-new-deployment
   ```

## Caveats

- **Codex refresh tokens are single-use / rotating.** Running the *same* Codex
  subscription concurrently on your laptop and in the container can invalidate one
  side's session. Prefer a dedicated login for the container, or only seed Codex when
  an agent is assigned to it.
- **Gemini cannot log in interactively in-container.** The adapter runs Gemini headless
  (`NO_BROWSER=1`), which fails fast instead of opening a browser — so its credentials
  must be seeded as files (no `gemini auth login` inside the task). Note this is a
  *local execution target* running in a container; the "remote/sandbox needs an API key"
  limitation applies only to genuine remote/sandbox execution targets, not this path.
- **Billing is subscription-metered.** All three report `billingType=subscription`, so
  Paperclip's per-agent `budgetMonthlyCents` no longer maps to a metered dollar cost;
  usage draws down the subscription instead.
