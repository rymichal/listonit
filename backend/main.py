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
    # Create database tables on startup
    Base.metadata.create_all(bind=engine)

    # Ensure mock user exists for development
    from sqlalchemy.orm import Session
    from database import SessionLocal

    db: Session = SessionLocal()
    try:
        existing_user = db.query(User).filter(User.id == settings.mock_user_id).first()
        if not existing_user:
            mock_user = User(
                id=settings.mock_user_id,
                email="dev@listonit.app",
                name="Dev User",
            )
            db.add(mock_user)
            db.commit()
    finally:
        db.close()

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
