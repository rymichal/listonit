# Story 2.5: Delete Items

## Description
Users can remove items from lists.

## Acceptance Criteria
- [ ] Swipe left to reveal delete button
- [ ] Long-press to select, then bulk delete
- [ ] Confirmation for bulk delete (>3 items)
- [ ] Undo snackbar for 5 seconds
- [ ] Deleted items removed from UI immediately

## Technical Implementation

### FastAPI Endpoint

```python
@router.delete("/items/{item_id}")
async def delete_item(
    item_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    item = db.query(Item).filter(Item.id == item_id).first()
    if not item:
        raise HTTPException(404, "Item not found")

    if not has_list_access(db, current_user.id, item.list_id):
        raise HTTPException(403, "Access denied")

    list_id = item.list_id
    db.delete(item)
    db.commit()

    # Broadcast deletion
    await broadcast_list_update(list_id, {
        "type": "item_deleted",
        "item_id": str(item_id)
    })

    return {"success": True}
```

### Flutter Implementation

```dart
class DeleteableItemTile extends ConsumerWidget {
  final Item item;
  final String listId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsNotifier = ref.read(itemsProvider.notifier);

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 16),
        child: Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        itemsNotifier.deleteItem(listId: listId, itemId: item.id);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted: ${item.name}'),
            duration: Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () => itemsNotifier.restoreItem(item),
            ),
          ),
        );
      },
      child: ListTile(title: Text(item.name)),
    );
  }
}
```

## Dependencies
- Story 2.1 (Add Item - Quick Mode)

## Estimated Effort
3 story points
