# Simple App

Three-tier app for manual testing on a VPS.
Go backend · Next.js frontend · Postgres · Docker Compose.

No domain, no Traefik, no certificates — just raw ports.

---

## Start

```bash
# Clone / copy to your VPS, then:
make up
```

That's it.

| Service  | URL                              |
|----------|----------------------------------|
| Frontend | http://YOUR_VPS_IP:3000          |
| Backend  | http://YOUR_VPS_IP:8080/api/health |
| Postgres | YOUR_VPS_IP:5432                 |

---

## Common commands

```bash
make up          # build + start
make down        # stop
make fresh       # wipe DB and restart clean
make rebuild     # force rebuild images
make logs        # tail all logs
make shell-db    # open psql
```

---

## API

```
GET    /api/health       → { status: "ok" }
GET    /api/users        → [ { id, name, email, created_at } ]
POST   /api/users        → body: { name, email }
DELETE /api/users/:id
```

---

## Seed data

5 users and 5 products are loaded automatically on first start (via `db/seeds/seed.sql`).
To reset and re-seed:

```bash
make fresh
```

---

## PR Preview Environments (VPS)

Each pull request can create its own isolated environment on your VPS:

- Environment name is derived from the PR branch name.
- Deploy/update happens on PR `opened`, `reopened`, and `synchronize`.
- Environment is removed when PR is merged.

Workflow file: `.github/workflows/preview-env.yml`

### Required GitHub Secrets

Set these in `Settings -> Secrets and variables -> Actions`:

- `VPS_HOST`: Public IP or hostname of your VPS
- `VPS_USER`: SSH user on VPS
- `VPS_SSH_KEY`: Private key for that user

Important: `VPS_SSH_KEY` alone is not enough. You must also add the matching public key to the VPS user's `authorized_keys`.

### Required SSH Authorization on VPS

GitHub Actions can SSH into your VPS only if the public key matching `VPS_SSH_KEY` is present in:

- `/home/<VPS_USER>/.ssh/authorized_keys` (or `/root/.ssh/authorized_keys` if using `root`)

Example setup:

```bash
# On your local machine (or wherever you generate deploy keys)
ssh-keygen -t ed25519 -C "github-actions-preview" -f ./github_actions_preview_key

# Add private key content to GitHub secret VPS_SSH_KEY
cat ./github_actions_preview_key

# Add public key content to the VPS user authorized_keys
cat ./github_actions_preview_key.pub
```

On the VPS (as root or with sudo), ensure permissions are correct:

```bash
sudo -u <VPS_USER> mkdir -p /home/<VPS_USER>/.ssh
sudo -u <VPS_USER> chmod 700 /home/<VPS_USER>/.ssh
sudo -u <VPS_USER> sh -c 'echo "<PASTE_PUBLIC_KEY_HERE>" >> /home/<VPS_USER>/.ssh/authorized_keys'
sudo -u <VPS_USER> chmod 600 /home/<VPS_USER>/.ssh/authorized_keys
```

### VPS Requirements

- Docker and Docker Compose plugin installed.
- `rsync` installed.
- SSH user can run Docker commands.
- Writable path: `~/simple-app/previews`.

### How preview ports work

Ports are computed deterministically from the branch name to allow multiple previews at once:

- Frontend host port: `20000-29999`
- Backend host port: `30000-39999`
- Postgres host port: `40000-49999`

The workflow posts URLs directly in the PR comments after each deploy.

---

## Customise DB credentials

Edit `docker-compose.yml`:

```yaml
db:
  environment:
    POSTGRES_PASSWORD: your_password

backend:
  environment:
    DATABASE_URL: postgres://app:your_password@db:5432/appdb?sslmode=disable
```

---

## Connect from your machine (optional)

Postgres is exposed on port 5432:

```bash
psql -h YOUR_VPS_IP -U app -d appdb
# password: secret
```

Or use TablePlus / DBeaver with the same credentials.
