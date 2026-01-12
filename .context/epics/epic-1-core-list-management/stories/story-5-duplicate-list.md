# Story 1.5: Duplicate List

## Description
Users can create a copy of any list including all items.

## Acceptance Criteria
- [ ] "Duplicate" option in list menu
- [ ] New list named "[Original] (Copy)"
- [ ] All items copied (unchecked state)
- [ ] Sharing NOT copied (new list is private)
- [ ] Navigate to new list after creation

## Technical Implementation

### FastAPI Endpoint

```python
@router.post("/lists/{list_id}/duplicate", response_model=ListResponse)
async def duplicate_list(
    list_id: UUID,
    duplicate_data: ListDuplicate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    original = db.query(List).filter(List.id == list_id).first()
    if not original:
        raise HTTPException(404, "List not found")

    # Verify access (owner or member)
    if not has_list_access(db, current_user.id, list_id):
        raise HTTPException(403, "Access denied")

    # Create new list
    new_list = List(
        owner_id=current_user.id,
        name=duplicate_data.name or f"{original.name} (Copy)",
        color=original.color,
        icon=original.icon,
        sort_mode=original.sort_mode
    )
    db.add(new_list)
    db.flush()

    # Copy all items
    items = db.query(Item).filter(Item.list_id == list_id).all()
    for item in items:
        new_item = Item(
            list_id=new_list.id,
            name=item.name,
            quantity=item.quantity,
            unit=item.unit,
            note=item.note,
            is_checked=False,  # Reset to unchecked
            sort_index=item.sort_index,
            created_by=current_user.id
        )
        db.add(new_item)

    # Add owner as member
    member = ListMember(
        list_id=new_list.id,
        user_id=current_user.id,
        role="owner"
    )
    db.add(member)
    db.commit()

    return new_list
```

## Dependencies
- Story 1.1 (Create New List)
- Epic 2: Item Management stories

## Estimated Effort
5 story points
