# Summary

This repo is intended as a starting point to get a FastAPI server up and running using uv and Docker (modern standards) on a unix box.

Once up and running, the host system will have an endpoint(s) available mirroring your FastAPI setup. When requesting from within the host, it should be reachable at 0.0.0.0:<port> or localhost:<port>.

To hit the endpoint(s) from outside the host, be sure to have appropriate networking and ports open so that traffic can reach the service. The setup assumes that all traffic stays in a private network (otherwise we should consider more about https).

Without further config, the endpoint would then be reachable at, e.g., 172.XXX.XXX.XXX:8000 or 172.XXX.XXX.XXX (port 80 setup). If running on the cloud, be weary that a host stop-start may reassign the internal IP address (AWS EC2 does this). Either a static IP should be set or infrastructure like a load balancer offer a good way to act as an intermediary stable URL target for clients to reference.


# Files at a glance

- `main.py` — FastAPI application entrypoint, defines all endpoints and startup logic
- `pyproject.toml` — project, dependency, and build configuration for [uv](https://docs.astral.sh/uv/) and Python tooling
- `uv.lock` — locked, reproducible list of all dependencies (used by uv and Docker build)
- `Dockerfile` — reproducible build and run instructions for a containerized application
- `.dockerignore` — excludes files (such as `.venv/`, `__pycache__/`) from Docker build context
- `scripts/sanity-check.sh` — small script that pings `/healthz` to verify running server
- `scripts/load-test.sh` — small script that puts some load on the main endpoint.
- `.python-version` — specifies Python version for tools like `pyenv` or uv



# API

- **GET /healthz** — health/readiness check; returns `{"status": "ok"}`
- **GET /sleep** — waits a few seconds (async) then returns `{"status": "ok", "message": "slept 2 seconds"}`
- **GET /v1/myendpoint** — calls `/sleep` via the shared httpx client and returns its response -- this endpoint is what to replace with "real" logic.

Under load, one uvicorn worker is generally enough, but we shard across two workers by default for a small resiliency boost: async I/O yields to the event loop, so many concurrent requests are handled without blocking. A shared `httpx.AsyncClient` is created at startup for outbound calls (e.g. from `/v1/myendpoint`).

---

## Run locally

[uv](https://docs.astral.sh/uv/) is used for dependency and environment management. Install uv (varies by OS slightly), then:

```bash
uv sync
uv run uvicorn main:app --reload
```

Or in one step (uv creates `.venv` and installs deps if needed):

```bash
uv run uvicorn main:app --reload
```

To add a dependency: `uv add <package>` (updates `pyproject.toml` and `uv.lock`).

---

## Run with Docker on server (recommended production usage)

Ensure all files are on your server and that you can run docker commands. Install docker if it's unrecognized.

Build and test on the machine:

```bash
docker build -t api .
docker run -p 8000:8000 api
```

If the above commands worked, you should see your FastAPI booted in a process. Keep this terminal alive, and in a new terminal, try both of the ./scripts/*.sh files to ensure endpoints are working.

Once you are confident that the api is reachable and working, then the below command setup starts as a background process and configure basic logs/restarts. Use `-p 8000:8000` for external access at `http://<host>:8000`; use `-p 80:8000` if you want the app on the host’s port 80 (ensure nothing else is bound to 80). Setting to port 80 might require additional permissions to be set/overwritten.

```bash
docker run -d --restart unless-stopped -p 8000:8000 --log-opt max-size=10m --log-opt max-file=3 api
docker ps
```

You should no longer "see" the active process since it's in the background, but the docker ps will tell you current status of the container.

To tear down the container if needed, use docker ps to find the CONTAINER_ID, then:

```bash
docker kill CONTAINER_ID
```
---

## Scripts

**Sanity check** — one request to the health endpoint (exits 0 on 200):

```bash
./scripts/sanity-check.sh                    # default: http://localhost:8000
./scripts/sanity-check.sh http://localhost:8000
```

**Load test** — many concurrent requests (curl + xargs). Arguments: `[BASE_URL] [COUNT] [CONCURRENCY] [ENDPOINT]`. Defaults: 3000 requests, 1000 concurrent, `GET /v1/myendpoint`.

```bash
./scripts/load-test.sh # Defaults to 3000 total requests with 1000 concurrency (heavy by intention to assess throughput - use with caution against real logic.)
./scripts/load-test.sh http://localhost:8000 1000 100   # 1k requests, 100 concurrent
./scripts/load-test.sh http://localhost:8000 2000 200 /sleep   # hit /sleep
```

Output shows HTTP status code counts and total time / req/s.
