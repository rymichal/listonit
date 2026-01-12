# Story 2.6: Bulk Item Actions

## Description
Users can perform actions on multiple items at once.

## Acceptance Criteria
- [ ] Long-press item to enter selection mode
- [ ] Checkboxes appear on all items
- [ ] "Select All" option
- [ ] Actions toolbar: Delete, Check All, Uncheck All
- [ ] Exit selection mode on action complete or back

## Technical Implementation

### FastAPI Endpoints

```python
@router.post("/lists/{list_id}/items/batch-check")
async def batch_check_items(
    list_id: UUID,
    batch_data: BatchCheckRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if not has_list_access(db, current_user.id, list_id):
        raise HTTPException(403, "Access denied")

    items = db.query(Item).filter(
        Item.id.in_(batch_data.item_ids),
        Item.list_id == list_id
    ).all()

    for item in items:
        item.is_checked = batch_data.checked
        item.checked_at = datetime.utcnow() if batch_data.checked else None
        item.checked_by = current_user.id if batch_data.checked else None
        item.updated_at = datetime.utcnow()

    db.commit()

    # Broadcast
    await broadcast_list_update(list_id, {
        "type": "items_batch_checked",
        "item_ids": [str(id) for id in batch_data.item_ids],
        "checked": batch_data.checked
    })

    return {"success": True, "updated_count": len(items)}

@router.delete("/lists/{list_id}/items/batch")
async def batch_delete_items(
    list_id: UUID,
    batch_data: BatchDeleteRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if not has_list_access(db, current_user.id, list_id):
        raise HTTPException(403, "Access denied")

    deleted_count = db.query(Item).filter(
        Item.id.in_(batch_data.item_ids),
        Item.list_id == list_id
    ).delete()

    db.commit()

    # Broadcast
    await broadcast_list_update(list_id, {
        "type": "items_batch_deleted",
        "item_ids": [str(id) for id in batch_data.item_ids]
    })

    return {"success": True, "deleted_count": deleted_count}
```

### Flutter Implementation

```dart
class SelectableItemList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(itemsProvider);
    final selectedIds = ref.watch(selectedItemsProvider);
    final isSelectionMode = selectedIds.isNotEmpty;

    return Column(
      children: [
        if (isSelectionMode)
          Container(
            color: Colors.blue.withOpacity(0.2),
            child: Row(
              children: [
                Expanded(
                  child: Text('${selectedIds.length} selected'),
                ),
                IconButton(
                  icon: Icon(Icons.check_circle),
                  onPressed: () => _checkSelected(context, ref),
                ),
                IconButton(
                  icon: Icon(Icons.radio_button_unchecked),
                  onPressed: () => _uncheckSelected(context, ref),
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => _deleteSelected(context, ref),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final isSelected = selectedIds.contains(item.id);

              return GestureDetector(
                onLongPress: () {
                  ref.read(selectedItemsProvider.notifier).toggle(item.id);
                },
                child: ListTile(
                  leading: isSelectionMode
                      ? Checkbox(
                          value: isSelected,
                          onChanged: (_) {
                            ref.read(selectedItemsProvider.notifier).toggle(item.id);
                          },
                        )
                      : null,
                  title: Text(item.name),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
```

## Dependencies
- Story 2.1 (Add Item - Quick Mode)
- Story 2.4 (Check/Uncheck Items)
- Story 2.5 (Delete Items)

## Estimated Effort
5 story points
