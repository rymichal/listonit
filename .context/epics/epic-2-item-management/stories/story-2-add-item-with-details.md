# Story 2.2: Add Item with Details

## Description
Users can add items with quantity, unit, and notes.

## Acceptance Criteria
- [ ] "Expand" icon on quick add reveals full form
- [ ] Fields: Name, Quantity + Unit, Note
- [ ] Quantity has +/- steppers and direct input
- [ ] Unit dropdown with common options
- [ ] Note is multiline text (max 500 chars)
- [ ] "Add" button (or keyboard "Done")

## Technical Implementation

### Flutter Widget

```dart
class ItemDetailForm extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Name field
        TextField(
          decoration: InputDecoration(labelText: 'Item name'),
          onChanged: (v) => ref.read(itemFormProvider.notifier).setName(v),
        ),

        // Quantity row
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.remove),
              onPressed: () => ref.read(itemFormProvider.notifier).decrementQty(),
            ),
            SizedBox(
              width: 60,
              child: TextField(
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                controller: _qtyController,
              ),
            ),
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () => ref.read(itemFormProvider.notifier).incrementQty(),
            ),

            // Unit dropdown
            DropdownButton<String>(
              value: ref.watch(itemFormProvider).unit,
              items: ['pcs', 'kg', 'lb', 'oz', 'L', 'gal', 'dozen', 'pack']
                  .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                  .toList(),
              onChanged: (v) => ref.read(itemFormProvider.notifier).setUnit(v),
            ),
          ],
        ),

        // Note field
        TextField(
          decoration: InputDecoration(labelText: 'Note (optional)'),
          maxLines: 2,
          maxLength: 500,
          onChanged: (v) => ref.read(itemFormProvider.notifier).setNote(v),
        ),
      ],
    );
  }
}
```

## Dependencies
- Story 2.1 (Add Item - Quick Mode)

## Estimated Effort
4 story points
