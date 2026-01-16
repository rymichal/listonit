# Multi-stage build for optimal image size

FROM python:3.11-slim AS builder

RUN pip install --no-cache-dir uv

WORKDIR /build

COPY pyproject.toml ./

# Create venv and install dependencies using uv
RUN uv venv /opt/venv && \
    uv pip install --python /opt/venv/bin/python -e .

FROM python:3.11-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends libpq5 && \
    rm -rf /var/lib/apt/lists/*

RUN useradd -m -u 1000 appuser && \
    mkdir -p /app && \
    chown -R appuser:appuser /app

WORKDIR /app

# Copy the virtual environment
COPY --from=builder --chown=appuser:appuser /opt/venv /opt/venv

COPY --chown=appuser:appuser . .

USER appuser

ENV PATH="/opt/venv/bin:$PATH" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD ["/opt/venv/bin/python", "-c", "import urllib.request; urllib.request.urlopen('http://localhost:8000/').read()"]

CMD ["/app/entrypoint.sh"]
