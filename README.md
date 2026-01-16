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

1. **Start PostgreSQL and Redis with Docker Compose**

   ```bash
   cd listonit
   docker-compose up -d
   ```

   This starts:
   - PostgreSQL on port 5433 (credentials: `listonit` / `listonit_dev`)
   - Redis on port 6379

2. **Set up Python environment**

   ```bash
   cd backend
   python -m venv .venv
   source .venv/bin/activate  # On Windows: .venv\Scripts\activate
   ```

3. **Install dependencies**

   Using `uv` (recommended):
   ```bash
   uv pip install -e .
   ```

   Or using `pip`:
   ```bash
   pip install -e .
   ```

4. **Configure environment variables**

   Copy `.env.example` to `.env` and update as needed:
   ```bash
   cp .env.example .env
   ```

5. **Run the backend server**

   ```bash
   python main.py
   ```

   The API will be available at `http://localhost:8000`
   API documentation: `http://localhost:8000/docs`

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
