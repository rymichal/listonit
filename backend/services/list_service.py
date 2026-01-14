import secrets
from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from repositories.list_repository import ListRepository
from schemas.list import ListCreate, ListUpdate, ListDuplicate, ListResponse, ShareLinkCreate, ShareLinkResponse, JoinLinkResponse
from models.shopping_list import ShoppingList
from models.list_member import ListMember, MemberRole


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

    def create_share_link(
        self, list_id: str, link_data: ShareLinkCreate, user_id: str
    ) -> ShareLinkResponse:
        shopping_list = self.repository.get_by_id(list_id)

        if not shopping_list:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="List not found",
            )

        if shopping_list.owner_id != user_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only the owner can create share links",
            )

        share_token = secrets.token_urlsafe(16)
        shopping_list.share_token = share_token
        shopping_list.share_token_role = link_data.role
        shopping_list.share_token_enabled = True
        self.repository.db.commit()

        return ShareLinkResponse(
            link=f"https://listonit.app/join/{share_token}",
            role=link_data.role,
        )

    def regenerate_share_link(
        self, list_id: str, user_id: str
    ) -> ShareLinkResponse:
        shopping_list = self.repository.get_by_id(list_id)

        if not shopping_list:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="List not found",
            )

        if shopping_list.owner_id != user_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only the owner can regenerate share links",
            )

        share_token = secrets.token_urlsafe(16)
        shopping_list.share_token = share_token
        self.repository.db.commit()

        return ShareLinkResponse(
            link=f"https://listonit.app/join/{share_token}",
            role=shopping_list.share_token_role,
        )

    def revoke_share_link(self, list_id: str, user_id: str) -> None:
        shopping_list = self.repository.get_by_id(list_id)

        if not shopping_list:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="List not found",
            )

        if shopping_list.owner_id != user_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only the owner can revoke share links",
            )

        shopping_list.share_token = None
        shopping_list.share_token_enabled = False
        self.repository.db.commit()

    def join_via_share_link(self, token: str, user_id: str) -> JoinLinkResponse:
        shopping_list = self.repository.db.query(ShoppingList).filter(
            ShoppingList.share_token == token,
            ShoppingList.share_token_enabled == True,
        ).first()

        if not shopping_list:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Invalid or expired share link",
            )

        # Check if user is already a member
        existing_member = self.repository.db.query(ListMember).filter(
            ListMember.list_id == shopping_list.id,
            ListMember.user_id == user_id,
        ).first()

        if not existing_member:
            # Add user as a member with the share link's role
            new_member = ListMember(
                list_id=shopping_list.id,
                user_id=user_id,
                role=shopping_list.share_token_role or "editor",
            )
            self.repository.db.add(new_member)
            self.repository.db.commit()

        return JoinLinkResponse(
            list_id=shopping_list.id,
            name=shopping_list.name,
        )
