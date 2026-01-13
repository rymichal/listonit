import uuid
from datetime import datetime
from sqlalchemy import String, DateTime
from sqlalchemy.orm import Mapped, mapped_column, relationship

from database import Base


class User(Base):
    """User model - stub for future authentication implementation."""

    __tablename__ = "users"

    id: Mapped[str] = mapped_column(
        String(36), primary_key=True, default=lambda: str(uuid.uuid4())
    )
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True)
    name: Mapped[str] = mapped_column(String(100))
    created_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow
    )

    # Relationships
    owned_lists: Mapped[list["ShoppingList"]] = relationship(
        "ShoppingList", back_populates="owner", cascade="all, delete-orphan"
    )
    list_memberships: Mapped[list["ListMember"]] = relationship(
        "ListMember", back_populates="user", cascade="all, delete-orphan"
    )
