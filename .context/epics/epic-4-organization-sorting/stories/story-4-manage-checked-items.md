# Story 4.4: Manage Checked Items

## Description
Control visibility and clearing of checked items.

## Acceptance Criteria
- [ ] Toggle: "Show checked items" (default on)
- [ ] When hidden, show "X checked items" collapsed section
- [ ] Tap collapsed section to expand
- [ ] "Clear checked items" bulk action in list menu
- [ ] Confirmation dialog for bulk clear
- [ ] Undo snackbar after clear

## Technical Implementation

### Flutter Implementation

```dart
class CheckedItemsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showChecked = ref.watch(showCheckedItemsProvider);
    final checkedItems = ref.watch(checkedItemsProvider);

    if (checkedItems.isEmpty) return SizedBox.shrink();

    if (!showChecked) {
      return ListTile(
        leading: Icon(Icons.check_circle_outline),
        title: Text('${checkedItems.length} checked items'),
        trailing: Icon(Icons.expand_more),
        onTap: () => ref.read(showCheckedItemsProvider.notifier).toggle(),
      );
    }

    return Column(
      children: [
        Divider(),
        ListTile(
          title: Text('Checked', style: TextStyle(fontWeight: FontWeight.bold)),
          trailing: TextButton(
            onPressed: () => _confirmClearChecked(context, ref),
            child: Text('Clear all'),
          ),
        ),
        ...checkedItems.map((item) => CheckedItemTile(item: item)),
      ],
    );
  }

  void _confirmClearChecked(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear checked items?'),
        content: Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(itemsProvider.notifier).clearCheckedItems();
              Navigator.pop(context);
            },
            child: Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
```

### FastAPI Endpoint

```python
@router.delete("/lists/{list_id}/items/checked")
async def clear_checked_items(
    list_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if not has_list_access(db, current_user.id, list_id):
        raise HTTPException(403, "Access denied")

    deleted_count = db.query(Item).filter(
        Item.list_id == list_id,
        Item.is_checked == True
    ).delete()

    db.commit()

    # Broadcast
    await broadcast_list_update(list_id, {
        "type": "checked_items_cleared",
        "count": deleted_count
    })

    return {"deleted_count": deleted_count}
```

## Dependencies
- Story 2.4 (Check/Uncheck Items)

## Estimated Effort
3 story points
