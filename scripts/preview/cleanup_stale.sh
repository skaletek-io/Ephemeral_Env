#!/usr/bin/env bash
set -euo pipefail

RETENTION_DAYS="${1:-7}"
PREVIEW_BASE_DIR="${2:-$HOME/skaletek-app-v2}"

if ! echo "$RETENTION_DAYS" | grep -Eq '^[0-9]+$'; then
  echo "RETENTION_DAYS must be a positive integer, got: '$RETENTION_DAYS'" >&2
  exit 1
fi

if [[ "$RETENTION_DAYS" -lt 1 ]]; then
  echo "RETENTION_DAYS must be >= 1, got: '$RETENTION_DAYS'" >&2
  exit 1
fi

if [[ ! -d "$PREVIEW_BASE_DIR" ]]; then
  echo "No preview base directory found at '$PREVIEW_BASE_DIR'; nothing to clean."
  exit 0
fi

echo "Cleaning previews older than $RETENTION_DAYS days in '$PREVIEW_BASE_DIR'..."

now_epoch="$(date +%s)"
cutoff_seconds="$((RETENTION_DAYS * 86400))"
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

  if [[ -x "$dir/scripts/preview/traefik_dynamic_config.sh" ]]; then
    "$dir/scripts/preview/traefik_dynamic_config.sh" remove "$env_name" || true
  fi

  if [[ -f "$dir/docker-compose.yml" || -f "$dir/docker-compose.yaml" ]]; then
    (
      cd "$dir"
      COMPOSE_PROJECT_NAME="skalemon-${env_name}" docker compose down -v --remove-orphans --rmi local || true
    )
  else
    echo "No docker compose file found in '$dir'; removing directory only."
  fi

  rm -rf "$dir"
  echo "deleted_env=$env_name"
  deleted_count="$((deleted_count + 1))"
done

echo "Cleanup summary: deleted=$deleted_count kept=$kept_count"
