#!/bin/sh
set -e

BASE_VERSION=$(node -p "require('./server/package.json').version" | sed 's/-[0-9a-fA-F]*$//')
PAPERCLIP_BUILD_SHA=${PAPERCLIP_BUILD_SHA:-$(git rev-parse --short=9 HEAD)}

case "$PAPERCLIP_BUILD_SHA" in
  *[!0-9a-fA-F]* | "")
    echo "Error: PAPERCLIP_BUILD_SHA must be a hexadecimal git commit." >&2
    exit 1
    ;;
esac

SHA_LENGTH=${#PAPERCLIP_BUILD_SHA}
if [ "$SHA_LENGTH" -lt 7 ] || [ "$SHA_LENGTH" -gt 40 ]; then
  echo "Error: PAPERCLIP_BUILD_SHA must contain 7 to 40 characters." >&2
  exit 1
fi

VERSION="${BASE_VERSION}-${PAPERCLIP_BUILD_SHA}"

echo "Stamping version: ${VERSION}"

for pkg in server/package.json cli/package.json ui/package.json; do
  node -e "
    const fs = require('fs');
    const p = JSON.parse(fs.readFileSync('${pkg}', 'utf8'));
    p.version = '${VERSION}';
    fs.writeFileSync('${pkg}', JSON.stringify(p, null, 2) + '\n');
  "
  echo "  updated ${pkg}"
done
