# Story 4.3: Chronological Sort

## Description
Items sorted by when they were added.

## Acceptance Criteria
- [ ] Default sort mode for new lists
- [ ] Most recently added at top
- [ ] Option to reverse (oldest first)
- [ ] Respects created_at timestamp

## Technical Implementation

See Story 4.1 for sorting extension implementation. Chronological sort is implemented in the `ItemListSorting` extension:

```dart
case SortMode.chronological:
  unchecked.sort((a, b) => ascending
      ? b.createdAt.compareTo(a.createdAt)  // newest first
      : a.createdAt.compareTo(b.createdAt));
  break;
```

## Dependencies
- Story 2.1 (Add Item - Quick Mode)

## Estimated Effort
1 story point
