# Story 1.3: Edit List Properties

## Description
Users can rename lists and change their color/icon.

## Acceptance Criteria
- [ ] Long-press or menu icon opens edit options
- [ ] Inline rename with auto-save on blur
- [ ] Color/icon pickers identical to create flow
- [ ] Changes sync immediately
- [ ] Show "Saving..." indicator briefly

## Technical Implementation

### FastAPI Endpoint

```python
@router.patch("/lists/{list_id}", response_model=ListResponse)
async def update_list(
    list_id: UUID,
    list_data: ListUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    lst = db.query(List).filter(List.id == list_id).first()
    if not lst:
        raise HTTPException(404, "List not found")

    # Verify ownership
    if lst.owner_id != current_user.id:
        raise HTTPException(403, "Only owner can edit list")

    if list_data.name:
        lst.name = list_data.name
    if list_data.color:
        lst.color = list_data.color
    if list_data.icon:
        lst.icon = list_data.icon

    lst.updated_at = datetime.utcnow()
    db.commit()

    return lst
```

### Flutter Implementation

```dart
Future<void> updateList(String listId, {String? name, String? color, String? icon}) async {
  try {
    state = AsyncValue.loading();

    final response = await _api.updateList(
      listId,
      name: name,
      color: color,
      icon: icon,
    );

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
3 story points
