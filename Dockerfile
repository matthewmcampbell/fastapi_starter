FROM python:3.12-slim

WORKDIR /app

# Install uv and sync dependencies from lockfile (reproducible, no project source needed)
COPY pyproject.toml uv.lock ./
RUN pip install uv && uv sync --frozen --no-dev --no-install-project

COPY main.py .

EXPOSE 8000

ENTRYPOINT [".venv/bin/uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
CMD ["--workers", "2"]
