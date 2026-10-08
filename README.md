# Digital Hoarding System

Personal system for saving short-video URLs (YouTube/TikTok), summarising and
classifying them, and tracking how users revisit or forget them — a measurement
tool for digital-hoarding research.

The authoritative design is [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md).

## Layout

| Folder               | Purpose                                              |
|----------------------|------------------------------------------------------|
| `backend/`           | Spring Boot (Java 21) — main API, auth, business logic |
| `processing-service/`| FastAPI — metadata extraction + AI (internal only)   |
| `frontend/`          | HTML/CSS/Vanilla JS dashboard                        |
| `chrome-extension/`  | Manifest V3 extension (Phase 13)                     |
| `database/`          | SQL migrations, local Postgres compose file          |
| `docs/`              | Documentation (env vars, etc.)                       |

## Quick start (Phase 0)

```bash
cp .env.example .env            # fill in values, never commit
docker compose --env-file .env -f database/docker-compose.yml up -d   # local Postgres

# Backend  → http://localhost:8083/api/health
cd backend && ./mvnw spring-boot:run

# Processing service → http://localhost:8000/health
cd processing-service
python -m venv .venv && source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -r requirements-dev.txt
uvicorn app.main:app --reload --port 8000
```

Environment variables are documented in [docs/ENVIRONMENT.md](docs/ENVIRONMENT.md).

## Status

- [x] Phase 0 — Project setup
- [ ] Phase 1 — Database
