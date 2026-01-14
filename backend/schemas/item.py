from datetime import datetime
from pydantic import BaseModel, Field


class ItemBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=200)
    quantity: int = Field(default=1, ge=1)
    unit: str | None = Field(default=None, max_length=20)
    note: str | None = Field(default=None, max_length=500)


class ItemCreate(ItemBase):
    pass


class ItemUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=200)
    quantity: int | None = Field(default=None, ge=1)
    unit: str | None = Field(default=None, max_length=20)
    note: str | None = Field(default=None, max_length=500)
    is_checked: bool | None = None
    sort_index: int | None = None


class ItemResponse(ItemBase):
    id: str
    list_id: str
    is_checked: bool
    checked_at: datetime | None
    checked_by: str | None
    sort_index: int
    created_by: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class ItemBatchCreate(BaseModel):
    names: list[str] = Field(..., min_length=1)


class ItemBatchCheck(BaseModel):
    item_ids: list[str] = Field(..., min_length=1)
    checked: bool


class ItemBatchDelete(BaseModel):
    item_ids: list[str] = Field(..., min_length=1)


class BatchOperationResponse(BaseModel):
    success: bool
    count: int
