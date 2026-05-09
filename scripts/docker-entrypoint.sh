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

# Seed a minimal config so CLI commands work when running against an external DB.
# The server ignores this file and reads env vars directly; the CLI needs it to
# know the deployment mode and auth base URL before it can touch the DB.
CONFIG_PATH=/paperclip/instances/default/config.json
if [ ! -f "$CONFIG_PATH" ]; then
    mkdir -p "$(dirname "$CONFIG_PATH")"
    python3 -c "
import json, os, sys
cfg = {
    'meta': {'version': 1},
    'server': {
        'deploymentMode': os.environ.get('PAPERCLIP_DEPLOYMENT_MODE', 'authenticated'),
        'exposure': os.environ.get('PAPERCLIP_DEPLOYMENT_EXPOSURE', 'public'),
        'host': '0.0.0.0',
        'port': int(os.environ.get('PORT', 3100)),
    },
    'auth': {
        'baseUrlMode': 'explicit',
        'publicBaseUrl': os.environ.get('PAPERCLIP_PUBLIC_URL', 'http://localhost:3100'),
    },
    'database': {'mode': 'postgres', 'connectionString': os.environ.get('DATABASE_URL', '')},
    'storage': {'provider': 'local_disk'},
    'secrets': {'provider': 'local_encrypted'},
}
with open(sys.argv[1], 'w') as f:
    json.dump(cfg, f, indent=2)
" "$CONFIG_PATH"
fi

# Fix ownership after all root writes are done.
chown -R node:node /paperclip

exec gosu node "$@"
