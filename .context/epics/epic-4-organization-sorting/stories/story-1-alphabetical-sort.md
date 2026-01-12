# Story 4.1: Alphabetical Sort

## Description
Items sorted A-Z by name.

## Acceptance Criteria
- [ ] Simple alphabetical sort
- [ ] Case-insensitive
- [ ] Flat list (no grouping)
- [ ] Toggle between A-Z and Z-A
- [ ] Sort preference saved per list

## Technical Implementation

### Flutter Implementation

```dart
enum SortMode { alphabetical, custom, chronological }

extension ItemListSorting on List<Item> {
  List<Item> sorted(SortMode mode, {bool ascending = true}) {
    final unchecked = where((i) => !i.isChecked).toList();
    final checked = where((i) => i.isChecked).toList();

    switch (mode) {
      case SortMode.alphabetical:
        unchecked.sort((a, b) => ascending
            ? a.name.toLowerCase().compareTo(b.name.toLowerCase())
            : b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case SortMode.custom:
        unchecked.sort((a, b) => a.sortIndex.compareTo(b.sortIndex));
        break;
      case SortMode.chronological:
        unchecked.sort((a, b) => ascending
            ? b.createdAt.compareTo(a.createdAt)  // newest first
            : a.createdAt.compareTo(b.createdAt));
        break;
    }

    // Checked items always at bottom, sorted by checked time
    checked.sort((a, b) => b.checkedAt!.compareTo(a.checkedAt!));

    return [...unchecked, ...checked];
  }
}
```

## Dependencies
- Story 2.1 (Add Item - Quick Mode)

## Estimated Effort
2 story points
