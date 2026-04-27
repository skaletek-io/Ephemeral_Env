#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 5 ]]; then
  echo "Usage: $0 <env-name> <preview-base-domain> <cpu-limit> <memory-limit> <github-output-file>" >&2
  exit 1
fi

ENV_NAME="$1"
PREVIEW_BASE_DOMAIN="$2"
CPU_LIMIT="$3"
MEMORY_LIMIT="$4"
GITHUB_OUTPUT_FILE="$5"

DEPLOY_OUT="$(ssh preview-vps "cd ~/simple-app/previews/${ENV_NAME} && ./scripts/preview/deploy.sh '${ENV_NAME}' '${PREVIEW_BASE_DOMAIN}' '${CPU_LIMIT}' '${MEMORY_LIMIT}'")"
echo "$DEPLOY_OUT"

FRONTEND_URL="$(printf '%s\n' "$DEPLOY_OUT" | awk -F= '/^frontend_url=/{print $2}' | tail -n1)"
BACKEND_URL="$(printf '%s\n' "$DEPLOY_OUT" | awk -F= '/^backend_url=/{print $2}' | tail -n1)"
DB_PORT="$(printf '%s\n' "$DEPLOY_OUT" | awk -F= '/^db_port=/{print $2}' | tail -n1)"
DEPLOY_SHA="$(printf '%s\n' "$DEPLOY_OUT" | awk -F= '/^commit_sha=/{print $2}' | tail -n1)"

{
  echo "frontend_url=$FRONTEND_URL"
  echo "backend_url=$BACKEND_URL"
  echo "db_port=$DB_PORT"
  echo "commit_sha=$DEPLOY_SHA"
} >> "$GITHUB_OUTPUT_FILE"
