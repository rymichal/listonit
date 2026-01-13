# Story 1.2: View All Lists

## Description
Users see all their lists (owned + shared) on the home screen.
Users can click a list to view the list details page.

## Acceptance Criteria
- [x] Lists displayed as cards in a scrollable grid/list
- [x] Each card shows: name, color accent, icon, last updated
- [ ] Each card shows: item count (requires items backend)
- [ ] Shared lists show avatar stack of members (requires sharing feature)
- [x] Pull-to-refresh fetches latest from server
- [x] Empty state with illustration and "Create your first list" CTA
- [x] Loading indicator while fetching
- [x] Click list card to navigate to list detail page
- [x] List detail page shows list name, icon, and color
- [x] List detail page has add item input
- [x] List detail page shows items with checkbox to mark complete
- [x] List detail page shows completed items separately
- [x] Swipe to delete items on detail page

## Technical Implementation

### FastAPI Endpoint

```python
@router.get("/lists", response_model=List[ListWithMeta])
async def get_lists(
    include_archived: bool = False,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    query = db.query(List).join(ListMember).filter(
        ListMember.user_id == current_user.id
    )

    if not include_archived:
        query = query.filter(List.is_archived == False)

    lists = query.order_by(List.updated_at.desc()).all()

    # Enrich with item counts and member info
    result = []
    for lst in lists:
        item_count = db.query(Item).filter(
            Item.list_id == lst.id,
            Item.is_checked == False
        ).count()

        members = db.query(User).join(ListMember).filter(
            ListMember.list_id == lst.id
        ).limit(5).all()

        result.append(ListWithMeta(
            **lst.__dict__,
            unchecked_count=item_count,
            members=[MemberPreview(id=m.id, name=m.name, avatar=m.avatar_url) for m in members]
        ))

    return result
```

## Dependencies
- Story 1.1 (Create New List)
- User Authentication setup

## Estimated Effort
5 story points
