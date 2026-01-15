from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from auth.dependencies import get_current_user_id
from database import get_db
from models import User
from schemas.auth import UserResponse

router = APIRouter(prefix="/users", tags=["users"])


@router.get("/search", response_model=list[UserResponse])
def search_users(
    q: str = Query("", description="Search query for user name"),
    db: Session = Depends(get_db),
    current_user_id: str = Depends(get_current_user_id),
):
    """Get all users, optionally filtered by search query on name. Current user is always included."""
    query = db.query(User).filter(User.is_active == True)  # noqa: E712

    if q:
        query = query.filter(User.name.ilike(f"%{q}%"))

    users = query.all()
    return users
