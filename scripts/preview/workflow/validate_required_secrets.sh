#!/usr/bin/env bash
set -euo pipefail

test -n "${VPS_HOST:-}"
test -n "${VPS_USER:-}"
test -n "${SSH_PRIVATE_KEY:-}"
