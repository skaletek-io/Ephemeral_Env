# Simple App

Three-tier app for VPS testing:

- Frontend: Next.js
- Backend: Go
- Database: Postgres
- Orchestration: Docker Compose

No domain or reverse proxy required. Everything is exposed via host ports.

---

## Architecture

- Frontend serves UI on port `3000` (or preview-computed frontend port).
- Frontend proxies `/api/*` to backend.
- Backend serves REST API on port `8080` (or preview-computed backend port).
- Backend connects to Postgres and seeds initial data from `db/seeds/seed.sql`.
- Postgres is exposed on host for direct connections.

---

## Local Quick Start

```bash
make up
```

Default endpoints:

| Service | URL |
|---|---|
| Frontend | `http://localhost:3000` |
| Backend health | `http://localhost:8080/api/health` |
| Postgres | `localhost:5432` |

---

## Make Commands

```bash
make up        # build (if needed) and start all services
make down      # stop all services
make fresh     # stop + remove volumes + restart
make rebuild   # rebuild images without cache, then start
make logs      # tail all logs
make logs-be   # backend logs
make logs-fe   # frontend logs
make logs-db   # database logs
make ps        # docker compose status
make shell-db  # open psql shell
make shell-be  # open backend container shell
```

---

## API

```text
GET    /api/health
GET    /api/users
POST   /api/users        body: { "name": "...", "email": "..." }
DELETE /api/users/:id
```

Health returns:

- `{"status":"healthy"}` when DB connection is good
- `{"status":"db unavailable"}` when DB is unavailable

---

## Data Seeding

Seed SQL is applied at startup from:

- `db/seeds/seed.sql`

Reset and re-seed:

```bash
make fresh
```

---

## Configuration

Main config lives in:

- `docker-compose.yml`

Important variables:

- `FRONTEND_PORT` (default `3000`)
- `BACKEND_PORT` (default `8080`)
- `DB_PORT` (default `5432`)
- `DATABASE_URL` for backend
- `POSTGRES_PASSWORD` for DB

To change DB credentials, update both DB and backend settings in `docker-compose.yml`.

---

## Preview Environments (PR-Based)

Workflow:

- `.github/workflows/preview-env.yml`

Behavior:

- On PR `opened`, `reopened`, and `synchronize`: deploy/update preview.
- On PR `closed`: destroy preview.
- Only runs when PR head repo is the same repository (not forks).

### Isolation Model

Environment names come from branch + PR number using `scripts/preview/env_name.sh`:

- Format: `pr-<PR_NUMBER>-<branch-slug>`
- Max length: `40`
- Example: `pr-42-feature-login-page`

This env name is used for:

- Remote directory: `~/simple-app/previews/<env_name>`
- Compose project: `simpleapp-<env_name>`
- Port derivation seed (deterministic per preview)

### Preview Port Ranges

Deterministic hash-based ranges:

- Frontend: `20000-29999`
- Backend: `30000-39999`
- Postgres: `40000-49999`

### Deploy Flow

1. Checkout repository in GitHub Actions.
2. Compute env name from branch + PR number.
3. Setup SSH from secret key.
4. `rsync` repo to `~/simple-app/previews/<env_name>`.
5. Run `scripts/preview/deploy.sh`.
6. Parse output URLs/ports.
7. Run smoke tests with retries (up to 12 attempts):
`curl` frontend URL and backend `/api/health`.
8. Upsert one PR status comment (no comment spam).

### Destroy Flow

1. Compute same env name.
2. SSH to VPS and enter preview directory.
3. Run `scripts/preview/destroy.sh`.
4. Remove preview directory.
5. Upsert PR status comment with cleanup message.

### PR Status Comment Behavior

The workflow maintains one rolling status comment using marker:

- `<!-- preview-env-status -->`

Includes:

- Run number
- Frontend URL
- Backend health URL
- DB port
- Commit SHA

If deploy/smoke test fails, the same comment is updated with:

- Failure message
- Link to workflow run logs
- Last known URLs (if available)

---

## Required GitHub Secrets

Set in:

- `Settings -> Secrets and variables -> Actions`

Required:

- `VPS_HOST`: VPS IP/hostname
- `VPS_USER`: SSH user on VPS
- `VPS_SSH_KEY`: private key used by GitHub Actions

---

## SSH Setup for GitHub Actions

`VPS_SSH_KEY` secret is not enough by itself. The matching public key must exist in the VPS user’s `authorized_keys`.

Generate key pair:

```bash
ssh-keygen -t ed25519 -C "github-actions-preview" -f ./github_actions_preview_key
```

Put private key in GitHub secret:

```bash
cat ./github_actions_preview_key
```

Put public key on VPS:

```bash
cat ./github_actions_preview_key.pub
```

Install public key for target user:

```bash
sudo -u <VPS_USER> mkdir -p /home/<VPS_USER>/.ssh
sudo -u <VPS_USER> chmod 700 /home/<VPS_USER>/.ssh
sudo -u <VPS_USER> sh -c 'echo "<PASTE_PUBLIC_KEY_HERE>" >> /home/<VPS_USER>/.ssh/authorized_keys'
sudo -u <VPS_USER> chmod 600 /home/<VPS_USER>/.ssh/authorized_keys
```

If using root:

- path is `/root/.ssh/authorized_keys`

---

## VPS Requirements

- Docker + Docker Compose plugin installed
- `rsync` installed
- SSH user allowed to run Docker commands
- writable preview base directory: `~/simple-app/previews`

Optional but recommended:

- dedicated deploy user (not root)
- firewall allowing only required ports

---

## Scheduled Stale Preview Cleanup

Workflow:

- `.github/workflows/preview-cleanup.yml`

Script:

- `scripts/preview/cleanup_stale.sh`

Behavior:

- Runs daily at `02:00 UTC`
- Also supports manual dispatch with `retention_days`
- Default retention: `7` days
- Cleans only directories matching `^pr-[0-9]+-`
- For each stale preview, runs `docker compose down -v --remove-orphans --rmi local`
- Then removes the preview directory

Manual run:

1. Go to Actions -> `Preview Cleanup`
2. Click `Run workflow`
3. Optional: set `retention_days`

---

## Preview Scripts

Located in `scripts/preview/`:

- `env_name.sh`: deterministic env name from branch + PR number
- `setup_ssh.sh`: normalizes SSH key secret, builds SSH config, verifies connection
- `deploy.sh`: computes ports, exports preview env vars, runs `docker compose up -d --build`
- `destroy.sh`: tears down preview stack and local images for that compose project
- `cleanup_stale.sh`: removes old preview stacks/directories
- `upsert_pr_comment.js`: helper for updating one PR status comment

---

## Troubleshooting

`Load key ... error in libcrypto`:

- usually malformed private key secret formatting
- ensure full private key is stored in `VPS_SSH_KEY`

`Permission denied (publickey)`:

- public key not installed for `VPS_USER`
- check `authorized_keys` path and permissions

`Can't open user config file ~/.ssh/config`:

- use absolute path in SSH command (`$HOME/.ssh/config`)

Preview closes but not removed:

- confirm PR was closed in same repository (workflow ignores forked PR heads)

Smoke test failure:

- open run logs from PR comment
- inspect backend `/api/health` and frontend startup logs

---

## Connect to Postgres from Your Machine

```bash
psql -h YOUR_VPS_IP -U app -d appdb
# password: secret (or your configured value)
```
