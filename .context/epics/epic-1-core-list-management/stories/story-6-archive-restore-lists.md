# Story 1.6: Archive/Restore Lists

## Description
Users can archive lists for later reference without deleting.

## Acceptance Criteria
- [ ] "Archive" option in list menu
- [ ] Archived lists hidden from main view
- [ ] "View Archived" option in settings/filter
- [ ] "Restore" action on archived lists
- [ ] Archived lists still accessible to shared members

## Technical Implementation

### FastAPI Endpoint

```python
@router.patch("/lists/{list_id}/archive")
async def archive_list(
    list_id: UUID,
    archive_data: ArchiveRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    lst = db.query(List).filter(List.id == list_id).first()
    if not lst:
        raise HTTPException(404, "List not found")

    # Only owner can archive
    if lst.owner_id != current_user.id:
        raise HTTPException(403, "Only owner can archive")

    lst.is_archived = archive_data.is_archived
    lst.updated_at = datetime.utcnow()
    db.commit()

    return lst
```

### Flutter Implementation

```dart
Future<void> toggleArchive(String listId, bool isArchived) async {
  try {
    final list = state.value!.firstWhere((l) => l.id == listId);

    final response = await _api.archiveList(listId, isArchived);

    state = AsyncValue.data(
      state.value!.map((l) => l.id == listId ? response : l).toList()
    );

    await _localDb.upsertList(response);
  } catch (e) {
    state = AsyncValue.error(e, StackTrace.current);
  }
}
```

## Dependencies
- Story 1.1 (Create New List)

## Estimated Effort
2 story points
