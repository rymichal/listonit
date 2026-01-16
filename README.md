# Listonit

A collaborative shopping list application that enables real-time synchronization across multiple users and devices with offline support.

## Tech Stack

- **Frontend**: Flutter (Dart), Riverpod for state management
- **Backend**: FastAPI (Python 3.11+)
- **Database**: PostgreSQL
- **Cache/Pub-Sub**: Redis
- **Authentication**: JWT with refresh tokens
- **Local Storage**: SQLite (mobile), SharedPreferences
- **Mobile Platforms**: iOS & Android
- **Real-time Communication**: WebSockets

## Project Structure

```
listonit/
├── backend/              # FastAPI server
│   ├── api/             # API endpoints
│   ├── models/          # SQLAlchemy ORM models
│   ├── schemas/         # Pydantic schemas
│   ├── services/        # Business logic
│   ├── repositories/    # Data access layer
│   ├── auth/            # Authentication logic
│   ├── config.py        # Configuration
│   └── main.py          # Entry point
│
└── client/listonit/     # Flutter application
    ├── lib/
    │   ├── features/    # Feature modules
    │   ├── core/        # Core utilities
    │   └── shared/      # Shared widgets & providers
    ├── integration_test/ # Integration tests
    └── test/            # Unit tests
```

## Getting Started

### Prerequisites

- **Backend**: Python 3.11+, Docker & Docker Compose
- **Frontend**: Flutter SDK 3.10.3+, Dart 3.10.3+

### Backend Setup

You can run the backend either locally or using Docker. Docker is recommended for easier setup and production-like environment.

#### Option A: Docker Setup (Recommended)

1. **Build and start all services with Docker Compose**

   ```bash
   cd listonit
   docker-compose up --build
   ```

   This starts:
   - PostgreSQL on port 5433 (credentials: `listonit` / `listonit_dev`)
   - Redis on port 6379
   - Backend API on port 8000

   The backend will automatically run database migrations on startup.

2. **Verify the backend is running**

   - API health check: `http://localhost:8000/`
   - API documentation: `http://localhost:8000/docs`

3. **Seed the database (optional)**

   ```bash
   docker-compose exec backend python scripts/seed.py
   ```

   This creates test users (ryan/hanna with password: asdfasdf)

4. **View logs**

   ```bash
   # All services
   docker-compose logs -f

   # Backend only
   docker-compose logs -f backend
   ```

5. **Stop services**

   ```bash
   # Stop but keep containers
   docker-compose stop

   # Stop and remove containers
   docker-compose down

   # Stop, remove containers, and delete volumes (CAUTION: deletes all data)
   docker-compose down -v
   ```

#### Option B: Local Development Setup

1. **Start dependencies**

   ```bash
   docker-compose up -d postgres redis
   ```

2. **Setup Python environment**

   ```bash
   cd backend
   python -m venv .venv
   source .venv/bin/activate  # On Windows: .venv\Scripts\activate
   uv pip install -e .
   ```

3. **Configure for local**

   Create `.env`:
   ```env
   DATABASE_URL=postgresql://listonit:listonit_dev@localhost:5433/listonit
   DEBUG=true
   ```

4. **Run migrations**

   ```bash
   alembic upgrade head
   ```

5. **Start server**

   ```bash
   uvicorn main:app --host 0.0.0.0 --port 8000 --reload
   ```

### Database Migrations

```bash
# Docker
docker-compose exec backend alembic upgrade head
docker-compose exec backend alembic revision --autogenerate -m "Description"

# Local
alembic upgrade head
alembic revision --autogenerate -m "Description"
```

### Rebuilding Containers

```bash
# After code/dependency changes
docker-compose up --build backend

# Force rebuild (no cache)
docker-compose build --no-cache backend
```

### Cloud Run Deployment

For production deployment to GCP Cloud Run with Cloud SQL, see [backend/DEPLOYMENT.md](backend/DEPLOYMENT.md) for detailed instructions.

### Client Setup

1. **Navigate to the client directory**

   ```bash
   cd client/listonit
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Generate code (Riverpod)**

   ```bash
   dart run build_runner build
   ```

4. **Configure environment**

   Create a `.env` file in `client/listonit/` with backend URL:
   ```
   BACKEND_URL=http://localhost:8000
   ```

5. **Run the app**

   ```bash
   # For iOS
   flutter run -d iphone

   # For Android
   flutter run -d android

   # For web (if supported)
   flutter run -d web
   ```

## Running Integration Tests

### Client Integration Tests

The client includes integration tests for key features:
- `lists_test.dart` - List creation and management
- `list_detail_test.dart` - List detail page interactions
- `checked_items_test.dart` - Item checking/unchecking
- `sorting_test.dart` - Item sorting functionality
- `offline_support_test.dart` - Offline sync behavior
- `sharing_and_collaboration_test.dart` - Sharing features

Run all integration tests:

```bash
cd client/listonit
flutter test integration_test/
```

Run a specific test:

```bash
flutter test integration_test/lists_test.dart
```

Run on a specific device:

```bash
flutter test -d iphone integration_test/
```

### Backend Tests

To run backend tests (when available):

```bash
cd backend
pytest
```

## Development Workflow

1. **Understand the story** - Check `.context/epics/` for feature requirements
2. **Make your changes** - Follow existing code patterns and conventions
3. **Test locally** - Run relevant integration or unit tests
4. **Commit with reference** - Use format: `feat(epic-X): X.Y - Description`

## API Documentation

The backend provides interactive API docs:
- **Swagger UI**: `http://localhost:8000/docs`
- **ReDoc**: `http://localhost:8000/redoc`
- **API Overview**: See `backend/API.md`

## Database Migrations

Migrations are managed with Alembic:

```bash
cd backend

# Create a new migration
alembic revision --autogenerate -m "Description"

# Apply migrations
alembic upgrade head

# Rollback
alembic downgrade -1
```

## Troubleshooting

### Backend Won't Start

1. Verify Docker containers are running: `docker-compose ps`
2. Check PostgreSQL is accessible: `psql -h localhost -p 5433 -U listonit -d listonit`
3. Verify environment variables in `.env`

### Flutter Dependencies Issues

```bash
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### Integration Tests Fail

1. Ensure backend is running on the expected URL
2. Check network connectivity between client and backend
3. Clear app cache: `flutter clean`
4. Rebuild and retry

## Resources

- **Epics & Stories**: See `.context/EPICS_AND_FEATURES_GUIDE.md`
- **System Prompt**: See `SYSTEM_PROMPT.md` for implementation guidelines
- **API Details**: See `backend/API.md`
