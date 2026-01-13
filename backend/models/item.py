import uuid
from datetime import datetime
from sqlalchemy import String, DateTime, Boolean, Integer, ForeignKey, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from database import Base


class Item(Base):
    """Shopping list item model."""

    __tablename__ = "items"

    id: Mapped[str] = mapped_column(
        String(36), primary_key=True, default=lambda: str(uuid.uuid4())
    )
    list_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("shopping_lists.id", ondelete="CASCADE"), index=True
    )
    name: Mapped[str] = mapped_column(String(200))
    quantity: Mapped[int] = mapped_column(Integer, default=1)
    unit: Mapped[str | None] = mapped_column(String(20), nullable=True)
    note: Mapped[str | None] = mapped_column(Text, nullable=True)
    is_checked: Mapped[bool] = mapped_column(Boolean, default=False)
    checked_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    checked_by: Mapped[str | None] = mapped_column(
        String(36), ForeignKey("users.id"), nullable=True
    )
    sort_index: Mapped[int] = mapped_column(Integer, default=0)
    created_by: Mapped[str] = mapped_column(
        String(36), ForeignKey("users.id"), index=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow
    )

    # Relationships
    shopping_list: Mapped["ShoppingList"] = relationship(
        "ShoppingList", back_populates="items"
    )
    creator: Mapped["User"] = relationship(
        "User", foreign_keys=[created_by], backref="created_items"
    )
    checker: Mapped["User"] = relationship(
        "User", foreign_keys=[checked_by], backref="checked_items"
    )
