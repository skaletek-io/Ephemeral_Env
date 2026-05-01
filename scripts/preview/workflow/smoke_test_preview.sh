#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <backend-health-url> [frontend-url]" >&2
  exit 1
fi

BACKEND_URL="$1"
FRONTEND_URL="${2:-}"

sleep 3

for attempt in $(seq 1 12); do
  backend_ok=0
  frontend_ok=0

  health_body="$(curl -fsS "$BACKEND_URL" || true)"
  if printf '%s' "$health_body" | grep -Eq '"status"[[:space:]]*:[[:space:]]*"(ok|healthy)"'; then
    backend_ok=1
  fi

  if [[ -z "$FRONTEND_URL" ]]; then
    frontend_ok=1
  elif curl -fsS -o /dev/null "$FRONTEND_URL"; then
    frontend_ok=1
  fi

  if [[ "$backend_ok" -eq 1 && "$frontend_ok" -eq 1 ]]; then
    echo "Smoke test passed on attempt $attempt."
    exit 0
  fi

  echo "Attempt $attempt failed; retrying in 5s..."
  sleep 5
done

echo "Smoke test failed: preview not healthy."
exit 1
