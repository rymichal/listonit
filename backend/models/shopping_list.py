import uuid
from datetime import datetime
from sqlalchemy import String, DateTime, Boolean, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship

from database import Base


class ShoppingList(Base):
    """Shopping list model."""

    __tablename__ = "shopping_lists"

    id: Mapped[str] = mapped_column(
        String(36), primary_key=True, default=lambda: str(uuid.uuid4())
    )
    owner_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("users.id"), index=True
    )
    name: Mapped[str] = mapped_column(String(100))
    color: Mapped[str] = mapped_column(String(7), default="#4CAF50")
    icon: Mapped[str] = mapped_column(String(50), default="shopping_cart")
    is_archived: Mapped[bool] = mapped_column(Boolean, default=False)
    # Share link fields
    share_token: Mapped[str | None] = mapped_column(String(32), unique=True, nullable=True)
    share_token_role: Mapped[str] = mapped_column(String(20), default="editor")
    share_token_enabled: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow
    )

    # Relationships
    owner: Mapped["User"] = relationship("User", back_populates="owned_lists")
    members: Mapped[list["ListMember"]] = relationship(
        "ListMember", back_populates="shopping_list", cascade="all, delete-orphan"
    )
    items: Mapped[list["Item"]] = relationship(
        "Item", back_populates="shopping_list", cascade="all, delete-orphan"
    )
