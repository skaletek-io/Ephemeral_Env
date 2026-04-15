#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <branch-name>" >&2
  exit 1
fi

BRANCH_NAME="$1"

ENV_NAME="$(echo "$BRANCH_NAME" \
  | tr '[:upper:]' '[:lower:]' \
  | sed -E 's/[^a-z0-9]+/-/g' \
  | sed -E 's/^-+|-+$//g' \
  | cut -c1-40)"

if [[ -z "$ENV_NAME" ]]; then
  echo "Could not compute env name from branch '$BRANCH_NAME'" >&2
  exit 1
fi

printf '%s\n' "$ENV_NAME"
