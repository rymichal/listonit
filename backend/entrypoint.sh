#!/bin/sh
set -e

echo "Running database migrations..."
/opt/venv/bin/alembic upgrade head

echo "Starting FastAPI server..."
# Cloud Run sets $PORT environment variable (default 8080)
# Use --proxy-headers for correct client IP behind Cloud Run load balancer
exec /opt/venv/bin/uvicorn main:app --host 0.0.0.0 --port ${PORT:-8000} --proxy-headers
