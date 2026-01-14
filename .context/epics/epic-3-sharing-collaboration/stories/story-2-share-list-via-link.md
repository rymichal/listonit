# Story 3.2: Share List via Link

## Description
Generate a shareable link for easy list access. This story includes foundational sharing infrastructure (ListMember model, roles, share UI patterns) that enables future email sharing.

## Acceptance Criteria

### Shared Infrastructure
- [ ] ListMember model with role support (Editor, Viewer)
- [ ] List model fields: share_token, share_token_role, share_token_enabled
- [ ] "Share" button in list menu/header
- [ ] Role selector UI: Editor (default), Viewer

### Link Sharing
- [ ] "Get Link" option in share menu
- [ ] Toggle: "Anyone with link can [Edit/View]"
- [ ] Copy link button
- [ ] Link format: https://listonit.app/join/[token]
- [ ] Owner can revoke/regenerate link
- [ ] New users via link become Editors by default
- [ ] Backend validates roles and permissions on list operations

## Technical Implementation

### Database Models

```python
# models/list.py
class List(Base):
    __tablename__ = "lists"
    id: UUID = Column(UUID, primary_key=True, default=uuid4)
    owner_id: UUID = Column(UUID, ForeignKey("user.id"))
    name: str = Column(String)
    description: str = Column(String, nullable=True)
    # Share fields
    share_token: str = Column(String, nullable=True, unique=True)
    share_token_role: str = Column(String, default="editor")  # editor, viewer
    share_token_enabled: bool = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

# models/list_member.py
class ListMember(Base):
    __tablename__ = "list_members"
    id: UUID = Column(UUID, primary_key=True, default=uuid4)
    list_id: UUID = Column(UUID, ForeignKey("lists.id"), nullable=False)
    user_id: UUID = Column(UUID, ForeignKey("user.id"), nullable=False)
    role: str = Column(String, default="editor")  # editor, viewer
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    __table_args__ = (UniqueConstraint('list_id', 'user_id'),)
```

### FastAPI Endpoints

```python
@router.post("/lists/{list_id}/link")
async def create_share_link(
    list_id: UUID,
    link_data: ShareLinkCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    lst = db.query(List).filter(List.id == list_id).first()
    if not lst or lst.owner_id != current_user.id:
        raise HTTPException(403, "Only owner can create link")

    share_token = secrets.token_urlsafe(16)

    lst.share_token = share_token
    lst.share_token_role = link_data.role
    lst.share_token_enabled = True
    db.commit()

    return {
        "link": f"https://listonit.app/join/{share_token}",
        "role": link_data.role
    }

@router.post("/join/{token}")
async def join_via_link(
    token: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    lst = db.query(List).filter(
        List.share_token == token,
        List.share_token_enabled == True
    ).first()

    if not lst:
        raise HTTPException(404, "Invalid share link")

    # Check if already a member
    existing = db.query(ListMember).filter(
        ListMember.list_id == lst.id,
        ListMember.user_id == current_user.id
    ).first()

    if not existing:
        member = ListMember(
            list_id=lst.id,
            user_id=current_user.id,
            role=lst.share_token_role or "editor"
        )
        db.add(member)
        db.commit()

    return {"list_id": str(lst.id), "name": lst.name}

@router.post("/lists/{list_id}/link/regenerate")
async def regenerate_share_link(
    list_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    lst = db.query(List).filter(List.id == list_id).first()
    if not lst or lst.owner_id != current_user.id:
        raise HTTPException(403, "Only owner can regenerate link")

    share_token = secrets.token_urlsafe(16)
    lst.share_token = share_token
    db.commit()

    return {
        "link": f"https://listonit.app/join/{share_token}",
        "role": lst.share_token_role
    }

@router.delete("/lists/{list_id}/link")
async def revoke_share_link(
    list_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    lst = db.query(List).filter(List.id == list_id).first()
    if not lst or lst.owner_id != current_user.id:
        raise HTTPException(403, "Only owner can revoke link")

    lst.share_token = None
    lst.share_token_enabled = False
    db.commit()

    return {"success": True}
```

## Dependencies
- Story 1.1 (Create New List)
- User Authentication
- Story 3.3 (Manage List Members) - for role-based access control

## Notes
This story establishes core sharing infrastructure including the ListMember model, role system, and share UI patterns. These foundations enable future email-based sharing (Story 3.1) and member management (Story 3.3) features.

## Estimated Effort
6 story points (includes shared infrastructure)
