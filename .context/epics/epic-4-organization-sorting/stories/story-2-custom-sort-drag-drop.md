# Story 4.2: Custom Sort (Drag & Drop)

## Description
Users can manually reorder items.

## Acceptance Criteria
- [ ] Long-press and drag to reorder
- [ ] Drag handle icon for accessibility
- [ ] Visual feedback during drag (elevation, opacity)
- [ ] Order persists across sessions
- [ ] Reset to default (chronological) option
- [ ] Only affects unchecked items

## Technical Implementation

### Flutter Implementation

```dart
class ReorderableItemList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(itemsProvider);

    return ReorderableListView.builder(
      itemCount: items.length,
      onReorder: (oldIndex, newIndex) {
        ref.read(itemsProvider.notifier).reorder(oldIndex, newIndex);
      },
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          key: ValueKey(item.id),
          leading: ReorderableDragStartListener(
            index: index,
            child: Icon(Icons.drag_handle),
          ),
          title: Text(item.name),
          // ... rest of item UI
        );
      },
    );
  }
}
```

### FastAPI Endpoint

```python
@router.post("/lists/{list_id}/items/reorder")
async def reorder_items(
    list_id: UUID,
    item_order: List[UUID],
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if not has_list_access(db, current_user.id, list_id):
        raise HTTPException(403, "Access denied")

    # Update sort_index for each item
    for index, item_id in enumerate(item_order):
        db.query(Item).filter(
            Item.id == item_id,
            Item.list_id == list_id
        ).update({"sort_index": index})

    db.commit()

    # Broadcast reorder event
    await broadcast_list_update(list_id, {
        "type": "items_reordered",
        "order": [str(id) for id in item_order]
    })

    return {"success": True}
```

## Dependencies
- Story 2.1 (Add Item - Quick Mode)

## Estimated Effort
4 story points
