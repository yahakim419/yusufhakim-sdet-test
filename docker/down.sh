#!/usr/bin/env bash
# Mac / Linux — stop the local Docker stack.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DOCKER_DIR="$ROOT/docker"
COMPOSE_FILE="$DOCKER_DIR/docker-compose.yml"
ENV_FILE="$DOCKER_DIR/.env"

if [ ! -f "$ENV_FILE" ]; then
  ENV_FILE="$DOCKER_DIR/.env.example"
fi

cd "$ROOT"
docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" down

echo "Stack stopped."
