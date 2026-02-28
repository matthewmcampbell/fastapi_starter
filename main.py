import asyncio
from contextlib import asynccontextmanager

import httpx
from fastapi import FastAPI

# Global client, set during lifespan.
http_client: httpx.AsyncClient | None = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    global http_client
    http_client = httpx.AsyncClient(
        base_url="http://127.0.0.1:8000",  # Replace with your upstream API base URL (e.g. from env)
        limits=httpx.Limits(max_connections=500, max_keepalive_connections=100),
        timeout=httpx.Timeout(connect=5.0, read=10.0, write=10.0, pool=10.0),
    )
    try:
        yield
    finally:
        await http_client.aclose()
        http_client = None


app = FastAPI(lifespan=lifespan)


@app.get("/sleep")
async def sleep():
    """Wait 2 seconds asynchronously, then return. Non-blocking under load."""
    await asyncio.sleep(2)
    return {"status": "ok", "message": "slept 2 seconds"}


@app.get("/healthz")
async def healthz():
    """
    Health/readiness check. Not relevant for the current setup, as container will only restart if process exits.
    But health endpoints are used by load balancers/orchestrators to determine if the service is healthy.
    """
    return {"status": "ok"}


@app.get("/v1/myendpoint")
async def myendpoint():
    """Calls the /sleep endpoint via the shared httpx client."""
    if http_client is None:
        raise RuntimeError("HTTP client not initialized")

    ############################################################################
    # Replace with an actual useful call.
    response = await http_client.get("/sleep")

    ############################################################################

    response.raise_for_status()
    return response.json()
