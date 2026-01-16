from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from config import get_settings
from database import engine, Base
from api.v1.router import api_router

# Import models to register them with SQLAlchemy
from models import User, ShoppingList, ListMember  # noqa: F401

settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Database migrations handled by Alembic
    # Run via: alembic upgrade head (or automatically via entrypoint.sh in Docker)
    # Verify database connectivity on startup
    from sqlalchemy import text
    try:
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        print("✓ Database connection successful")
    except Exception as e:
        print(f"✗ Database connection failed: {e}")
        raise
    yield


app = FastAPI(
    title=settings.app_name,
    lifespan=lifespan,
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include API router
app.include_router(api_router)


@app.get("/")
def health_check():
    return {"status": "healthy", "app": settings.app_name}
