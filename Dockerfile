# syntax=docker/dockerfile:1.20
FROM node:lts-trixie-slim AS base
ARG USER_UID=1000
ARG USER_GID=1000
RUN apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates gosu curl gh git wget ripgrep python3 \
  && rm -rf /var/lib/apt/lists/* \
  && corepack enable

# Modify the existing node user/group to have the specified UID/GID to match host user
RUN usermod -u $USER_UID --non-unique node \
  && groupmod -g $USER_GID --non-unique node \
  && usermod -g $USER_GID -d /paperclip node

FROM base AS deps
WORKDIR /app
COPY package.json pnpm-workspace.yaml pnpm-lock.yaml .npmrc ./
COPY cli/package.json cli/
COPY server/package.json server/
COPY ui/package.json ui/
COPY packages/shared/package.json packages/shared/
COPY packages/db/package.json packages/db/
COPY packages/adapter-utils/package.json packages/adapter-utils/
COPY packages/google-sheets-mcp-server/package.json packages/google-sheets-mcp-server/
COPY packages/kv-demo-mcp-server/package.json packages/kv-demo-mcp-server/
COPY packages/mcp-server/package.json packages/mcp-server/
COPY packages/skills-catalog/package.json packages/skills-catalog/
COPY packages/teams-catalog/package.json packages/teams-catalog/
COPY packages/adapters/claude-local/package.json packages/adapters/claude-local/
COPY packages/adapters/codex-local/package.json packages/adapters/codex-local/
COPY packages/adapters/cursor-cloud/package.json packages/adapters/cursor-cloud/
COPY packages/adapters/cursor-local/package.json packages/adapters/cursor-local/
COPY packages/adapters/gemini-local/package.json packages/adapters/gemini-local/
COPY packages/adapters/grok-local/package.json packages/adapters/grok-local/
COPY packages/adapters/hermes/package.json packages/adapters/hermes/
COPY packages/adapters/hermes-gateway/package.json packages/adapters/hermes-gateway/
COPY packages/adapters/openclaw-gateway/package.json packages/adapters/openclaw-gateway/
COPY packages/adapters/opencode-local/package.json packages/adapters/opencode-local/
COPY packages/adapters/pi-local/package.json packages/adapters/pi-local/
COPY packages/plugins/sdk/package.json packages/plugins/sdk/
COPY --parents packages/plugins/sandbox-providers/./*/package.json packages/plugins/sandbox-providers/
COPY packages/plugins/paperclip-plugin-fake-sandbox/package.json packages/plugins/paperclip-plugin-fake-sandbox/
COPY packages/plugins/plugin-llm-wiki/package.json packages/plugins/plugin-llm-wiki/
COPY packages/plugins/plugin-workspace-diff/package.json packages/plugins/plugin-workspace-diff/
COPY patches/ patches/
COPY scripts/link-plugin-dev-sdk.mjs scripts/

RUN pnpm install --frozen-lockfile

FROM base AS build
WORKDIR /app
COPY --from=deps /app /app
COPY . .
RUN pnpm --filter @paperclipai/ui build
RUN pnpm --filter @paperclipai/plugin-sdk build
RUN pnpm --filter @paperclipai/server build
RUN test -f server/dist/index.js || (echo "ERROR: server build output missing" && exit 1)

FROM base AS production
ARG USER_UID=1000
ARG USER_GID=1000
# Real version for this build, computed from `git describe` on the CI runner
# (the image has no .git, so the server cannot derive it at runtime). Empty for
# local `docker build`, which just leaves the server on its normal fallbacks.
ARG PAPERCLIP_BUILD_VERSION=""
ARG AWS_CLI_VERSION=2.35.21
ARG PULUMI_VERSION=3.253.0
ARG TARGETARCH
WORKDIR /app
# This layer only installs global CLI tools and system packages - nothing
# here depends on /app, so it's ordered before the build-output COPY below.
# That keeps it cached across releases that only touch app source or
# package.json versions (e.g. version-stamp), instead of re-fetching the
# CLIs/AWS CLI/Pulumi on every deploy.
COPY --from=ghcr.io/astral-sh/uv:0.11.1 /uv /uvx /usr/local/bin/
RUN npm install --global --omit=dev @anthropic-ai/claude-code@latest @openai/codex@latest opencode-ai @google/gemini-cli@latest \
  && apt-get update \
  && apt-get install -y --no-install-recommends openssh-client jq unzip make groff less \
  && case "$TARGETARCH" in \
       amd64) AWS_ARCH=x86_64; PULUMI_ARCH=x64 ;; \
       arm64) AWS_ARCH=aarch64; PULUMI_ARCH=arm64 ;; \
       *) echo "Unsupported architecture: $TARGETARCH" >&2; exit 1 ;; \
     esac \
  && mkdir -p /tmp/tool-install \
  && curl --fail --silent --show-error --location \
       "https://awscli.amazonaws.com/awscli-exe-linux-${AWS_ARCH}-${AWS_CLI_VERSION}.zip" \
       --output /tmp/tool-install/awscliv2.zip \
  && unzip -q /tmp/tool-install/awscliv2.zip -d /tmp/tool-install \
  && /tmp/tool-install/aws/install \
  && curl --fail --silent --show-error --location \
       "https://get.pulumi.com/releases/sdk/pulumi-v${PULUMI_VERSION}-linux-${PULUMI_ARCH}.tar.gz" \
       --output /tmp/tool-install/pulumi.tar.gz \
  && tar -xzf /tmp/tool-install/pulumi.tar.gz -C /tmp/tool-install \
  && find /tmp/tool-install/pulumi -maxdepth 1 -type f -name 'pulumi*' -executable \
       -exec install {} /usr/local/bin/ \; \
  && aws --version \
  && pulumi version \
  && uv --version \
  && make --version \
  && rm -rf /tmp/tool-install \
  && rm -rf /var/lib/apt/lists/* \
  && mkdir -p /paperclip \
  && chown node:node /paperclip

COPY --chown=node:node --from=build /app /app
COPY scripts/docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENV NODE_ENV=production \
  HOME=/paperclip \
  HOST=0.0.0.0 \
  PORT=3100 \
  SERVE_UI=true \
  PAPERCLIP_HOME=/paperclip \
  PAPERCLIP_INSTANCE_ID=default \
  PAPERCLIP_BUILD_VERSION=${PAPERCLIP_BUILD_VERSION} \
  USER_UID=${USER_UID} \
  USER_GID=${USER_GID} \
  PAPERCLIP_CONFIG=/paperclip/instances/default/config.json \
  PAPERCLIP_DEPLOYMENT_MODE=authenticated \
  PAPERCLIP_DEPLOYMENT_EXPOSURE=private \
  OPENCODE_ALLOW_ALL_MODELS=true \
  GEMINI_SANDBOX=false

EXPOSE 3100

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["node", "--import", "./server/node_modules/tsx/dist/loader.mjs", "server/dist/index.js"]

# Cloud image variant (build with `--target cloud`): the production image
# plus built bundled sandbox-provider plugins. Managed instances receive a
# `plugins.autoInstall` key list through PAPERCLIP_MANAGED_CONFIG and
# install those plugins from the bundled catalog at boot
# (server/src/services/bundled-plugins.ts), which requires each plugin's
# dist/ to exist in the image — the default image ships only their source,
# so auto-install logs "bundle not present" and skips. The plugins are
# built in this separate target so the default (self-hosted) image stays
# lean; CI pins the default build to `--target production`, which is
# byte-identical to before this stage existed.
#
# The sandbox providers are intentionally excluded from the pnpm workspace
# (see pnpm-workspace.yaml), so each installs standalone exactly as its
# README prescribes. Installing in a `build`-based stage (not `production`)
# keeps devDependencies available for tsc: `production` sets
# NODE_ENV=production, which would make pnpm skip them.
#
# CLOUD_BUNDLED_PLUGINS is the space-separated list of sandbox-provider
# directory names to build into the variant. Only what managed deployments
# actually auto-install belongs here — every entry adds its node_modules
# to the image. Growing the list is a one-line workflow change.
FROM build AS cloud-plugins
ARG CLOUD_BUNDLED_PLUGINS="daytona"
RUN set -eu; \
  for name in $CLOUD_BUNDLED_PLUGINS; do \
    dir="packages/plugins/sandbox-providers/$name"; \
    test -d "$dir" || { echo "ERROR: unknown sandbox provider '$name'" >&2; exit 1; }; \
    pnpm -C "$dir" install --ignore-workspace --no-lockfile; \
    pnpm -C "$dir" build; \
    test -f "$dir/dist/manifest.js" || { echo "ERROR: $dir is missing dist/manifest.js after build" >&2; exit 1; }; \
  done

FROM production AS cloud
COPY --chown=node:node --from=cloud-plugins /app/packages/plugins/sandbox-providers /app/packages/plugins/sandbox-providers
