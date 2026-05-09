#!/bin/sh
set -e

BASE_VERSION=$(node -p "require('./server/package.json').version" | sed 's/-[0-9a-f]*$//')
GIT_SHA=$(git rev-parse --short HEAD)
VERSION="${BASE_VERSION}-${GIT_SHA}"

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
