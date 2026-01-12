# Story 1.1: Create New List

## Description
Users can create a new shopping list with a name, optional color, and icon.

## Acceptance Criteria
- [ ] Tapping "+" opens create list modal
- [ ] Name field is required (min 1, max 100 chars)
- [ ] Color picker with 12 preset colors + custom hex
- [ ] Icon picker with 20 common shopping icons
- [ ] "Create" button disabled until name entered
- [ ] New list appears immediately (optimistic UI)
- [ ] Show error toast if sync fails, offer retry

## Technical Implementation

### FastAPI Endpoint

```python
@router.post("/lists", response_model=ListResponse)
async def create_list(
    list_data: ListCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    list_obj = List(
        owner_id=current_user.id,
        name=list_data.name,
        color=list_data.color or "#4CAF50",
        icon=list_data.icon or "shopping_cart"
    )
    db.add(list_obj)
    db.commit()

    # Auto-add owner as member
    member = ListMember(
        list_id=list_obj.id,
        user_id=current_user.id,
        role="owner"
    )
    db.add(member)
    db.commit()

    return list_obj
```

### Flutter Implementation

```dart
// List creation with Riverpod
class ListNotifier extends StateNotifier<AsyncValue<List<ShoppingList>>> {
  Future<void> createList(String name, {String? color, String? icon}) async {
    final tempId = uuid.v4();
    final optimisticList = ShoppingList(
      id: tempId,
      name: name,
      color: color ?? '#4CAF50',
      icon: icon ?? 'shopping_cart',
      isLocal: true,
    );

    // Optimistic update
    state = AsyncValue.data([...state.value!, optimisticList]);

    try {
      final response = await _api.createList(name: name, color: color, icon: icon);
      // Replace temp with real
      state = AsyncValue.data(
        state.value!.map((l) => l.id == tempId ? response : l).toList()
      );
      await _localDb.upsertList(response);
    } catch (e) {
      // Queue for sync if offline
      if (e is NetworkException) {
        await _syncQueue.enqueue(SyncAction.createList, optimisticList);
      } else {
        // Rollback
        state = AsyncValue.data(
          state.value!.where((l) => l.id != tempId).toList()
        );
        throw e;
      }
    }
  }
}
```

## Dependencies
- None (foundational feature)

## Estimated Effort
4 story points
