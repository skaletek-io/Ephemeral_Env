#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 <branch-name> [pr-number]"
}

log() {
  echo "[preview-destroy] $*"
}

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

BRANCH_NAME="$1"
PR_NUMBER="${2:-}"
if [[ -z "$BRANCH_NAME" ]]; then
  echo "branch-name must not be empty" >&2
  usage
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_NAME="$("$SCRIPT_DIR/env_name.sh" "$BRANCH_NAME" "$PR_NUMBER")"
PROJECT_NAME="simpleapp-${ENV_NAME}"

export COMPOSE_PROJECT_NAME="$PROJECT_NAME"

log "Destroying preview resources for project '$PROJECT_NAME'..."
docker compose down -v --remove-orphans --rmi local || true

log "Destroy step completed."
echo "destroyed_env=$ENV_NAME"
echo "project_name=$PROJECT_NAME"
