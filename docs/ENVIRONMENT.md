# Environment variables

| Variable | Used by | Purpose |
|---|---|---|
| SPRING_DATASOURCE_URL | backend | JDBC URL of Supabase/local PostgreSQL |
| SPRING_DATASOURCE_USERNAME | backend | DB user |
| SPRING_DATASOURCE_PASSWORD | backend | DB password |
| SUPABASE_URL | backend, frontend | Supabase project URL (Phase 3) |
| SUPABASE_JWT_SECRET | backend | Validate Supabase JWTs (Phase 3). Backend only, never frontend |
| FASTAPI_BASE_URL | backend | Internal URL of processing service |
| LLM_API_KEY | processing-service | LLM provider key (Phase 6) |
| CORS_ALLOWED_ORIGINS | backend | Comma-separated allowed origins |

Copy `.env.example` to `.env`. `.env` is git-ignored. Never put secrets in frontend JS or the Chrome extension.
