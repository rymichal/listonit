from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from auth.dependencies import get_current_user_id
from database import get_db
from schemas.item import (
    ItemCreate,
    ItemUpdate,
    ItemResponse,
    ItemBatchCreate,
    ItemBatchCheck,
    ItemBatchDelete,
    BatchOperationResponse,
    ItemReorder,
)
from services.item_service import ItemService

router = APIRouter(prefix="/lists/{list_id}/items", tags=["items"])


@router.post("", response_model=ItemResponse, status_code=status.HTTP_201_CREATED)
async def create_item(
    list_id: str,
    item_data: ItemCreate,
    db: Session = Depends(get_db),
    current_user_id: str = Depends(get_current_user_id),
):
    """Create a new item in a shopping list."""
    service = ItemService(db)
    return service.create_item(list_id, item_data, current_user_id)


@router.post("/batch", response_model=list[ItemResponse], status_code=status.HTTP_201_CREATED)
async def create_items_batch(
    list_id: str,
    batch_data: ItemBatchCreate,
    db: Session = Depends(get_db),
    current_user_id: str = Depends(get_current_user_id),
):
    """Create multiple items at once (for comma-separated input)."""
    service = ItemService(db)
    return service.create_items_batch(list_id, batch_data.names, current_user_id)


@router.get("", response_model=list[ItemResponse])
def get_items(
    list_id: str,
    db: Session = Depends(get_db),
    current_user_id: str = Depends(get_current_user_id),
):
    """Get all items in a shopping list."""
    service = ItemService(db)
    return service.get_items(list_id, current_user_id)


@router.get("/{item_id}", response_model=ItemResponse)
def get_item(
    list_id: str,
    item_id: str,
    db: Session = Depends(get_db),
    current_user_id: str = Depends(get_current_user_id),
):
    """Get a specific item."""
    service = ItemService(db)
    return service.get_item(list_id, item_id, current_user_id)


@router.patch("/{item_id}", response_model=ItemResponse)
async def update_item(
    list_id: str,
    item_id: str,
    update_data: ItemUpdate,
    db: Session = Depends(get_db),
    current_user_id: str = Depends(get_current_user_id),
):
    """Update an item."""
    service = ItemService(db)
    return service.update_item(list_id, item_id, update_data, current_user_id)


@router.post("/{item_id}/toggle", response_model=ItemResponse)
async def toggle_item(
    list_id: str,
    item_id: str,
    db: Session = Depends(get_db),
    current_user_id: str = Depends(get_current_user_id),
):
    """Toggle an item's checked status."""
    service = ItemService(db)
    return service.toggle_item(list_id, item_id, current_user_id)


@router.delete("/{item_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_item(
    list_id: str,
    item_id: str,
    db: Session = Depends(get_db),
    current_user_id: str = Depends(get_current_user_id),
):
    """Delete an item."""
    service = ItemService(db)
    service.delete_item(list_id, item_id, current_user_id)


@router.delete("", status_code=status.HTTP_200_OK)
def clear_checked_items(
    list_id: str,
    db: Session = Depends(get_db),
    current_user_id: str = Depends(get_current_user_id),
):
    """Delete all checked items in a list."""
    service = ItemService(db)
    count = service.clear_checked(list_id, current_user_id)
    return {"deleted_count": count}


@router.post("/batch-check", response_model=BatchOperationResponse)
async def batch_check_items(
    list_id: str,
    batch_data: ItemBatchCheck,
    db: Session = Depends(get_db),
    current_user_id: str = Depends(get_current_user_id),
):
    """Check or uncheck multiple items at once."""
    service = ItemService(db)
    count = service.batch_check(
        list_id, batch_data.item_ids, batch_data.checked, current_user_id
    )
    return BatchOperationResponse(success=True, count=count)


@router.post("/batch-delete", response_model=BatchOperationResponse)
def batch_delete_items(
    list_id: str,
    batch_data: ItemBatchDelete,
    db: Session = Depends(get_db),
    current_user_id: str = Depends(get_current_user_id),
):
    """Delete multiple items at once."""
    service = ItemService(db)
    count = service.batch_delete(list_id, batch_data.item_ids, current_user_id)
    return BatchOperationResponse(success=True, count=count)


@router.post("/reorder", response_model=BatchOperationResponse)
async def reorder_items(
    list_id: str,
    reorder_data: ItemReorder,
    db: Session = Depends(get_db),
    current_user_id: str = Depends(get_current_user_id),
):
    """Reorder items in a list by updating their sort indices."""
    service = ItemService(db)
    result = service.reorder_items(list_id, reorder_data, current_user_id)
    return BatchOperationResponse(success=result["success"], count=result["count"])
