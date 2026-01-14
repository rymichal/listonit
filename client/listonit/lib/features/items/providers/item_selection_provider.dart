import 'package:flutter_riverpod/flutter_riverpod.dart';

class ItemSelectionState {
  final String? listId;
  final Set<String> selectedIds;
  final bool isSelectionMode;

  const ItemSelectionState({
    this.listId,
    this.selectedIds = const {},
    this.isSelectionMode = false,
  });

  ItemSelectionState copyWith({
    String? listId,
    Set<String>? selectedIds,
    bool? isSelectionMode,
  }) {
    return ItemSelectionState(
      listId: listId ?? this.listId,
      selectedIds: selectedIds ?? this.selectedIds,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
    );
  }

  int get selectedCount => selectedIds.length;

  bool isSelected(String itemId) => selectedIds.contains(itemId);
}

class ItemSelectionNotifier extends StateNotifier<ItemSelectionState> {
  ItemSelectionNotifier() : super(const ItemSelectionState());

  void enterSelectionMode(String listId, String initialItemId) {
    state = ItemSelectionState(
      listId: listId,
      selectedIds: {initialItemId},
      isSelectionMode: true,
    );
  }

  void exitSelectionMode() {
    state = const ItemSelectionState();
  }

  void toggleItem(String itemId) {
    if (!state.isSelectionMode) return;

    final newSelectedIds = Set<String>.from(state.selectedIds);
    if (newSelectedIds.contains(itemId)) {
      newSelectedIds.remove(itemId);
    } else {
      newSelectedIds.add(itemId);
    }

    // Exit selection mode if no items selected
    if (newSelectedIds.isEmpty) {
      exitSelectionMode();
    } else {
      state = state.copyWith(selectedIds: newSelectedIds);
    }
  }

  void selectAll(List<String> itemIds) {
    if (!state.isSelectionMode) return;
    state = state.copyWith(selectedIds: Set<String>.from(itemIds));
  }

  void deselectAll() {
    exitSelectionMode();
  }
}

final itemSelectionProvider =
    StateNotifierProvider<ItemSelectionNotifier, ItemSelectionState>(
  (ref) => ItemSelectionNotifier(),
);
