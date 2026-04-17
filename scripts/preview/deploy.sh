#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 <branch-name> [vps-ip] [commit-sha] [pr-number] [mode] [backend-image]"
  echo "  mode: frontend (default) | backend"
}

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

BRANCH_NAME="$1"
VPS_IP="${2:-}"
COMMIT_SHA="${3:-local}"
PR_NUMBER="${4:-}"
MODE="${5:-frontend}"
BACKEND_IMAGE="${6:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

if [[ "$MODE" != "frontend" && "$MODE" != "backend" ]]; then
  echo "Invalid mode '$MODE'. Allowed: frontend, backend" >&2
  usage
  exit 1
fi

hash_port() {
  local input="$1"
  local base="$2"
  local span="$3"
  local hash dec
  hash="$(printf "%s" "$input" | sha256sum | cut -c1-8)"
  dec="$((16#$hash))"
  echo "$((base + (dec % span)))"
}

ENV_NAME="$("$SCRIPT_DIR/env_name.sh" "$BRANCH_NAME" "$PR_NUMBER")"

PROJECT_NAME="simpleapp-${ENV_NAME}"
FRONTEND_PORT="$(hash_port "${ENV_NAME}-fe" 20000 10000)"
BACKEND_PORT="$(hash_port "${ENV_NAME}-be" 30000 10000)"
DB_PORT="$(hash_port "${ENV_NAME}-db" 40000 10000)"

export COMPOSE_PROJECT_NAME="$PROJECT_NAME"
export FRONTEND_PORT
export BACKEND_PORT
export DB_PORT
export ENV_NAME
export PREVIEW_BRANCH_NAME="$BRANCH_NAME"
export PREVIEW_COMMIT_SHA="$COMMIT_SHA"

COMPOSE_ARGS=(-f "$PROJECT_DIR/docker-compose.yml")
OVERRIDE_FILE=""
if [[ "$MODE" == "frontend" && -n "$BACKEND_IMAGE" ]]; then
  export BACKEND_IMAGE
  OVERRIDE_FILE="$(mktemp)"
  cat > "$OVERRIDE_FILE" <<'YAML'
services:
  backend:
    image: ${BACKEND_IMAGE}
    pull_policy: always
YAML
  COMPOSE_ARGS+=(-f "$OVERRIDE_FILE")
fi
cleanup() {
  if [[ -n "$OVERRIDE_FILE" && -f "$OVERRIDE_FILE" ]]; then
    rm -f "$OVERRIDE_FILE"
  fi
}
trap cleanup EXIT

if [[ "$MODE" == "backend" ]]; then
  docker compose "${COMPOSE_ARGS[@]}" up -d --build backend db
else
  if [[ -n "$BACKEND_IMAGE" ]]; then
    docker compose "${COMPOSE_ARGS[@]}" pull backend
    docker compose "${COMPOSE_ARGS[@]}" build frontend
    docker compose "${COMPOSE_ARGS[@]}" up -d --no-build frontend backend db
  else
    docker compose "${COMPOSE_ARGS[@]}" up -d --build frontend backend db
  fi
fi

echo "env_name=$ENV_NAME"
echo "project_name=$PROJECT_NAME"
echo "frontend_port=$FRONTEND_PORT"
echo "backend_port=$BACKEND_PORT"
echo "db_port=$DB_PORT"
echo "commit_sha=$COMMIT_SHA"
echo "deployment_mode=$MODE"
if [[ -n "$BACKEND_IMAGE" ]]; then
  echo "backend_image_source=$BACKEND_IMAGE"
else
  echo "backend_image_source=local-build"
fi
if [[ -n "$VPS_IP" ]]; then
  echo "backend_url=http://${VPS_IP}:${BACKEND_PORT}/api/health"
  if [[ "$MODE" == "frontend" ]]; then
    echo "frontend_url=http://${VPS_IP}:${FRONTEND_PORT}"
  fi
fi
