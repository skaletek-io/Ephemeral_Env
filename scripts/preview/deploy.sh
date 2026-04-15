#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <branch-name> [vps-ip] [commit-sha] [pr-number]"
  exit 1
fi

BRANCH_NAME="$1"
VPS_IP="${2:-}"
COMMIT_SHA="${3:-local}"
PR_NUMBER="${4:-}"
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

docker compose up -d --build

echo "env_name=$ENV_NAME"
echo "project_name=$PROJECT_NAME"
echo "frontend_port=$FRONTEND_PORT"
echo "backend_port=$BACKEND_PORT"
echo "db_port=$DB_PORT"
echo "commit_sha=$COMMIT_SHA"
if [[ -n "$VPS_IP" ]]; then
  echo "frontend_url=http://${VPS_IP}:${FRONTEND_PORT}"
  echo "backend_url=http://${VPS_IP}:${BACKEND_PORT}/api/health"
fi
