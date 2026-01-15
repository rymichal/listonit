from datetime import datetime
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from auth.dependencies import get_current_user_id
from database import get_db
from models.shopping_list import ShoppingList
from models.item import Item
from schemas.sync import BatchSyncRequest, BatchSyncResponse, SyncResultItem
from schemas.list import ListCreate, ListUpdate
from schemas.item import ItemCreate, ItemUpdate
from services.list_service import ListService
from services.item_service import ItemService

router = APIRouter(prefix="/sync", tags=["sync"])


@router.post("/batch", response_model=BatchSyncResponse, status_code=status.HTTP_200_OK)
def batch_sync(
    sync_data: BatchSyncRequest,
    db: Session = Depends(get_db),
    current_user_id: str = Depends(get_current_user_id),
):
    """Process batched offline changes from client.

    Accepts a list of sync actions (create, update, delete) and processes them
    in order of client_timestamp. Returns results for each action including
    any conflicts that occurred.
    """
    results = []
    synced_count = 0
    failed_count = 0
    conflict_count = 0

    # Sort actions by timestamp to maintain order
    sorted_actions = sorted(sync_data.actions, key=lambda a: a.client_timestamp)

    list_service = ListService(db)
    item_service = ItemService(db)

    for action in sorted_actions:
        try:
            if action.type == "create_list":
                list_data = action.payload
                list_create = ListCreate(
                    name=list_data.get("name"),
                    color=list_data.get("color", "#4CAF50"),
                    icon=list_data.get("icon", "shopping_cart"),
                )
                created_list = list_service.create_list(list_create, current_user_id)
                results.append(
                    SyncResultItem(
                        action_id=action.id,
                        success=True,
                        entity_type="list",
                        entity_id=created_list.id,
                    )
                )
                synced_count += 1

            elif action.type == "create_item":
                item_data = action.payload
                list_id = item_data.get("list_id")

                # Verify user owns the list
                shopping_list = db.query(ShoppingList).filter(
                    ShoppingList.id == list_id,
                    ShoppingList.owner_id == current_user_id,
                ).first()

                if not shopping_list:
                    raise ValueError("List not found or unauthorized")

                item_create = ItemCreate(
                    name=item_data.get("name"),
                    quantity=item_data.get("quantity", 1),
                    unit=item_data.get("unit"),
                    note=item_data.get("note"),
                )
                created_item = item_service.create_item(
                    list_id, item_create, current_user_id
                )
                results.append(
                    SyncResultItem(
                        action_id=action.id,
                        success=True,
                        entity_type="item",
                        entity_id=created_item.id,
                    )
                )
                synced_count += 1

            elif action.type == "update_list":
                list_id = action.entity_id
                list_data = action.payload

                # Verify user owns the list
                shopping_list = db.query(ShoppingList).filter(
                    ShoppingList.id == list_id,
                    ShoppingList.owner_id == current_user_id,
                ).first()

                if not shopping_list:
                    raise ValueError("List not found or unauthorized")

                # Check for conflicts (server version is newer)
                if shopping_list.updated_at > action.client_timestamp:
                    conflict_count += 1
                    results.append(
                        SyncResultItem(
                            action_id=action.id,
                            success=False,
                            entity_type="list",
                            entity_id=list_id,
                            conflict={
                                "id": list_id,
                                "server_version": {
                                    "name": shopping_list.name,
                                    "color": shopping_list.color,
                                    "icon": shopping_list.icon,
                                    "is_archived": shopping_list.is_archived,
                                    "updated_at": shopping_list.updated_at.isoformat(),
                                },
                            },
                        )
                    )
                else:
                    # Apply update
                    list_update = ListUpdate(
                        name=list_data.get("name"),
                        color=list_data.get("color"),
                        icon=list_data.get("icon"),
                        is_archived=list_data.get("is_archived"),
                    )
                    updated_list = list_service.update_list(
                        list_id, list_update, current_user_id
                    )
                    results.append(
                        SyncResultItem(
                            action_id=action.id,
                            success=True,
                            entity_type="list",
                            entity_id=list_id,
                        )
                    )
                    synced_count += 1

            elif action.type == "update_item":
                item_id = action.entity_id
                item_data = action.payload
                list_id = item_data.get("list_id")

                # Verify user owns the list
                shopping_list = db.query(ShoppingList).filter(
                    ShoppingList.id == list_id,
                    ShoppingList.owner_id == current_user_id,
                ).first()

                if not shopping_list:
                    raise ValueError("List not found or unauthorized")

                item = db.query(Item).filter(Item.id == item_id).first()
                if not item:
                    raise ValueError("Item not found")

                # Check for conflicts (server version is newer)
                if item.updated_at > action.client_timestamp:
                    conflict_count += 1
                    results.append(
                        SyncResultItem(
                            action_id=action.id,
                            success=False,
                            entity_type="item",
                            entity_id=item_id,
                            conflict={
                                "id": item_id,
                                "server_version": {
                                    "name": item.name,
                                    "quantity": item.quantity,
                                    "unit": item.unit,
                                    "note": item.note,
                                    "is_checked": item.is_checked,
                                    "updated_at": item.updated_at.isoformat(),
                                },
                            },
                        )
                    )
                else:
                    # Apply update
                    item_update = ItemUpdate(
                        name=item_data.get("name"),
                        quantity=item_data.get("quantity"),
                        unit=item_data.get("unit"),
                        note=item_data.get("note"),
                        is_checked=item_data.get("is_checked"),
                    )
                    updated_item = item_service.update_item(
                        list_id, item_id, item_update, current_user_id
                    )
                    results.append(
                        SyncResultItem(
                            action_id=action.id,
                            success=True,
                            entity_type="item",
                            entity_id=item_id,
                        )
                    )
                    synced_count += 1

            elif action.type == "delete_list":
                list_id = action.entity_id

                # Verify user owns the list
                shopping_list = db.query(ShoppingList).filter(
                    ShoppingList.id == list_id,
                    ShoppingList.owner_id == current_user_id,
                ).first()

                if not shopping_list:
                    raise ValueError("List not found or unauthorized")

                list_service.delete_list(list_id, current_user_id)
                results.append(
                    SyncResultItem(
                        action_id=action.id,
                        success=True,
                        entity_type="list",
                        entity_id=list_id,
                    )
                )
                synced_count += 1

            elif action.type == "delete_item":
                item_id = action.entity_id
                list_id = action.payload.get("list_id")

                # Verify user owns the list
                shopping_list = db.query(ShoppingList).filter(
                    ShoppingList.id == list_id,
                    ShoppingList.owner_id == current_user_id,
                ).first()

                if not shopping_list:
                    raise ValueError("List not found or unauthorized")

                item_service.delete_item(list_id, item_id, current_user_id)
                results.append(
                    SyncResultItem(
                        action_id=action.id,
                        success=True,
                        entity_type="item",
                        entity_id=item_id,
                    )
                )
                synced_count += 1

        except Exception as e:
            failed_count += 1
            results.append(
                SyncResultItem(
                    action_id=action.id,
                    success=False,
                    entity_type=action.entity_type,
                    entity_id=action.entity_id,
                    error=str(e),
                )
            )

    # Commit all changes
    try:
        db.commit()
    except Exception as e:
        db.rollback()
        raise

    return BatchSyncResponse(
        results=results,
        server_timestamp=datetime.utcnow(),
        synced_count=synced_count,
        failed_count=failed_count,
        conflict_count=conflict_count,
    )
