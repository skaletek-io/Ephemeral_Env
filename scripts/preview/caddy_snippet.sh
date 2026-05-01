#!/usr/bin/env bash
set -euo pipefail

preview_caddy_home() {
	printf '%s\n' "${SKALETEK_CADDY_HOME:-$HOME/skaletek-caddy}"
}

preview_caddy_snippets_dir() {
	printf '%s\n' "${CADDY_SNIPPETS_DIR:-$(preview_caddy_home)/snippets}"
}

preview_reload_caddy() {
	local ch dir
	ch="$(preview_caddy_home)"
	dir="$(preview_caddy_snippets_dir)"
	if [[ ! -d "$ch" ]] || [[ ! -f "$ch/docker-compose.yml" ]]; then
		echo "[caddy] SKALETEK_CADDY_HOME not bootstrapped at '$ch'; skipping reload." >&2
		return 0
	fi
	mkdir -p "$dir"
	if [[ -n "$(docker compose -f "$ch/docker-compose.yml" ps -q caddy 2>/dev/null || true)" ]]; then
		docker compose -f "$ch/docker-compose.yml" exec -T caddy caddy reload --config /etc/caddy/Caddyfile \
			|| echo "[caddy] reload failed (is the container healthy?)." >&2
	else
		echo "[caddy] Caddy container not running; start it once from '$ch' (see caddy/README.md)." >&2
	fi
	return 0
}

preview_write_snippet() {
	local env_name="$1"
	local fe_port="$2"
	local be_port="$3"
	local domain="$4"
	local dir file host
	dir="$(preview_caddy_snippets_dir)"
	host="${env_name}.${domain}"
	file="${dir}/${env_name}.caddy"
	mkdir -p "$dir"

	cat >"$file" <<EOF
${host} {
	handle /api/* {
		reverse_proxy 127.0.0.1:${be_port}
	}
	handle /docs* {
		reverse_proxy 127.0.0.1:${be_port}
	}
	handle {
		reverse_proxy 127.0.0.1:${fe_port}
	}
}
EOF
	echo "[caddy] wrote ${file}"
}

preview_remove_snippet() {
	local env_name="$1"
	local f
	f="$(preview_caddy_snippets_dir)/${env_name}.caddy"
	if [[ -f "$f" ]]; then
		rm -f "$f"
		echo "[caddy] removed ${f}"
	fi
}

usage() {
	echo "Usage: $0 write <env_name> <frontend_port> <backend_port> <preview_domain>" >&2
	echo "       $0 remove <env_name>" >&2
	echo "       $0 reload" >&2
	exit 1
}

cmd="${1:-}"
case "$cmd" in
write)
	[[ $# -eq 5 ]] || usage
	preview_write_snippet "$2" "$3" "$4" "$5"
	preview_reload_caddy
	;;
remove)
	[[ $# -eq 2 ]] || usage
	preview_remove_snippet "$2"
	preview_reload_caddy
	;;
reload)
	preview_reload_caddy
	;;
*)
	usage
	;;
esac
