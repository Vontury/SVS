# Environment variables

Never commit real values. Copy `.env.example` to `.env` locally; on Cloud Run use
environment variables / Secret Manager.

| Variable | Used by | Phase | Notes |
|---|---|---|---|
| `SERVER_PORT` | backend | 0 | Defaults to `8083` |
| `SPRING_DATASOURCE_URL` | backend | 0 | JDBC URL (local Postgres or Supabase) |
| `SPRING_DATASOURCE_USERNAME` | backend | 0 | |
| `SPRING_DATASOURCE_PASSWORD` | backend | 0 | Secret |
| `CORS_ALLOWED_ORIGINS` | backend | 10 | Comma-separated origins |
| `SUPABASE_URL` | backend | 3 | |
| `SUPABASE_JWT_SECRET` | backend | 3 | Secret. Must match the algorithm Supabase signs with |
| `FASTAPI_BASE_URL` | backend | 7 | Internal URL of processing-service |
| `LLM_API_KEY` | processing-service | 6 | Secret |

Spring Boot does not read `.env` files by itself. Export the variables in your
shell (or configure them in your IDE run configuration) before starting it.
Start the local database with `docker compose --env-file .env -f database/docker-compose.yml up -d` from the repo root.
