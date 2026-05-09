#!/bin/sh
set -e

# Capture runtime UID/GID from environment variables, defaulting to 1000
PUID=${USER_UID:-1000}
PGID=${USER_GID:-1000}

# Without root we can neither remap the node user (usermod/groupmod/chown)
# nor switch users (gosu needs CAP_SETUID/CAP_SETGID), so exec directly.
# This covers Kubernetes restricted PodSecurity (runAsNonRoot + runAsUser)
# as well as platforms that assign arbitrary UIDs (e.g. OpenShift); for the
# latter a UID/GID mismatch is unfixable here, so warn instead of letting
# usermod fail cryptically and keep volume-permission issues diagnosable.
if [ "$(id -u)" -ne 0 ]; then
    if [ "$(id -u)" -ne "$PUID" ] || [ "$(id -g)" -ne "$PGID" ]; then
        echo "docker-entrypoint.sh: running unprivileged as $(id -u):$(id -g); cannot remap to requested ${PUID}:${PGID}" >&2
    fi
    exec "$@"
fi

# Adjust the node user's UID/GID if they differ from the runtime request
if [ "$(id -u node)" -ne "$PUID" ]; then
    echo "Updating node UID to $PUID"
    usermod -o -u "$PUID" node
fi

if [ "$(id -g node)" -ne "$PGID" ]; then
    echo "Updating node GID to $PGID"
    groupmod -o -g "$PGID" node
    usermod -g "$PGID" node
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

# Ensure the app home is owned by the runtime user after all root writes are
# done. A freshly mounted volume can shadow the image's build-time ownership;
# checking for the first mismatch avoids an unnecessary recursive chown.
home_dir="${PAPERCLIP_HOME:-/paperclip}"
if [ -d "$home_dir" ] && [ -n "$(find "$home_dir" \( ! -user node -o ! -group node \) -print -quit 2>/dev/null)" ]; then
    chown -R node:node "$home_dir"
fi

exec gosu node "$@"
