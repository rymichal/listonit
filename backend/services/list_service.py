from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from repositories.list_repository import ListRepository
from schemas.list import (
    ListCreate,
    ListUpdate,
    ListDuplicate,
    ListResponse,
    MemberInfo,
    UpdateMemberRole,
)
from models.shopping_list import ShoppingList
from models.list_member import ListMember, MemberRole
from models.user import User


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

    def get_list_members(self, list_id: str, user_id: str) -> list[MemberInfo]:
        shopping_list = self.repository.get_by_id(list_id)

        if not shopping_list:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="List not found",
            )

        if not self._user_has_access(shopping_list, user_id):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You don't have access to this list",
            )

        members = self.repository.db.query(ListMember).filter(
            ListMember.list_id == list_id
        ).all()

        member_infos = []
        for member in members:
            user = self.repository.db.query(User).filter(User.id == member.user_id).first()
            if user:
                member_infos.append(
                    MemberInfo(
                        id=member.user_id,
                        name=user.name,
                        avatar=None,
                        role=member.role,
                        created_at=member.created_at,
                    )
                )

        return member_infos

    def update_member_role(
        self, list_id: str, member_user_id: str, role_data: UpdateMemberRole, user_id: str
    ) -> MemberInfo:
        shopping_list = self.repository.get_by_id(list_id)

        if not shopping_list:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="List not found",
            )

        if shopping_list.owner_id != user_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only the owner can change member roles",
            )

        member = self.repository.db.query(ListMember).filter(
            ListMember.list_id == list_id,
            ListMember.user_id == member_user_id,
        ).first()

        if not member:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Member not found in this list",
            )

        # Prevent changing owner's role
        if member.role == MemberRole.owner:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Cannot change the owner's role",
            )

        member.role = role_data.role
        self.repository.db.commit()

        user = self.repository.db.query(User).filter(User.id == member.user_id).first()
        return MemberInfo(
            id=member.user_id,
            name=user.name if user else "Unknown",
            avatar=None,
            role=member.role,
            created_at=member.created_at,
        )

    def remove_member(self, list_id: str, member_user_id: str, user_id: str) -> None:
        shopping_list = self.repository.get_by_id(list_id)

        if not shopping_list:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="List not found",
            )

        # Owner can remove anyone, members can only remove themselves
        if user_id != member_user_id and shopping_list.owner_id != user_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You cannot remove this member",
            )

        member = self.repository.db.query(ListMember).filter(
            ListMember.list_id == list_id,
            ListMember.user_id == member_user_id,
        ).first()

        if not member:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Member not found in this list",
            )

        # Prevent removing the owner
        if member.role == MemberRole.owner:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Cannot remove the list owner",
            )

        self.repository.db.delete(member)
        self.repository.db.commit()

    def add_member(
        self, list_id: str, target_user_id: str, role: str, current_user_id: str
    ) -> MemberInfo:
        shopping_list = self.repository.get_by_id(list_id)

        if not shopping_list:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="List not found",
            )

        # Only owner can add members
        if shopping_list.owner_id != current_user_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only the owner can add members",
            )

        # Check if user exists
        target_user = self.repository.db.query(User).filter(User.id == target_user_id).first()
        if not target_user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found",
            )

        # Check if user is already a member
        existing_member = self.repository.db.query(ListMember).filter(
            ListMember.list_id == list_id,
            ListMember.user_id == target_user_id,
        ).first()

        if existing_member:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="User is already a member of this list",
            )

        # Add the new member
        new_member = ListMember(
            list_id=list_id,
            user_id=target_user_id,
            role=role,
        )
        self.repository.db.add(new_member)
        self.repository.db.commit()

        return MemberInfo(
            id=target_user.id,
            name=target_user.name,
            avatar=None,
            role=role,
            created_at=new_member.created_at,
        )
