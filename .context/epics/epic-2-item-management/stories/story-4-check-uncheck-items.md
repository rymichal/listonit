# Story 2.4: Check/Uncheck Items

## Description
Users mark items as purchased during shopping.

## Acceptance Criteria
- [x] Checkbox to check items (UI only - not persisted to backend)
- [ ] Swipe-right gesture to check
- [x] Checked items: strikethrough text, move to bottom (UI only)
- [x] Uncheck: tap checkbox again (UI only)
- [ ] Record: checked_at timestamp, checked_by user (requires backend)
- [ ] Animation: satisfying check mark
- [ ] Option: "Check off by swipe" toggle in settings
- [ ] Backend API endpoint for check/uncheck
- [ ] Check state persisted to database

## Technical Implementation

### FastAPI Endpoint

```python
@router.patch("/items/{item_id}/check")
async def toggle_check(
    item_id: UUID,
    checked: bool,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    item = db.query(Item).filter(Item.id == item_id).first()
    if not item:
        raise HTTPException(404, "Item not found")

    # Verify access
    if not has_list_access(db, current_user.id, item.list_id):
        raise HTTPException(403, "Access denied")

    item.is_checked = checked
    item.checked_at = datetime.utcnow() if checked else None
    item.checked_by = current_user.id if checked else None
    item.updated_at = datetime.utcnow()
    db.commit()

    # Broadcast to list members
    await broadcast_list_update(
        item.list_id,
        {"type": "item_checked", "item_id": str(item_id), "checked": checked}
    )

    return item
```

### Flutter Implementation

```dart
class CheckableItemTile extends ConsumerWidget {
  final Item item;
  final String listId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsNotifier = ref.read(itemsProvider.notifier);

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.startToEnd,
      onDismissed: (_) {
        itemsNotifier.toggleCheck(
          listId: listId,
          itemId: item.id,
          checked: !item.isChecked,
        );
      },
      child: ListTile(
        leading: Checkbox(
          value: item.isChecked,
          onChanged: (_) {
            itemsNotifier.toggleCheck(
              listId: listId,
              itemId: item.id,
              checked: !item.isChecked,
            );
          },
        ),
        title: Text(
          item.name,
          style: TextStyle(
            decoration: item.isChecked ? TextDecoration.lineThrough : null,
            color: item.isChecked ? Colors.grey : null,
          ),
        ),
      ),
    );
  }
}
```

## Dependencies
- Story 2.1 (Add Item - Quick Mode)

## Estimated Effort
4 story points
