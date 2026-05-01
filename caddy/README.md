# Caddy reverse proxy for previews

One Caddy instance on the VPS terminates HTTPS and routes `{env-name}.{PREVIEW_DOMAIN}` to the preview frontend port, with `/api/*` and `/docs*` sent to the backend port.

## One-time VPS bootstrap

1. **Route 53**  
   Create a wildcard **A** record: `*.preview.example.com` → your VPS public IP (replace with your real preview zone).

2. **IAM**  
   Grant DNS write for `_acme-challenge` TXT records on that zone (least-privilege policy scoped to the hosted zone ID).

3. **Install Caddy stack** (separate from each preview folder):

   ```bash
   mkdir -p ~/skaletek-caddy/snippets
   # Copy from this repo: Dockerfile, docker-compose.yml, Caddyfile, snippets/
   cd ~/skaletek-caddy
   cp /path/to/simple-app-infra/caddy/env.example .env
   # Edit .env: ACME_EMAIL, AWS_* , AWS_HOSTED_ZONE_ID
   docker compose up -d --build
   ```

   Snippets live under `~/skaletek-caddy/snippets`. Keep `000-status.caddy` from the repo so the main `Caddyfile` `import` always matches at least one file. Preview deploy adds `{env-name}.caddy` here and reloads Caddy.

4. **GitHub Actions**  
   Add repository secret **`PREVIEW_DOMAIN`** with the DNS suffix only (example: `preview.example.com`). Deploy sets `PREVIEW_API_URL` to `https://{env}.{PREVIEW_DOMAIN}/api/v1`. Omit the secret to keep plain `http://IP:port` URLs.

## Environment overrides

| Variable | Meaning |
|----------|---------|
| `SKALETEK_CADDY_HOME` | Directory with `docker-compose.yml` for Caddy (default `~/skaletek-caddy`). |
| `CADDY_SNIPPETS_DIR` | Where per-env `*.caddy` files are written (default `$SKALETEK_CADDY_HOME/snippets`). |

## Notes

- Caddy is built with the **Route 53** DNS provider for ACME DNS-01 (wildcard-friendly).
- Destroy and stale cleanup remove the matching snippet and reload Caddy.
