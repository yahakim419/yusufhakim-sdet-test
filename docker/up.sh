#!/usr/bin/env bash
# Mac / Linux — start the local Docker stack from the repo root.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DOCKER_DIR="$ROOT/docker"
COMPOSE_FILE="$DOCKER_DIR/docker-compose.yml"
ENV_FILE="$DOCKER_DIR/.env"

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is not installed or not on PATH. Install Docker Desktop, then retry."
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  echo "Docker daemon is not running. Start Docker Desktop, then retry."
  exit 1
fi

if [ ! -f "$ENV_FILE" ]; then
  cp "$DOCKER_DIR/.env.example" "$ENV_FILE"
  echo "Created docker/.env from .env.example — edit secrets if needed."
fi

cd "$ROOT"
docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" up --build -d

echo "Waiting for API to accept connections..."
for i in $(seq 1 60); do
  # Any HTTP response means Puma is up (may be 500 until migrations run).
  code="$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:3001/health" || true)"
  if [ "$code" != "000" ] && [ -n "$code" ]; then
    echo "API is listening (HTTP $code)."
    break
  fi
  if [ "$i" -eq 60 ]; then
    echo "API did not start in time. Check: docker compose -f docker/docker-compose.yml logs api"
    exit 1
  fi
  sleep 2
done

echo "Running db:prepare (create/migrate) and db:seed..."
docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" exec -T api \
  bundle exec rails db:prepare db:seed

echo "Verifying API health..."
if ! curl -sf "http://127.0.0.1:3001/health" >/dev/null; then
  echo "Health check failed after migrate. Check: docker compose -f docker/docker-compose.yml logs api"
  exit 1
fi

echo ""
echo "Stack is ready:"
echo "  API  http://localhost:3001/health"
echo "  Web  http://localhost:5173"
echo "Stop with: docker/down.sh"
