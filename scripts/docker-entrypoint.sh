#!/bin/sh
set -e

# Capture runtime UID/GID from environment variables, defaulting to 1000
PUID=${USER_UID:-1000}
PGID=${USER_GID:-1000}

# Adjust the node user's UID/GID if they differ from the runtime request
# and fix volume ownership only when a remap is needed
changed=0

if [ "$(id -u node)" -ne "$PUID" ]; then
    echo "Updating node UID to $PUID"
    usermod -o -u "$PUID" node
    changed=1
fi

if [ "$(id -g node)" -ne "$PGID" ]; then
    echo "Updating node GID to $PGID"
    groupmod -o -g "$PGID" node
    usermod -g "$PGID" node
    changed=1
fi

if [ "$changed" = "1" ]; then
    chown -R node:node /paperclip
fi

# Seed a minimal config so CLI commands work when running against an external DB.
# The server ignores this file and reads env vars directly; the CLI needs it to
# know the deployment mode and auth base URL before it can touch the DB.
CONFIG_PATH=/paperclip/instances/default/config.json
if [ ! -f "$CONFIG_PATH" ]; then
    mkdir -p "$(dirname "$CONFIG_PATH")"
    cat > "$CONFIG_PATH" << EOF
{
  "meta": { "version": 1 },
  "server": {
    "deploymentMode": "${PAPERCLIP_DEPLOYMENT_MODE:-authenticated}",
    "exposure": "${PAPERCLIP_DEPLOYMENT_EXPOSURE:-public}",
    "host": "0.0.0.0",
    "port": ${PORT:-3100}
  },
  "auth": {
    "baseUrlMode": "explicit",
    "publicBaseUrl": "${PAPERCLIP_PUBLIC_URL:-http://localhost:3100}"
  },
  "database": { "mode": "postgres", "connectionString": "${DATABASE_URL}" },
  "storage": { "provider": "local_disk" },
  "secrets": { "provider": "local_encrypted" }
}
EOF
    chown node:node "$CONFIG_PATH"
fi

exec gosu node "$@"
