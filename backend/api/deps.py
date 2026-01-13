from fastapi import Depends
from sqlalchemy.orm import Session

from database import get_db
from config import get_settings


def get_current_user_id() -> str:
    """
    Mock user dependency for development.
    Returns a hardcoded user ID until authentication is implemented.
    """
    settings = get_settings()
    return settings.mock_user_id


def get_db_session():
    """Database session dependency."""
    return Depends(get_db)
