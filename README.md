# Digital Hoarding System

Personal content saver for digital-hoarding research. See `IMPLEMENTATION_PLAN.md` (authoritative).

```
backend/             Spring Boot 3 / Java 21 (main backend)
processing-service/  FastAPI (metadata + AI only)
frontend/            HTML/CSS/Vanilla JS
chrome-extension/    Manifest V3 (Phase 13)
database/migrations/ SQL migrations (Phase 1)
docs/
```

## Run locally
```bash
# backend (needs env vars from .env.example; default port 8083, override with SERVER_PORT)
cd backend && mvn spring-boot:run   # serves on http://localhost:8083

# processing service
cd processing-service && python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt && uvicorn app.main:app --reload --port 8000
```

## Status
- [x] Phase 0 — project setup
- [x] Phase 1 — database (`database/run_tests.sh` to verify)
- [ ] Phase 2 — Spring Boot CRUD