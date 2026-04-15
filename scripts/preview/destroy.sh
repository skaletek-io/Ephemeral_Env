#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <branch-name>"
  exit 1
fi

BRANCH_NAME="$1"

safe_name() {
  echo "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g' \
    | sed -E 's/^-+|-+$//g' \
    | cut -c1-40
}

ENV_NAME="$(safe_name "$BRANCH_NAME")"
if [[ -z "$ENV_NAME" ]]; then
  echo "Could not compute env name from branch '$BRANCH_NAME'"
  exit 1
fi

PROJECT_NAME="simpleapp-${ENV_NAME}"

export COMPOSE_PROJECT_NAME="$PROJECT_NAME"

docker compose down -v --remove-orphans --rmi local|| true

echo "destroyed_env=$ENV_NAME"
echo "project_name=$PROJECT_NAME"
