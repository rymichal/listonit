from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from repositories.list_repository import ListRepository
from schemas.list import ListCreate, ListUpdate, ListDuplicate, ListResponse
from models.shopping_list import ShoppingList


class ListService:
    def __init__(self, db: Session):
        self.repository = ListRepository(db)

    def create_list(self, list_data: ListCreate, owner_id: str) -> ListResponse:
        shopping_list = self.repository.create(list_data, owner_id)
        return ListResponse.model_validate(shopping_list)

    def get_list(self, list_id: str, user_id: str) -> ListResponse:
        shopping_list = self.repository.get_by_id(list_id)

        if not shopping_list:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="List not found",
            )

        # Check if user has access to this list
        if not self._user_has_access(shopping_list, user_id):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You don't have access to this list",
            )

        return ListResponse.model_validate(shopping_list)

    def get_user_lists(self, user_id: str) -> list[ListResponse]:
        lists = self.repository.get_all_for_user(user_id)
        return [ListResponse.model_validate(lst) for lst in lists]

    def update_list(
        self, list_id: str, update_data: ListUpdate, user_id: str
    ) -> ListResponse:
        shopping_list = self.repository.get_by_id(list_id)

        if not shopping_list:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="List not found",
            )

        if not self._user_can_edit(shopping_list, user_id):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You don't have permission to edit this list",
            )

        updated = self.repository.update(shopping_list, update_data)
        return ListResponse.model_validate(updated)

    def delete_list(self, list_id: str, user_id: str) -> None:
        shopping_list = self.repository.get_by_id(list_id)

        if not shopping_list:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="List not found",
            )

        if shopping_list.owner_id != user_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only the owner can delete this list",
            )

        self.repository.delete(shopping_list)

    def _user_has_access(self, shopping_list: ShoppingList, user_id: str) -> bool:
        return any(member.user_id == user_id for member in shopping_list.members)

    def _user_can_edit(self, shopping_list: ShoppingList, user_id: str) -> bool:
        for member in shopping_list.members:
            if member.user_id == user_id and member.role.value in ("owner", "editor"):
                return True
        return False

    def duplicate_list(
        self, list_id: str, duplicate_data: ListDuplicate, user_id: str
    ) -> ListResponse:
        original = self.repository.get_by_id(list_id)

        if not original:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="List not found",
            )

        if not self._user_has_access(original, user_id):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You don't have access to this list",
            )

        new_name = duplicate_data.name or f"{original.name} (Copy)"
        new_list = self.repository.duplicate(original, new_name, user_id)

        return ListResponse.model_validate(new_list)
