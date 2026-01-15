import 'item.dart';
import 'sort_mode.dart';

extension ItemListSorting on List<Item> {
  /// Sort items by the given mode, keeping checked items at the bottom.
  ///
  /// - Unchecked items are sorted according to [mode] with [ascending] direction
  /// - Checked items always appear at the bottom, sorted by checked time (newest first)
  /// - Case-insensitive for alphabetical sorting
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
            ? b.createdAt.compareTo(a.createdAt) // newest first
            : a.createdAt.compareTo(b.createdAt));
        break;
    }

    // Checked items always at bottom, sorted by checked time (newest first)
    checked.sort((a, b) => b.checkedAt!.compareTo(a.checkedAt!));

    return [...unchecked, ...checked];
  }
}
