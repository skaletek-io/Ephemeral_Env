#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <branch-name> [pr-number]"
  exit 1
fi

BRANCH_NAME="$1"
PR_NUMBER="${2:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_NAME="$("$SCRIPT_DIR/env_name.sh" "$BRANCH_NAME" "$PR_NUMBER")"

PROJECT_NAME="simpleapp-${ENV_NAME}"

export COMPOSE_PROJECT_NAME="$PROJECT_NAME"

docker compose down -v --remove-orphans --rmi local || true

echo "destroyed_env=$ENV_NAME"
echo "project_name=$PROJECT_NAME"
