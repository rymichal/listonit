from datetime import datetime
from pydantic import BaseModel, Field


class ListBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    color: str | None = Field(default="#4CAF50", pattern=r"^#[0-9A-Fa-f]{6}$")
    icon: str | None = Field(default="shopping_cart", max_length=50)


class ListCreate(ListBase):
    pass


class ListUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=100)
    color: str | None = Field(default=None, pattern=r"^#[0-9A-Fa-f]{6}$")
    icon: str | None = Field(default=None, max_length=50)
    is_archived: bool | None = None


class ListDuplicate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=100)


class ShareLinkCreate(BaseModel):
    role: str = Field(default="editor", pattern=r"^(editor|viewer)$")


class ShareLinkResponse(BaseModel):
    link: str
    role: str


class JoinLinkResponse(BaseModel):
    list_id: str
    name: str


class MemberInfo(BaseModel):
    id: str
    name: str
    avatar: str | None = None
    role: str
    created_at: datetime


class UpdateMemberRole(BaseModel):
    role: str = Field(pattern=r"^(editor|viewer)$")


class ListResponse(ListBase):
    id: str
    owner_id: str
    is_archived: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
