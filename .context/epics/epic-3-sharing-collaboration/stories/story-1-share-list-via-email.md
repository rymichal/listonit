# Story 3.1: Share List via Email

## Status
**CANCELED** - Email sharing deferred beyond MVP. Core sharing infrastructure moved to Story 3.2.

## Description
List owners can invite others by email.

## Acceptance Criteria
- [ ] "Share" button in list menu/header
- [ ] Email input with validation
- [ ] Role selector: Editor (default), Viewer
- [ ] "Invite" sends email with app link
- [ ] Invited user sees list after signing up/in
- [ ] Show pending invites with "Resend" option

## Technical Implementation

### FastAPI Endpoint

```python
@router.post("/lists/{list_id}/invite")
async def invite_member(
    list_id: UUID,
    invite: InviteCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    background_tasks: BackgroundTasks
):
    lst = db.query(List).filter(List.id == list_id).first()
    if not lst or lst.owner_id != current_user.id:
        raise HTTPException(403, "Only owner can invite")

    # Check if user exists
    invitee = db.query(User).filter(User.email == invite.email).first()

    if invitee:
        # Direct add
        member = ListMember(
            list_id=list_id,
            user_id=invitee.id,
            role=invite.role
        )
        db.add(member)
        db.commit()

        # Send notification
        background_tasks.add_task(
            send_share_notification, invitee.email, lst.name, current_user.name
        )
    else:
        # Create pending invite
        invite_token = secrets.token_urlsafe(32)
        pending = PendingInvite(
            list_id=list_id,
            email=invite.email,
            role=invite.role,
            token=invite_token,
            expires_at=datetime.utcnow() + timedelta(days=7)
        )
        db.add(pending)
        db.commit()

        # Send invite email
        background_tasks.add_task(
            send_invite_email, invite.email, lst.name, current_user.name, invite_token
        )

    return {"status": "invited"}
```

## Dependencies
- Story 1.1 (Create New List)
- User Authentication

## Notes for Future Implementation
When this story is revisited, refer to Story 3.2 for shared infrastructure (ListMember model, role management, share UI patterns). Email-specific work will include sending invite notifications and managing pending invites for users not yet registered.

## Estimated Effort
5 story points
