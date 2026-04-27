#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <env-name> [preview-base-domain] [cpu-limit] [memory-limit]"
  exit 1
fi

ENV_NAME="$1"
PREVIEW_BASE_DOMAIN="${2:-${PREVIEW_BASE_DOMAIN:-}}"
CPU_LIMIT="${3:-${CPU_LIMIT:-0.50}}"
MEMORY_LIMIT="${4:-${MEMORY_LIMIT:-512m}}"
TRAEFIK_PUBLIC_NETWORK="${TRAEFIK_PUBLIC_NETWORK:-traefik-public}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

hash_port() {
  local input="$1"
  local base="$2"
  local span="$3"
  local hash dec
  hash="$(printf "%s" "$input" | sha256sum | cut -c1-8)"
  dec="$((16#$hash))"
  echo "$((base + (dec % span)))"
}

ENV_NAME="$("$SCRIPT_DIR/env_name.sh" "$ENV_NAME")"

PROJECT_NAME="simpleapp-${ENV_NAME}"
FRONTEND_PORT="$(hash_port "${ENV_NAME}-fe" 20000 10000)"
BACKEND_PORT="$(hash_port "${ENV_NAME}-be" 30000 10000)"
DB_PORT="$(hash_port "${ENV_NAME}-db" 40000 10000)"

export COMPOSE_PROJECT_NAME="$PROJECT_NAME"
export FRONTEND_PORT
export BACKEND_PORT
export DB_PORT
export ENV_NAME
export PREVIEW_ENV_NAME="$ENV_NAME"
export PREVIEW_BASE_DOMAIN
export CPU_LIMIT
export MEMORY_LIMIT
export TRAEFIK_PUBLIC_NETWORK

if [[ -z "$PREVIEW_BASE_DOMAIN" ]]; then
  echo "PREVIEW_BASE_DOMAIN must be set (example: preview.example.com)" >&2
  exit 1
fi

if ! docker network inspect "$TRAEFIK_PUBLIC_NETWORK" > /dev/null 2>&1; then
  docker network create "$TRAEFIK_PUBLIC_NETWORK" > /dev/null
fi

docker compose up -d --build

echo "env_name=$ENV_NAME"
echo "project_name=$PROJECT_NAME"
echo "frontend_port=$FRONTEND_PORT"
echo "backend_port=$BACKEND_PORT"
echo "db_port=$DB_PORT"
echo "cpu_limit=$CPU_LIMIT"
echo "memory_limit=$MEMORY_LIMIT"
echo "frontend_url=https://${ENV_NAME}-web.${PREVIEW_BASE_DOMAIN}"
echo "backend_url=https://${ENV_NAME}-api.${PREVIEW_BASE_DOMAIN}/api/health"
