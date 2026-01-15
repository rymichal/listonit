from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from repositories.item_repository import ItemRepository
from repositories.list_repository import ListRepository
from schemas.item import ItemCreate, ItemUpdate, ItemResponse, ItemReorder
from models.item import Item
from websocket_manager import manager


class ItemService:
    def __init__(self, db: Session):
        self.repository = ItemRepository(db)
        self.list_repository = ListRepository(db)

    def create_item(
        self, list_id: str, item_data: ItemCreate, user_id: str
    ) -> ItemResponse:
        # Verify list exists and user has access
        self._verify_list_access(list_id, user_id)

        item = self.repository.create(list_id, item_data, user_id)
        response = ItemResponse.model_validate(item)

        # Broadcast to WebSocket clients
        import asyncio
        try:
            asyncio.create_task(
                manager.broadcast(
                    list_id,
                    {
                        "type": "item_added",
                        "item": response.model_dump(),
                        "user_id": user_id,
                    },
                )
            )
        except Exception:
            pass  # WebSocket broadcast is not critical

        return response

    def create_items_batch(
        self, list_id: str, names: list[str], user_id: str
    ) -> list[ItemResponse]:
        # Verify list exists and user has access
        self._verify_list_access(list_id, user_id)

        # Filter out empty names
        valid_names = [n.strip() for n in names if n.strip()]
        if not valid_names:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No valid item names provided",
            )

        items = self.repository.create_batch(list_id, valid_names, user_id)
        return [ItemResponse.model_validate(item) for item in items]

    def get_items(self, list_id: str, user_id: str) -> list[ItemResponse]:
        # Verify list exists and user has access
        self._verify_list_access(list_id, user_id)

        items = self.repository.get_all_for_list(list_id)
        return [ItemResponse.model_validate(item) for item in items]

    def get_item(self, list_id: str, item_id: str, user_id: str) -> ItemResponse:
        # Verify list exists and user has access
        self._verify_list_access(list_id, user_id)

        item = self._get_item_or_404(item_id, list_id)
        return ItemResponse.model_validate(item)

    def update_item(
        self, list_id: str, item_id: str, update_data: ItemUpdate, user_id: str
    ) -> ItemResponse:
        # Verify list exists and user has access
        self._verify_list_access(list_id, user_id)

        item = self._get_item_or_404(item_id, list_id)
        updated = self.repository.update(item, update_data)
        return ItemResponse.model_validate(updated)

    def toggle_item(
        self, list_id: str, item_id: str, user_id: str
    ) -> ItemResponse:
        # Verify list exists and user has access
        self._verify_list_access(list_id, user_id)

        item = self._get_item_or_404(item_id, list_id)
        toggled = self.repository.toggle_checked(item, user_id)
        response = ItemResponse.model_validate(toggled)

        # Broadcast to WebSocket clients
        import asyncio
        try:
            asyncio.create_task(
                manager.broadcast(
                    list_id,
                    {
                        "type": "item_updated",
                        "item": response.model_dump(),
                        "user_id": user_id,
                    },
                )
            )
        except Exception:
            pass  # WebSocket broadcast is not critical

        return response

    def delete_item(self, list_id: str, item_id: str, user_id: str) -> None:
        # Verify list exists and user has access
        self._verify_list_access(list_id, user_id)

        item = self._get_item_or_404(item_id, list_id)
        self.repository.delete(item)

    def clear_checked(self, list_id: str, user_id: str) -> int:
        # Verify list exists and user has access
        self._verify_list_access(list_id, user_id)

        return self.repository.delete_checked(list_id)

    def batch_check(
        self, list_id: str, item_ids: list[str], checked: bool, user_id: str
    ) -> int:
        # Verify list exists and user has access
        self._verify_list_access(list_id, user_id)

        return self.repository.batch_check(list_id, item_ids, checked, user_id)

    def batch_delete(self, list_id: str, item_ids: list[str], user_id: str) -> int:
        # Verify list exists and user has access
        self._verify_list_access(list_id, user_id)

        return self.repository.batch_delete(list_id, item_ids)

    def reorder_items(
        self, list_id: str, reorder_data: ItemReorder, user_id: str
    ) -> dict:
        """
        Reorder items in a list by updating their sort_index values.

        Args:
            list_id: The list ID
            reorder_data: ItemReorder with list of items and their new sort indices
            user_id: Current user ID (for access verification)

        Returns:
            Dict with 'success' and 'count' keys
        """
        # Verify list exists and user has access
        self._verify_list_access(list_id, user_id)

        # Convert ItemReorder entries to dict format for repository
        reorder_entries = [
            {"item_id": entry.item_id, "sort_index": entry.sort_index}
            for entry in reorder_data.items
        ]

        count = self.repository.bulk_update_sort_indices(list_id, reorder_entries)

        return {"success": True, "count": count}

    def _verify_list_access(self, list_id: str, user_id: str) -> None:
        shopping_list = self.list_repository.get_by_id(list_id)

        if not shopping_list:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="List not found",
            )

        if not any(member.user_id == user_id for member in shopping_list.members):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You don't have access to this list",
            )

    def _get_item_or_404(self, item_id: str, list_id: str) -> Item:
        item = self.repository.get_by_id(item_id)

        if not item:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Item not found",
            )

        if item.list_id != list_id:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Item not found in this list",
            )

        return item
