from datetime import datetime
from sqlalchemy.orm import Session
from sqlalchemy import func

from models.item import Item
from schemas.item import ItemCreate, ItemUpdate


class ItemRepository:
    def __init__(self, db: Session):
        self.db = db

    def create(self, list_id: str, item_data: ItemCreate, user_id: str) -> Item:
        # Get the next sort index
        max_sort = self.db.query(func.max(Item.sort_index)).filter(
            Item.list_id == list_id
        ).scalar() or 0

        item = Item(
            list_id=list_id,
            name=item_data.name,
            quantity=item_data.quantity,
            unit=item_data.unit,
            note=item_data.note,
            sort_index=max_sort + 1,
            created_by=user_id,
        )
        self.db.add(item)
        self.db.commit()
        self.db.refresh(item)
        return item

    def create_batch(
        self, list_id: str, names: list[str], user_id: str
    ) -> list[Item]:
        # Get the next sort index
        max_sort = self.db.query(func.max(Item.sort_index)).filter(
            Item.list_id == list_id
        ).scalar() or 0

        items = []
        for i, name in enumerate(names):
            item = Item(
                list_id=list_id,
                name=name.strip(),
                quantity=1,
                sort_index=max_sort + i + 1,
                created_by=user_id,
            )
            self.db.add(item)
            items.append(item)

        self.db.commit()
        for item in items:
            self.db.refresh(item)
        return items

    def get_by_id(self, item_id: str) -> Item | None:
        return self.db.query(Item).filter(Item.id == item_id).first()

    def get_all_for_list(self, list_id: str) -> list[Item]:
        return (
            self.db.query(Item)
            .filter(Item.list_id == list_id)
            .order_by(Item.is_checked, Item.sort_index)
            .all()
        )

    def update(self, item: Item, update_data: ItemUpdate) -> Item:
        update_dict = update_data.model_dump(exclude_unset=True)
        for field, value in update_dict.items():
            setattr(item, field, value)

        self.db.commit()
        self.db.refresh(item)
        return item

    def toggle_checked(self, item: Item, user_id: str) -> Item:
        item.is_checked = not item.is_checked
        if item.is_checked:
            item.checked_at = datetime.utcnow()
            item.checked_by = user_id
        else:
            item.checked_at = None
            item.checked_by = None

        self.db.commit()
        self.db.refresh(item)
        return item

    def delete(self, item: Item) -> None:
        self.db.delete(item)
        self.db.commit()

    def delete_checked(self, list_id: str) -> int:
        count = (
            self.db.query(Item)
            .filter(Item.list_id == list_id, Item.is_checked == True)
            .delete()
        )
        self.db.commit()
        return count

    def batch_check(
        self, list_id: str, item_ids: list[str], checked: bool, user_id: str
    ) -> int:
        items = (
            self.db.query(Item)
            .filter(Item.id.in_(item_ids), Item.list_id == list_id)
            .all()
        )

        now = datetime.utcnow()
        for item in items:
            item.is_checked = checked
            item.checked_at = now if checked else None
            item.checked_by = user_id if checked else None
            item.updated_at = now

        self.db.commit()
        return len(items)

    def batch_delete(self, list_id: str, item_ids: list[str]) -> int:
        count = (
            self.db.query(Item)
            .filter(Item.id.in_(item_ids), Item.list_id == list_id)
            .delete(synchronize_session=False)
        )
        self.db.commit()
        return count

    def bulk_update_sort_indices(
        self, list_id: str, reorder_data: list[dict]
    ) -> int:
        """
        Bulk update sort_index for multiple items.

        Args:
            list_id: The list ID
            reorder_data: List of dicts with 'item_id' and 'sort_index'

        Returns:
            Number of items updated
        """
        updated_count = 0
        now = datetime.utcnow()

        for entry in reorder_data:
            item = (
                self.db.query(Item)
                .filter(Item.id == entry["item_id"], Item.list_id == list_id)
                .first()
            )
            if item:
                item.sort_index = entry["sort_index"]
                item.updated_at = now
                updated_count += 1

        self.db.commit()
        return updated_count
