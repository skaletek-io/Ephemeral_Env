#!/usr/bin/env bash
set -euo pipefail

preview_traefik_home() {
	printf '%s\n' "${SKALETEK_TRAEFIK_HOME:-$HOME/skaletek-traefik}"
}

preview_traefik_dynamic_dir() {
	printf '%s\n' "${TRAEFIK_DYNAMIC_DIR:-$(preview_traefik_home)/dynamic}"
}

preview_write_traefik_dynamic() {
	local env_name="$1"
	local fe_port="$2"
	local be_port="$3"
	local domain="$4"
	local dir file host
	local rule_api rule_docs rule_fe

	dir="$(preview_traefik_dynamic_dir)"
	host="${env_name}.${domain}"
	file="${dir}/preview-${env_name}.yml"

	rule_api="$(printf 'Host(`%s`) && PathPrefix(`/api`)' "$host")"
	rule_docs="$(printf 'Host(`%s`) && PathPrefix(`/docs`)' "$host")"
	rule_fe="$(printf 'Host(`%s`)' "$host")"

	mkdir -p "$dir"

	{
		printf '%s\n' 'http:'
		printf '%s\n' '  routers:'
		printf '%s\n' "    preview-${env_name}-api:"
		printf '%s\n' '      priority: 100'
		printf '%s\n' '      entryPoints:'
		printf '%s\n' '        - websecure'
		printf '%s\n' "      rule: \"${rule_api}\""
		printf '%s\n' "      service: preview-${env_name}-backend"
		printf '%s\n' '      tls:'
		printf '%s\n' '        certResolver: route53'
		printf '%s\n' "    preview-${env_name}-docs:"
		printf '%s\n' '      priority: 90'
		printf '%s\n' '      entryPoints:'
		printf '%s\n' '        - websecure'
		printf '%s\n' "      rule: \"${rule_docs}\""
		printf '%s\n' "      service: preview-${env_name}-backend"
		printf '%s\n' '      tls:'
		printf '%s\n' '        certResolver: route53'
		printf '%s\n' "    preview-${env_name}-fe:"
		printf '%s\n' '      priority: 1'
		printf '%s\n' '      entryPoints:'
		printf '%s\n' '        - websecure'
		printf '%s\n' "      rule: \"${rule_fe}\""
		printf '%s\n' "      service: preview-${env_name}-frontend"
		printf '%s\n' '      tls:'
		printf '%s\n' '        certResolver: route53'
		printf '%s\n' '  services:'
		printf '%s\n' "    preview-${env_name}-backend:"
		printf '%s\n' '      loadBalancer:'
		printf '%s\n' '        servers:'
		printf '%s\n' "          - url: \"http://host.docker.internal:${be_port}\""
		printf '%s\n' "    preview-${env_name}-frontend:"
		printf '%s\n' '      loadBalancer:'
		printf '%s\n' '        servers:'
		printf '%s\n' "          - url: \"http://host.docker.internal:${fe_port}\""
	} >"$file"

	echo "[traefik] wrote ${file}"
}

preview_remove_traefik_dynamic() {
	local env_name="$1"
	local f
	f="$(preview_traefik_dynamic_dir)/preview-${env_name}.yml"
	if [[ -f "$f" ]]; then
		rm -f "$f"
		echo "[traefik] removed ${f}"
	fi
}

usage() {
	echo "Usage: $0 write <env_name> <frontend_port> <backend_port> <preview_domain>" >&2
	echo "       $0 remove <env_name>" >&2
	exit 1
}

cmd="${1:-}"
case "$cmd" in
write)
	[[ $# -eq 5 ]] || usage
	preview_write_traefik_dynamic "$2" "$3" "$4" "$5"
	;;
remove)
	[[ $# -eq 2 ]] || usage
	preview_remove_traefik_dynamic "$2"
	;;
*)
	usage
	;;
esac
