# Story 2.1: Add Item (Quick Mode)

## Description
Users can rapidly add items by typing names.

## Acceptance Criteria
- [ ] Text input always visible at top/bottom of list
- [ ] Pressing enter adds item immediately
- [ ] Item appears with default quantity (1)
- [ ] Input clears, ready for next item
- [ ] Support comma-separated batch add: "milk, eggs, bread"

## Technical Implementation

### FastAPI Endpoint

```python
@router.post("/lists/{list_id}/items", response_model=ItemResponse)
async def create_item(
    list_id: UUID,
    item_data: ItemCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if not has_list_access(db, current_user.id, list_id):
        raise HTTPException(403, "Access denied")

    item = Item(
        list_id=list_id,
        name=item_data.name,
        quantity=item_data.quantity or 1,
        unit=item_data.unit,
        note=item_data.note,
        created_by=current_user.id
    )
    db.add(item)
    db.commit()

    # Broadcast to members
    await broadcast_list_update(list_id, {
        "type": "item_added",
        "item": item.to_dict()
    })

    return item
```

### Flutter Implementation

```dart
class QuickAddController extends StateNotifier<String> {
  final ItemsNotifier _itemsNotifier;

  QuickAddController(this._itemsNotifier) : super('');

  Future<void> submitItems(String input, String listId) async {
    if (input.trim().isEmpty) return;

    // Split by commas for batch add
    final itemNames = input
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    for (final name in itemNames) {
      await _itemsNotifier.addItem(
        listId: listId,
        name: name,
        quantity: 1,
      );
    }

    state = ''; // Clear input
  }
}
```

## Dependencies
- Story 1.1 (Create New List)

## Estimated Effort
3 story points
