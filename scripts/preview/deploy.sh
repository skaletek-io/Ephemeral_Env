#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <env-name> [vps-ip]"
  exit 1
fi

ENV_NAME="$1"
VPS_IP="${2:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

hash_port() {
  local input="$1"
  local base="$2"
  local span="$3"
  local hash dec
  hash="$(printf "%s" "$input" | sha256sum | cut -c1-8)"
  dec="$((16#$hash))"
  echo "$((base + (dec % span)))"
}

ENV_NAME="$("$SCRIPT_DIR/env_name.sh" "$ENV_NAME")"

PROJECT_NAME="skalemon-${ENV_NAME}"
FRONTEND_PORT="$(hash_port "${ENV_NAME}-fe" 20000 10000)"
BACKEND_PORT="$(hash_port "${ENV_NAME}-be" 30000 10000)"
DB_PORT="$(hash_port "${ENV_NAME}-db" 40000 10000)"

export COMPOSE_PROJECT_NAME="$PROJECT_NAME"
export FRONTEND_PORT
export BACKEND_PORT
export DB_PORT
export ENV_NAME
export PREVIEW_ENV_NAME="$ENV_NAME"
export PATH=$PATH:/usr/local/go/bin # Go is installed in vps but not in the PATH when running via SSH — SSH non-interactive sessions don't source ~/.bashrc
export PATH=$PATH:/usr/local/go/bin:~/go/bin # Also add ~/go/bin to PATH for any Go tools installed via 'go install'

if [[ -n "${VPS_IP:-}" ]]; then
  export PREVIEW_API_URL="http://${VPS_IP}:${BACKEND_PORT}/api/v1"
else
  export PREVIEW_API_URL="http://127.0.0.1:${BACKEND_PORT}/api/v1"
fi

echo "step: make deps"
(cd backend/skalemon-api && make deps)

if ! command -v oapi-codegen &> /dev/null; then
    echo "Installing oapi-codegen..."
    go install github.com/oapi-codegen/oapi-codegen/v2/cmd/oapi-codegen@latest
fi

echo "step: make gen"
(cd backend/skalemon-api && make gen)

echo "step: docker compose up"
docker compose -f docker-compose.yml up -d --build

echo "env_name=$ENV_NAME"
echo "project_name=$PROJECT_NAME"
echo "frontend_port=$FRONTEND_PORT"
echo "backend_port=$BACKEND_PORT"
echo "db_port=$DB_PORT"
if [[ -n "$VPS_IP" ]]; then
  echo "frontend_url=http://${VPS_IP}:${FRONTEND_PORT}"
  echo "backend_url=http://${VPS_IP}:${BACKEND_PORT}/docs"
  echo "backend_health_url=http://${VPS_IP}:${BACKEND_PORT}/api/v1/health"
fi
