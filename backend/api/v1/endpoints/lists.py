from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from auth.dependencies import get_current_user_id
from database import get_db
from schemas.list import ListCreate, ListUpdate, ListDuplicate, ListResponse
from services.list_service import ListService

router = APIRouter(prefix="/lists", tags=["lists"])


@router.post("", response_model=ListResponse, status_code=status.HTTP_201_CREATED)
def create_list(
    list_data: ListCreate,
    db: Session = Depends(get_db),
    current_user_id: str = Depends(get_current_user_id),
):
    """Create a new shopping list."""
    service = ListService(db)
    return service.create_list(list_data, current_user_id)


@router.get("", response_model=list[ListResponse])
def get_lists(
    db: Session = Depends(get_db),
    current_user_id: str = Depends(get_current_user_id),
):
    """Get all shopping lists for the current user."""
    service = ListService(db)
    return service.get_user_lists(current_user_id)


@router.get("/{list_id}", response_model=ListResponse)
def get_list(
    list_id: str,
    db: Session = Depends(get_db),
    current_user_id: str = Depends(get_current_user_id),
):
    """Get a specific shopping list by ID."""
    service = ListService(db)
    return service.get_list(list_id, current_user_id)


@router.patch("/{list_id}", response_model=ListResponse)
def update_list(
    list_id: str,
    update_data: ListUpdate,
    db: Session = Depends(get_db),
    current_user_id: str = Depends(get_current_user_id),
):
    """Update a shopping list."""
    service = ListService(db)
    return service.update_list(list_id, update_data, current_user_id)


@router.delete("/{list_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_list(
    list_id: str,
    db: Session = Depends(get_db),
    current_user_id: str = Depends(get_current_user_id),
):
    """Delete a shopping list."""
    service = ListService(db)
    service.delete_list(list_id, current_user_id)


@router.post("/{list_id}/duplicate", response_model=ListResponse, status_code=status.HTTP_201_CREATED)
def duplicate_list(
    list_id: str,
    duplicate_data: ListDuplicate,
    db: Session = Depends(get_db),
    current_user_id: str = Depends(get_current_user_id),
):
    """Duplicate a shopping list. Creates a new private copy owned by the current user."""
    service = ListService(db)
    return service.duplicate_list(list_id, duplicate_data, current_user_id)
