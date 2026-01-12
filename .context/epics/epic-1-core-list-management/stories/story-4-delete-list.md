# Story 1.4: Delete List

## Description
Users can permanently delete lists they own.

## Acceptance Criteria
- [ ] Delete option in list menu (owners only)
- [ ] Confirmation dialog: "Delete [List Name]? This will remove the list for all members."
- [ ] Shared members see "Leave list" instead
- [ ] Soft delete (30-day recovery window server-side)
- [ ] Undo snackbar for 5 seconds

## Technical Implementation

### FastAPI Endpoint

```python
@router.delete("/lists/{list_id}")
async def delete_list(
    list_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    lst = db.query(List).filter(List.id == list_id).first()
    if not lst:
        raise HTTPException(404, "List not found")

    # Verify ownership
    if lst.owner_id != current_user.id:
        raise HTTPException(403, "Only owner can delete list")

    # Soft delete with recovery window
    lst.deleted_at = datetime.utcnow()
    lst.updated_at = datetime.utcnow()
    db.commit()

    # Broadcast to members
    await broadcast_list_update(list_id, {
        "type": "list_deleted",
        "list_id": str(list_id)
    })

    return {"success": True}
```

### Flutter Implementation

```dart
Future<void> deleteList(String listId) async {
  try {
    await _api.deleteList(listId);

    state = AsyncValue.data(
      state.value!.where((l) => l.id != listId).toList()
    );

    await _localDb.deleteList(listId);
  } catch (e) {
    state = AsyncValue.error(e, StackTrace.current);
  }
}
```

## Dependencies
- Story 1.1 (Create New List)

## Estimated Effort
3 story points
