#!/usr/bin/env bash
# Ensures node_modules exists when a named volume masks the image layer (Mac + Windows).
set -euo pipefail

if [ ! -x node_modules/.bin/vite ]; then
  echo "Installing npm dependencies..."
  npm ci
fi

exec "$@"
