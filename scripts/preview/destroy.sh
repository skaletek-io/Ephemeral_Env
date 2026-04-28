#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 <env-name>"
}

log() {
  echo "[preview-destroy] $*"
}

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

ENV_NAME="$1"
if [[ -z "$ENV_NAME" ]]; then
  echo "env-name must not be empty" >&2
  usage
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_NAME="$("$SCRIPT_DIR/env_name.sh" "$ENV_NAME")"
PROJECT_NAME="skalemon-${ENV_NAME}"

export COMPOSE_PROJECT_NAME="$PROJECT_NAME"

log "Destroying preview resources for project '$PROJECT_NAME'..."
docker compose down -v --remove-orphans --rmi local || true

log "Destroy step completed."
echo "destroyed_env=$ENV_NAME"
echo "project_name=$PROJECT_NAME"
