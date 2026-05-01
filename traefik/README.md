# Traefik reverse proxy for previews

Traefik listens on **80/443**, obtains certificates via **Let’s Encrypt DNS-01** (Route 53), and routes `{env-name}.{PREVIEW_DOMAIN}` to preview containers on the host using **`host.docker.internal`**.

## One-time VPS bootstrap

1. **Route 53**: wildcard **A** — `*.preview.example.com` → VPS public IP.

2. **IAM**: allow DNS updates for `_acme-challenge` on that zone (same idea as any LE DNS-01 setup).

3. **Run Traefik** (separate from each preview directory):

   ```bash
   mkdir -p ~/skaletek-traefik/dynamic
   cd ~/skaletek-traefik
   # Copy traefik.yml, docker-compose.yml from this repo's traefik/ folder.
   cp /path/to/simple-app-infra/traefik/env.example .env
   # Edit .env — ACME_EMAIL and AWS_* (or rely on an EC2 instance profile).
   docker compose up -d
   ```

4. **GitHub**: set secret **`PREVIEW_DOMAIN`** to the suffix only (e.g. `preview.example.com`). Hostnames become `{env}.preview.example.com`. Leave unset to keep raw `http://IP:port` URLs.

Deploy writes **`dynamic/preview-{env}.yml`**; with **`watch: true`** Traefik picks up adds/removes without a manual reload.

## Overrides

| Variable | Default |
|----------|---------|
| `SKALETEK_TRAEFIK_HOME` | `~/skaletek-traefik` |
| `TRAEFIK_DYNAMIC_DIR` | `$SKALETEK_TRAEFIK_HOME/dynamic` |

Certificates are stored in the **`traefik_letsencrypt`** Docker volume at `/letsencrypt/acme.json`; Traefik creates it on first issuance.
