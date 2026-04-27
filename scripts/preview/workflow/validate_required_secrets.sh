#!/usr/bin/env bash
set -euo pipefail

required_vars=(VPS_HOST VPS_USER SSH_PRIVATE_KEY)

if [[ "${REQUIRE_PREVIEW_DOMAIN:-0}" == "1" ]]; then
  required_vars+=(PREVIEW_BASE_DOMAIN)
fi

for var_name in "${required_vars[@]}"; do
  if [[ -z "${!var_name:-}" ]]; then
    echo "Missing required secret or env var: ${var_name}" >&2
    exit 1
  fi
done
