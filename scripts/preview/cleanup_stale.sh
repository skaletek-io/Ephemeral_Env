#!/usr/bin/env bash
set -euo pipefail

RETENTION_MINUTES="${1:-10}"
PREVIEW_BASE_DIR="${2:-$HOME/simple-app/previews}"

if ! echo "$RETENTION_MINUTES" | grep -Eq '^[0-9]+$'; then
  echo "RETENTION_MINUTES must be a positive integer, got: '$RETENTION_MINUTES'" >&2
  exit 1
fi

if [[ "$RETENTION_MINUTES" -lt 1 ]]; then
  echo "RETENTION_MINUTES must be >= 1, got: '$RETENTION_MINUTES'" >&2
  exit 1
fi

if [[ ! -d "$PREVIEW_BASE_DIR" ]]; then
  echo "No preview base directory found at '$PREVIEW_BASE_DIR'; nothing to clean."
  exit 0
fi

echo "Cleaning previews older than $RETENTION_MINUTES minutes in '$PREVIEW_BASE_DIR'..."

now_epoch="$(date +%s)"
cutoff_seconds="$((RETENTION_MINUTES * 60))"
deleted_count=0
kept_count=0

shopt -s nullglob
for dir in "$PREVIEW_BASE_DIR"/*; do
  [[ -d "$dir" ]] || continue

  env_name="$(basename "$dir")"

  mtime_epoch="$(stat -c %Y "$dir")"
  age_seconds="$((now_epoch - mtime_epoch))"

  if [[ "$age_seconds" -lt "$cutoff_seconds" ]]; then
    kept_count="$((kept_count + 1))"
    continue
  fi

  echo "Removing stale preview: $env_name"

  if [[ -f "$dir/docker-compose.yml" || -f "$dir/docker-compose.yaml" ]]; then
    (
      cd "$dir"
      COMPOSE_PROJECT_NAME="simpleapp-${env_name}" docker compose down -v --remove-orphans --rmi local || true
    )
  else
    echo "No docker compose file found in '$dir'; removing directory only."
  fi

  rm -rf "$dir"
  echo "deleted_env=$env_name"
  deleted_count="$((deleted_count + 1))"
done

echo "Cleanup summary: deleted=$deleted_count kept=$kept_count"
