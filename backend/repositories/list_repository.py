from sqlalchemy.orm import Session

from models.shopping_list import ShoppingList
from models.list_member import ListMember, MemberRole
from schemas.list import ListCreate, ListUpdate


class ListRepository:
    def __init__(self, db: Session):
        self.db = db

    def create(self, list_data: ListCreate, owner_id: str) -> ShoppingList:
        shopping_list = ShoppingList(
            owner_id=owner_id,
            name=list_data.name,
            color=list_data.color or "#4CAF50",
            icon=list_data.icon or "shopping_cart",
        )
        self.db.add(shopping_list)
        self.db.flush()

        # Auto-add owner as member with owner role
        member = ListMember(
            list_id=shopping_list.id,
            user_id=owner_id,
            role=MemberRole.owner,
        )
        self.db.add(member)
        self.db.commit()
        self.db.refresh(shopping_list)

        return shopping_list

    def get_by_id(self, list_id: str) -> ShoppingList | None:
        return self.db.query(ShoppingList).filter(ShoppingList.id == list_id).first()

    def get_all_for_user(self, user_id: str) -> list[ShoppingList]:
        return (
            self.db.query(ShoppingList)
            .join(ListMember, ShoppingList.id == ListMember.list_id)
            .filter(ListMember.user_id == user_id)
            .filter(ShoppingList.is_archived == False)
            .order_by(ShoppingList.updated_at.desc())
            .all()
        )

    def update(self, shopping_list: ShoppingList, update_data: ListUpdate) -> ShoppingList:
        update_dict = update_data.model_dump(exclude_unset=True)
        for field, value in update_dict.items():
            setattr(shopping_list, field, value)

        self.db.commit()
        self.db.refresh(shopping_list)
        return shopping_list

    def delete(self, shopping_list: ShoppingList) -> None:
        self.db.delete(shopping_list)
        self.db.commit()
