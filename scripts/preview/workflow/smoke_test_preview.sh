#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <frontend-url> <backend-health-url>" >&2
  exit 1
fi

FRONTEND_URL="$1"
BACKEND_URL="$2"

sleep 3

for attempt in $(seq 1 12); do
  frontend_ok=0
  backend_ok=0

  if curl -fsS "$FRONTEND_URL" > /dev/null; then
    frontend_ok=1
  fi

  health_body="$(curl -fsS "$BACKEND_URL" || true)"
  if printf '%s' "$health_body" | grep -Eq '"status"[[:space:]]*:[[:space:]]*"(ok|healthy)"'; then
    backend_ok=1
  fi

  if [[ "$frontend_ok" -eq 1 && "$backend_ok" -eq 1 ]]; then
    echo "Smoke test passed on attempt $attempt."
    exit 0
  fi

  echo "Attempt $attempt failed; retrying in 5s..."
  sleep 5
done

echo "Smoke test failed: preview not healthy."
exit 1

