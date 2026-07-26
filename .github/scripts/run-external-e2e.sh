#!/usr/bin/env bash
# Boot the existing API (no api/ edits) and run assessment/scripts/e2e_business_flow.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
API_DIR="${ROOT}/api"
BASE_URL="${BASE_URL:-http://127.0.0.1:3001}"
E2E_EMAIL="${E2E_EMAIL:-admin@test-corp.example}"
E2E_PASSWORD="${E2E_PASSWORD:-Password1!}"
X_TENANT_SCHEME="${X_TENANT_SCHEME:-test-corp}"

cd "$API_DIR"

export RAILS_ENV="${RAILS_ENV:-development}"
export WEB_CONCURRENCY="${WEB_CONCURRENCY:-0}"
export PORT="${PORT:-3001}"

echo "Preparing DB + seed…"
bundle exec rails db:prepare
bundle exec rails db:seed

echo "Starting API on ${BASE_URL}…"
bundle exec rails server -b 127.0.0.1 -p "${PORT}" -e "${RAILS_ENV}" > /tmp/api-e2e-server.log 2>&1 &
SERVER_PID=$!

cleanup() {
  if kill -0 "$SERVER_PID" 2>/dev/null; then
    kill "$SERVER_PID" 2>/dev/null || true
    wait "$SERVER_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT

echo "Waiting for /health…"
for i in $(seq 1 60); do
  if curl -sf "${BASE_URL}/health" >/dev/null 2>&1; then
    echo "API ready."
    break
  fi
  if ! kill -0 "$SERVER_PID" 2>/dev/null; then
    echo "API process died. Log:" >&2
    cat /tmp/api-e2e-server.log >&2 || true
    exit 1
  fi
  if [[ "$i" -eq 60 ]]; then
    echo "Timed out waiting for API. Log:" >&2
    cat /tmp/api-e2e-server.log >&2 || true
    exit 1
  fi
  sleep 2
done

export BASE_URL E2E_EMAIL E2E_PASSWORD X_TENANT_SCHEME
chmod +x "${ROOT}/assessment/scripts/e2e_business_flow.sh"
"${ROOT}/assessment/scripts/e2e_business_flow.sh"
