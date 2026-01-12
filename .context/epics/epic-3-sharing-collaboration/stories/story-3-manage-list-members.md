# Story 3.3: Manage List Members

## Description
Owners can view and manage who has access.

## Acceptance Criteria
- [ ] Member list shows: avatar, name, role, joined date
- [ ] Owner can change member roles
- [ ] Owner can remove members
- [ ] Non-owners see "Leave list" option
- [ ] Show pending invites separately

## Technical Implementation

### FastAPI Endpoints

```python
@router.get("/lists/{list_id}/members", response_model=List[MemberInfo])
async def list_members(
    list_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if not has_list_access(db, current_user.id, list_id):
        raise HTTPException(403, "Access denied")

    members = db.query(ListMember).join(User).filter(
        ListMember.list_id == list_id
    ).all()

    return [
        MemberInfo(
            id=m.user_id,
            name=m.user.name,
            avatar=m.user.avatar_url,
            role=m.role,
            joined_at=m.joined_at
        )
        for m in members
    ]

@router.patch("/lists/{list_id}/members/{user_id}")
async def update_member_role(
    list_id: UUID,
    user_id: UUID,
    role_data: UpdateRoleRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    lst = db.query(List).filter(List.id == list_id).first()
    if not lst or lst.owner_id != current_user.id:
        raise HTTPException(403, "Only owner can change roles")

    member = db.query(ListMember).filter(
        ListMember.list_id == list_id,
        ListMember.user_id == user_id
    ).first()

    if not member:
        raise HTTPException(404, "Member not found")

    member.role = role_data.role
    db.commit()

    return member

@router.delete("/lists/{list_id}/members/{user_id}")
async def remove_member(
    list_id: UUID,
    user_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    lst = db.query(List).filter(List.id == list_id).first()
    if not lst:
        raise HTTPException(404, "List not found")

    # Owner can remove anyone, members can only remove themselves
    if current_user.id != user_id and lst.owner_id != current_user.id:
        raise HTTPException(403, "Cannot remove this member")

    member = db.query(ListMember).filter(
        ListMember.list_id == list_id,
        ListMember.user_id == user_id
    ).delete()

    db.commit()

    return {"success": True}
```

## Dependencies
- Story 3.1 (Share List via Email)

## Estimated Effort
4 story points
