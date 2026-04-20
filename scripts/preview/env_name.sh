#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <branch-name>" >&2
  exit 1
fi

ENV_NAME="$1"
MAX_LEN=40

ENV_SLUG="$(echo "$ENV_NAME" \
  | tr '[:upper:]' '[:lower:]' \
  | sed -E 's/[^a-z0-9]+/-/g' \
  | sed -E 's/^-+|-+$//g' \
  | cut -c1-"$MAX_LEN")"

if [[ -z "$ENV_SLUG" ]]; then
  echo "Could not compute env name '$ENV_NAME'" >&2
  exit 1
fi

# if [[ -n "$PR_NUMBER" ]]; then
#   PREFIX="pr-${PR_NUMBER}"
#   REMAINING=$((MAX_LEN - ${#PREFIX} - 1))
#   if (( REMAINING > 0 )); then
#     BRANCH_PART="$(printf '%s' "$ENV_SLUG" | cut -c1-"$REMAINING")"
#     ENV_NAME="${PREFIX}-${BRANCH_PART}"
#   else
#     ENV_NAME="$(printf '%s' "$PREFIX" | cut -c1-"$MAX_LEN")"
#   fi
# else
ENV_NAME="$ENV_SLUG"
# fi

printf '%s\n' "$ENV_NAME"
