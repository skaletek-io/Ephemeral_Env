#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <env-name> <github-output-file>" >&2
  exit 1
fi

ENV_NAME="$1"
GITHUB_OUTPUT_FILE="$2"

DESTROY_OUT="$(ssh preview-vps "
  set -e
  PREVIEW_DIR=\"\$HOME/skaletek-app-v2/${ENV_NAME}\"
  if [ -d \"\$PREVIEW_DIR\" ]; then
    echo \"[preview-destroy] Found preview directory: \$PREVIEW_DIR\"
    cd \"\$PREVIEW_DIR\"
    ./scripts/preview/destroy.sh '${ENV_NAME}'
    cd /
    sudo rm -rf \"\$PREVIEW_DIR\"
    echo 'preview_dir_removed=true'
  else
    echo '[preview-destroy] No preview directory found; nothing to destroy.'
    echo 'preview_dir_removed=false'
  fi
")"
echo "$DESTROY_OUT"

DESTROYED_ENV="$(printf '%s\n' "$DESTROY_OUT" | awk -F= '/^destroyed_env=/{print $2}' | tail -n1)"
PROJECT_NAME="$(printf '%s\n' "$DESTROY_OUT" | awk -F= '/^project_name=/{print $2}' | tail -n1)"
PREVIEW_DIR_REMOVED="$(printf '%s\n' "$DESTROY_OUT" | awk -F= '/^preview_dir_removed=/{print $2}' | tail -n1)"

{
  echo "destroyed_env=$DESTROYED_ENV"
  echo "project_name=$PROJECT_NAME"
  echo "preview_dir_removed=$PREVIEW_DIR_REMOVED"
} >> "$GITHUB_OUTPUT_FILE"

