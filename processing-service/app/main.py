from fastapi import FastAPI

# Internal processing service only (plan §5 Rule 2).
# POST /process is implemented in Phase 5.
app = FastAPI(title="Digital Hoarding Processing Service")


@app.get("/health")
def health() -> dict:
    return {"status": "ok"}
