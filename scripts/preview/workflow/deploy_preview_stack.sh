#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 3 ]]; then
  echo "Usage: $0 <env-name> <vps-host> <github-output-file>" >&2
  exit 1
fi

ENV_NAME="$1"
VPS_HOST="$2"
GITHUB_OUTPUT_FILE="$3"

REMOTE_STORE="$(printf 'export STORE_ENCRYPTION_KEY=%q' "${STORE_ENCRYPTION_KEY:-}")"
REMOTE_DOMAIN="$(printf 'export PREVIEW_DOMAIN=%q' "${PREVIEW_DOMAIN:-}")"
DEPLOY_OUT="$(ssh preview-vps "cd ~/skaletek-app-v2/${ENV_NAME} && ${REMOTE_STORE} && ${REMOTE_DOMAIN} && ./scripts/preview/deploy.sh '${ENV_NAME}' '${VPS_HOST}'")"
echo "$DEPLOY_OUT"

FRONTEND_URL="$(printf '%s\n' "$DEPLOY_OUT" | awk -F= '/^frontend_url=/{print $2}' | tail -n1)"
BACKEND_URL="$(printf '%s\n' "$DEPLOY_OUT" | awk -F= '/^backend_url=/{print $2}' | tail -n1)"
BACKEND_HEALTH_URL="$(printf '%s\n' "$DEPLOY_OUT" | awk -F= '/^backend_health_url=/{print $2}' | tail -n1)"
DB_PORT="$(printf '%s\n' "$DEPLOY_OUT" | awk -F= '/^db_port=/{print $2}' | tail -n1)"
DEPLOY_SHA="$(printf '%s\n' "$DEPLOY_OUT" | awk -F= '/^commit_sha=/{print $2}' | tail -n1)"

{
  echo "frontend_url=$FRONTEND_URL"
  echo "backend_url=$BACKEND_URL"
  echo "backend_health_url=$BACKEND_HEALTH_URL"
  echo "db_port=$DB_PORT"
  echo "commit_sha=$DEPLOY_SHA"
} >> "$GITHUB_OUTPUT_FILE"
