# Story 3.2: Share List via Link

## Description
Generate a shareable link for easy list access.

## Acceptance Criteria
- [ ] "Get Link" option in share menu
- [ ] Toggle: "Anyone with link can [Edit/View]"
- [ ] Copy link button
- [ ] Link format: https://listonit.app/join/[token]
- [ ] Owner can revoke/regenerate link
- [ ] New users via link become Editors by default

## Technical Implementation

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
- Story 3.1 (Share List via Email)

## Estimated Effort
4 story points
