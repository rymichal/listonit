# Listonit Backend

FastAPI backend for the Listonit collaborative shopping list application.

## Tech Stack

- **Framework**: FastAPI (Python 3.11+)
- **Database**: PostgreSQL 15
- **ORM**: SQLAlchemy 2.0
- **Migrations**: Alembic
- **Cache/Pub-Sub**: Redis
- **Authentication**: JWT with refresh tokens
- **Dependency Management**: uv (or pip)

## Quick Start

### Option 1: Docker Compose (Recommended for Local Development)

This is the easiest way to get everything running locally. It starts PostgreSQL, Redis, and the FastAPI backend all together.

```bash
# From the project root
cd /path/to/listonit
docker-compose up --build
```

**What this does:**
- Starts PostgreSQL on port 5433
- Starts Redis on port 6379
- Builds and starts the FastAPI backend on port 8000
- Automatically runs database migrations
- Sets up networking between services

**Access the API:**
- Health check: http://localhost:8000/
- API documentation: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

**Useful commands:**
```bash
# Start in background (detached mode)
docker-compose up -d

# View logs
docker-compose logs -f backend

# Stop all services
docker-compose down

# Stop and remove all data (CAUTION!)
docker-compose down -v

# Rebuild after code changes
docker-compose up --build backend

# Access the backend container
docker-compose exec backend sh
```

### Option 2: Dockerfile Only (Backend Container with External Database)

If you want to run just the backend in Docker but manage the database separately:

**Step 1: Start dependencies (PostgreSQL & Redis)**

You have two choices:

a) Use docker-compose for dependencies only:
```bash
cd /path/to/listonit
docker-compose up -d postgres redis
```

b) Or run them manually:
```bash
# PostgreSQL
docker run -d \
  --name listonit-postgres \
  -e POSTGRES_USER=listonit \
  -e POSTGRES_PASSWORD=listonit_dev \
  -e POSTGRES_DB=listonit \
  -p 5433:5432 \
  postgres:15-alpine

# Redis
docker run -d \
  --name listonit-redis \
  -p 6379:6379 \
  redis:7-alpine
```

**Step 2: Build the backend Docker image**

```bash
cd /path/to/listonit/backend
docker build -t listonit-backend .
```

**Step 3: Run the backend container**

```bash
docker run -p 8000:8000 \
  -e DATABASE_URL="postgresql://listonit:listonit_dev@host.docker.internal:5433/listonit" \
  -e DEBUG=true \
  -e CORS_ORIGINS='["http://localhost:3000","http://localhost:8080","http://localhost:8000"]' \
  listonit-backend
```

**Note**: `host.docker.internal` allows the container to access services running on your host machine (like PostgreSQL started with docker-compose).

### Option 3: Local Development (No Docker)

Run the backend directly on your machine for development with hot-reload.

**Step 1: Start dependencies**

```bash
cd /path/to/listonit
docker-compose up -d postgres redis
```

**Step 2: Set up Python environment**

```bash
cd backend
python -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate
```

**Step 3: Install dependencies**

Using `uv` (recommended - faster):
```bash
uv pip install -e .
```

Or using `pip`:
```bash
pip install -e .
```

**Step 4: Configure environment**

Create a `.env` file in the `backend/` directory:
```env
DATABASE_URL=postgresql://listonit:listonit_dev@localhost:5433/listonit
DEBUG=true
CORS_ORIGINS=["http://localhost:3000","http://localhost:8080","http://localhost:8000"]
```

**Step 5: Run migrations**

```bash
alembic upgrade head
```

**Step 6: Start the server**

```bash
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

The `--reload` flag enables auto-restart when code changes.

## Database Migrations

Migrations are managed with Alembic.

### Running Migrations

**With Docker Compose:**
```bash
docker-compose exec backend alembic upgrade head
```

**With Dockerfile only:**
```bash
docker exec listonit-backend alembic upgrade head
```

**Local development:**
```bash
source .venv/bin/activate
alembic upgrade head
```

### Creating New Migrations

**With Docker Compose:**
```bash
docker-compose exec backend alembic revision --autogenerate -m "Add new column"
```

**Local development:**
```bash
source .venv/bin/activate
alembic revision --autogenerate -m "Add new column"
```

### Migration Commands Reference

```bash
# Create a new migration
alembic revision --autogenerate -m "description"

# Apply all pending migrations
alembic upgrade head

# Rollback one migration
alembic downgrade -1

# Show current migration version
alembic current

# Show migration history
alembic history

# Rollback to a specific version
alembic downgrade <revision>
```

### Important Notes on Migrations

- **Docker Compose**: Migrations run automatically on startup via [entrypoint.sh](entrypoint.sh)
- Migration files are stored in `alembic/versions/`
- Always commit migration files to git
- The `alembic/versions` directory is mounted as a volume in docker-compose to persist migrations

## Seeding the Database

To populate the database with test data:

**With Docker Compose:**
```bash
docker-compose exec backend python scripts/seed.py
```

**With Dockerfile only:**
```bash
docker exec listonit-backend python scripts/seed.py
```

**Local development:**
```bash
source .venv/bin/activate
python scripts/seed.py
```

This creates test users:
- Username: `ryan`, Password: `asdfasdf` (admin)
- Username: `hanna`, Password: `asdfasdf` (regular user)

## Environment Variables

Key environment variables (see [.env.example](.env.example) for full list):

| Variable | Description | Docker Compose Default | Local Default |
|----------|-------------|----------------------|---------------|
| `DATABASE_URL` | PostgreSQL connection string | `postgres:5432` | `localhost:5433` |
| `DEBUG` | Enable debug mode | `false` | `true` |
| `SQL_ECHO` | Log SQL queries | `false` | `false` |
| `CORS_ORIGINS` | Allowed CORS origins | `["http://localhost:3000","http://localhost:8080"]` | Same |
| `JWT_SECRET_KEY` | JWT signing key | `your-secret-key-change-in-production` | Same |

### Cloud SQL Support (for GCP Cloud Run)

The backend supports Cloud SQL Unix socket connections:

```env
# Instead of DATABASE_URL, use these:
DB_USER=listonit
DB_PASSWORD=<from Secret Manager>
DB_NAME=listonit
CLOUD_SQL_CONNECTION_NAME=project-id:region:instance-name
```

See [DEPLOYMENT.md](DEPLOYMENT.md) for Cloud Run deployment instructions.

## Project Structure

```
backend/
├── alembic/              # Database migrations
│   ├── versions/         # Migration files
│   └── env.py           # Alembic configuration
├── api/                 # API routes
│   └── v1/
│       ├── endpoints/   # Endpoint handlers
│       └── router.py    # API router
├── auth/                # Authentication logic
├── models/              # SQLAlchemy models
├── schemas/             # Pydantic schemas
├── services/            # Business logic
├── repositories/        # Data access layer
├── scripts/             # Utility scripts
│   └── seed.py         # Database seeding
├── config.py            # Configuration management
├── database.py          # Database connection
├── main.py              # FastAPI application entry point
├── entrypoint.sh        # Docker container startup script
├── Dockerfile           # Docker image definition
└── pyproject.toml       # Python dependencies
```

## API Documentation

When the server is running, visit:

- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc
- **OpenAPI JSON**: http://localhost:8000/openapi.json

See [API.md](API.md) for detailed API documentation.

## Development Workflow

1. **Make code changes**
2. **If models changed**: Create migration
   ```bash
   alembic revision --autogenerate -m "description"
   ```
3. **Test locally**: Use docker-compose or local dev server
4. **Rebuild Docker** (if using containers):
   ```bash
   docker-compose up --build backend
   ```

## Troubleshooting

### Container won't start

**Check logs:**
```bash
docker-compose logs backend
```

**Common issues:**
- Database not ready: Wait for postgres health check
- Port already in use: Stop other services on port 8000
- Migration failed: Check migration files in `alembic/versions/`

### Database connection errors

**With Docker Compose:**
- Verify postgres is healthy: `docker-compose ps`
- Check DATABASE_URL uses `postgres:5432` (not localhost)

**With local development:**
- Verify postgres is running: `docker-compose ps postgres`
- Check DATABASE_URL uses `localhost:5433`

### Migration errors

**Alembic not found:**
- Docker: Ensure you rebuilt after adding dependencies
- Local: Activate virtual environment first

**Migration conflicts:**
```bash
# Check current version
alembic current

# View history
alembic history

# Force stamp to a specific version
alembic stamp head
```

### Dependencies not updating

**Docker Compose:**
```bash
# Force rebuild without cache
docker-compose build --no-cache backend
docker-compose up -d backend
```

**Local:**
```bash
# Reinstall all dependencies
uv pip install -e . --force-reinstall
```

## Testing

Run tests (when available):

```bash
# With Docker Compose
docker-compose exec backend pytest

# Local
source .venv/bin/activate
pytest
```

## Production Deployment

For production deployment to Google Cloud Run, see [DEPLOYMENT.md](DEPLOYMENT.md).

Key differences for production:
- Use Cloud SQL for database (managed PostgreSQL)
- Store secrets in Secret Manager
- Enable HTTPS
- Set appropriate resource limits
- Use production-grade JWT secret key

## Additional Resources

- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [SQLAlchemy 2.0 Documentation](https://docs.sqlalchemy.org/en/20/)
- [Alembic Documentation](https://alembic.sqlalchemy.org/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
