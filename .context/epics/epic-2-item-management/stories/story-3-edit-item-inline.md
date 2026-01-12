# Story 2.3: Edit Item Inline

## Description
Users can modify any item property directly in the list.

## Acceptance Criteria
- [ ] Tap item name → edit name inline
- [ ] Tap quantity → number input with +/- steppers
- [ ] Tap to expand item → reveal all fields
- [ ] Swipe right → quick check off
- [ ] Changes save on blur (debounced 500ms)
- [ ] Show subtle "Saved" indicator

## Technical Implementation

### FastAPI Endpoint

```python
@router.patch("/items/{item_id}", response_model=ItemResponse)
async def update_item(
    item_id: UUID,
    item_data: ItemUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    item = db.query(Item).filter(Item.id == item_id).first()
    if not item:
        raise HTTPException(404, "Item not found")

    if not has_list_access(db, current_user.id, item.list_id):
        raise HTTPException(403, "Access denied")

    # Update fields
    if item_data.name:
        item.name = item_data.name
    if item_data.quantity is not None:
        item.quantity = item_data.quantity
    if item_data.unit:
        item.unit = item_data.unit
    if item_data.note is not None:
        item.note = item_data.note

    item.updated_at = datetime.utcnow()
    db.commit()

    # Broadcast update
    await broadcast_list_update(item.list_id, {
        "type": "item_updated",
        "item": item.to_dict()
    })

    return item
```

### Flutter Implementation

```dart
class EditableItemTile extends ConsumerWidget {
  final Item item;
  final String listId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsNotifier = ref.read(itemsProvider.notifier);

    return GestureDetector(
      onTap: () => _showEditDialog(context, ref),
      child: ListTile(
        title: EditableText(
          initialValue: item.name,
          onSubmitted: (value) {
            itemsNotifier.updateItem(
              listId: listId,
              itemId: item.id,
              name: value,
            );
          },
        ),
        subtitle: Text('${item.quantity} ${item.unit ?? ''}'),
      ),
    );
  }
}
```

## Dependencies
- Story 2.1 (Add Item - Quick Mode)

## Estimated Effort
5 story points
