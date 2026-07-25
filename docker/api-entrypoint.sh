#!/usr/bin/env bash
# Generates config/application.yml for Figaro from container ENV (Mac + Windows friendly).
# Does not modify host-tracked files; writes only inside the container filesystem
# unless the path is bind-mounted.
set -euo pipefail

APP_YML="${APP_YML_PATH:-/app/config/application.yml}"

# Bind-mount of ../api hides image-created dirs; recreate before Puma/Sidekiq start.
mkdir -p "$(dirname "$APP_YML")" tmp/pids tmp/cache tmp/sockets log

cat > "$APP_YML" <<EOF
SECRET_KEY_BASE: "${SECRET_KEY_BASE}"
DB_HOST: "${DB_HOST}"
DB_PORT: "${DB_PORT:-5432}"
DB_NAME: "${DB_NAME:-rakamin_development}"
DB_USERNAME: "${DB_USERNAME:-postgres}"
DB_PASSWORD: "${DB_PASSWORD}"
GEMINI_API_KEY: "${GEMINI_API_KEY:-your_gemini_api_key}"
GEMINI_LIVE_MODEL: "${GEMINI_LIVE_MODEL:-gemini-2.0-flash-live-001}"
GEMINI_FLASH_MODEL: "${GEMINI_FLASH_MODEL:-gemini-2.0-flash-001}"
GEMINI_PRO_MODEL: "${GEMINI_PRO_MODEL:-gemini-2.0-pro-001}"
APP_BASE_URL: "${APP_BASE_URL:-http://localhost:3001}"
TOKEN_EXPIRATION_TIME: "${TOKEN_EXPIRATION_TIME:-259200}"
ALLOWED_ORIGINS: "${ALLOWED_ORIGINS:-http://localhost:5173}"
REDIS_URL: "${REDIS_URL:-redis://redis:6379/1}"
EOF

exec "$@"
