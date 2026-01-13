import uuid
from datetime import datetime
from enum import Enum as PyEnum
from sqlalchemy import String, DateTime, ForeignKey, Enum
from sqlalchemy.orm import Mapped, mapped_column, relationship

from database import Base


class MemberRole(str, PyEnum):
    owner = "owner"
    editor = "editor"
    viewer = "viewer"


class ListMember(Base):
    """List membership model - tracks who has access to which lists."""

    __tablename__ = "list_members"

    id: Mapped[str] = mapped_column(
        String(36), primary_key=True, default=lambda: str(uuid.uuid4())
    )
    list_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("shopping_lists.id"), index=True
    )
    user_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("users.id"), index=True
    )
    role: Mapped[MemberRole] = mapped_column(
        Enum(MemberRole), default=MemberRole.viewer
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow
    )

    # Relationships
    shopping_list: Mapped["ShoppingList"] = relationship(
        "ShoppingList", back_populates="members"
    )
    user: Mapped["User"] = relationship("User", back_populates="list_memberships")
