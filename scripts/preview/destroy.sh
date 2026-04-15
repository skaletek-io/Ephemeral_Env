#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <branch-name>"
  exit 1
fi

BRANCH_NAME="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_NAME="$("$SCRIPT_DIR/env_name.sh" "$BRANCH_NAME")"

PROJECT_NAME="simpleapp-${ENV_NAME}"

export COMPOSE_PROJECT_NAME="$PROJECT_NAME"

docker compose down -v --remove-orphans --rmi local || true

echo "destroyed_env=$ENV_NAME"
echo "project_name=$PROJECT_NAME"
