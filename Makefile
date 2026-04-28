.PHONY: help up down logs ps build rebuild shell-db shell-backend fresh logs-seed

help:
	@echo ""
	@echo "  Simple App — Commands"
	@echo ""
	@echo "  make up          Build (if needed) and start everything"
	@echo "  make down        Stop containers"
	@echo "  make fresh       Wipe everything (volumes) and restart fresh"
	@echo "  make rebuild     Force rebuild all images and restart"
	@echo "  make logs        Tail all logs"
	@echo "  make logs-be     Tail backend logs only"
	@echo "  make logs-fe     Tail frontend logs only"
	@echo "  make logs-db     Tail database logs"
	@echo "  make logs-seed   Show seed container logs"
	@echo "  make ps          Show status"
	@echo "  make shell-db    Open psql in db container"
	@echo "  make shell-be    Open shell in backend container"
	@echo ""
	@echo "  Access:"
	@echo "    Frontend  →  http://YOUR_VPS_IP:3000"
	@echo "    Backend   →  http://YOUR_VPS_IP:8080/api/health"
	@echo "    Postgres  →  YOUR_VPS_IP:5432 (user: app, pass: secret, db: appdb)"
	@echo ""

up:
	docker compose up -d --build
	@echo ""
	@echo "✅ Running!"
	@echo "   Frontend  → http://localhost:3000"
	@echo "   Backend   → http://localhost:8080/api/health"

down:
	docker compose down

fresh:
	docker compose down -v
	docker compose up -d --build
	@echo "✅ Fresh start complete"

rebuild:
	docker compose down
	docker compose build --no-cache
	docker compose up -d
	@echo "✅ Rebuilt and running"

logs:
	docker compose logs -f

logs-be:
	docker compose logs -f backend

logs-fe:
	docker compose logs -f frontend

logs-db:
	docker compose logs -f db

logs-seed:
	docker compose logs seed

ps:
	docker compose ps

shell-db:
	docker compose exec db psql -U postgres -d skalemon

shell-be:
	docker compose exec backend sh
