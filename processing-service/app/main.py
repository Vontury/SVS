from fastapi import FastAPI

# Internal processing service: metadata extraction (Phase 5) and AI (Phase 6).
# It must never contain user/ownership authorization logic.
app = FastAPI(title="Hoarding Processing Service")


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "UP"}
