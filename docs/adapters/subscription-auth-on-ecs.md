---
title: Subscription auth on ECS
summary: Run claude_local / codex_local / gemini_local against local subscriptions (no AWS Bedrock, no API keys) — claude via an injected CLAUDE_CODE_OAUTH_TOKEN, codex/gemini via credentials seeded onto the container's EFS home
---

The `claude_local`, `codex_local`, and `gemini_local` adapters all choose their auth
mode implicitly: subscription is the automatic fallback whenever the provider's
Bedrock/API-key environment variables are **absent** and the CLI can find a logged-in
credential. For a *local* execution target — the CLI spawned as an in-container
subprocess, which is the default for heartbeat runs — each CLI inherits the container's
environment and `$HOME`:

| Adapter | Credential source | Resulting billing |
|---------|-------------------|-------------------|
| `claude_local` | **`CLAUDE_CODE_OAUTH_TOKEN` env var** (injected from Secrets Manager) | `provider=anthropic`, `biller=anthropic`, `billingType=subscription` |
| `codex_local`  | `~/.codex/auth.json` (seeded onto EFS `$HOME`) | `provider=openai`, `biller=chatgpt`, `billingType=subscription` |
| `gemini_local` | `~/.gemini/` OAuth + `settings.json` (seeded onto EFS `$HOME`) | `provider=google`, `biller=google`, `billingType=subscription` |

On the Ailtir ECS/Fargate deployment `$HOME=/paperclip`, backed by a read-write EFS
access point. The server's `process.env` is inherited by every CLI subprocess it spawns
(`packages/adapter-utils/src/execution-target.ts`, `env: { ...process.env, ... }`), so
an injected `CLAUDE_CODE_OAUTH_TOKEN` reaches the `claude` CLI with no file on disk.

> **Do not set `ANTHROPIC_API_KEY` for paperclip.** `resolveClaudeBillingType`
> (`packages/adapters/claude-local/src/server/execute.ts`) switches Claude to
> **metered API** billing the moment that variable is non-empty. Subscription mode
> depends on it being unset, with `CLAUDE_CODE_OAUTH_TOKEN` supplying the auth.

> The Bedrock path (`CLAUDE_CODE_USE_BEDROCK=1`, `ANTHROPIC_MODEL=eu.anthropic.*`, the
> Bedrock IAM policy, and the `bedrock-runtime` VPC endpoint) has been removed from the
> `infrastructure` repo. With those gone, `claude_local` runs in subscription mode using
> the short model ID configured per agent (e.g. `claude-sonnet-4-6`).

## Claude — managed via Pulumi secret (no manual seeding)

Claude's credential is now infrastructure-as-code, in line with every other paperclip
secret: a Pulumi config secret → the `paperclip` AWS secret → the ECS task's `secrets`
block as `CLAUDE_CODE_OAUTH_TOKEN`. There is **no `aws ecs execute-command` step** for
Claude.

To set or rotate the token:

1. Generate a long-lived headless subscription token on your workstation:

   ```sh
   claude setup-token          # prints the CLAUDE_CODE_OAUTH_TOKEN value
   ```

2. Store it as an encrypted Pulumi secret (from the `infrastructure` repo):

   ```sh
   pulumi config set --secret infrastructure:claude_code_oauth_token <token>
   ```

3. Deploy:

   ```sh
   make -C infrastructure up
   ```

The wiring lives in `infrastructure/src/secrets.py`
(`claude_code_oauth_token = config.require_secret(...)`),
`infrastructure/src/secret_versions.py` (the `secret_paperclip_version` blob), and
`infrastructure/src/service_paperclip.py` (the task-definition `secrets` entry).

> **Token lifecycle.** `setup-token` tokens are long-lived (~1 year). Rotation is the
> three commands above — no shelling into the task. The old EFS-seeded
> `~/.claude/.credentials.json` is no longer required and can be ignored.

## Codex / Gemini — file seeding on EFS

Codex and Gemini still authenticate from credential files under `/paperclip`. They have
no equivalent long-lived headless-token env var, and Gemini in particular cannot log in
interactively in-container. Seed these only when you actually assign an agent to them.

### Prerequisites (already in place)

- **Egress:** the paperclip service security group already allows 443 → `0.0.0.0/0`
  via the NAT gateway, so the CLIs can reach OpenAI and Google.
- **ECS Exec:** the paperclip service runs with `enable_execute_command=True` and has the
  SSM VPC endpoints + `AmazonSSMManagedInstanceCore`, so you can shell into the running
  task to write the credential files.

### Seeding procedure

1. Log in locally on your workstation so the source files exist:
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
   base64 -w0 ~/.codex/auth.json   # copy the output
   ```

   Inside the task shell:

   ```sh
   mkdir -p /paperclip/.codex
   printf '%s' '<pasted-base64>' | base64 -d > /paperclip/.codex/auth.json
   chmod 600 /paperclip/.codex/auth.json
   chown -R 1000:1000 /paperclip/.codex
   ```

   Repeat for the contents of `~/.gemini/` → `/paperclip/.gemini/` (include
   `settings.json` so the CLI knows which auth type to use).

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
- **Remote/sandbox execution targets.** The `CLAUDE_CODE_OAUTH_TOKEN` env var covers the
  default in-container (local process) path. Remote/sandbox targets sanitize their env
  (`sanitizeRemoteExecutionEnv`) and seed a copied Claude config instead; if such targets
  are ever enabled, the token would need to be threaded through that config-seed path.
- **Billing is subscription-metered.** All three report `billingType=subscription`, so
  Paperclip's per-agent `budgetMonthlyCents` no longer maps to a metered dollar cost;
  usage draws down the subscription instead.
