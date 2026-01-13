import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/network/api_exception.dart';
import '../data/item_repository.dart';
import '../domain/item.dart';

class ItemsState {
  final String listId;
  final List<Item> items;
  final bool isLoading;
  final String? error;

  const ItemsState({
    required this.listId,
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  List<Item> get uncheckedItems => items.where((i) => !i.isChecked).toList();
  List<Item> get checkedItems => items.where((i) => i.isChecked).toList();

  ItemsState copyWith({
    String? listId,
    List<Item>? items,
    bool? isLoading,
    String? error,
  }) {
    return ItemsState(
      listId: listId ?? this.listId,
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ItemsNotifier extends StateNotifier<ItemsState> {
  final ItemRepository _repository;
  final Uuid _uuid = const Uuid();

  ItemsNotifier(this._repository, String listId)
      : super(ItemsState(listId: listId));

  Future<void> loadItems() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final items = await _repository.getItems(state.listId);
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e is ApiException ? e.message : 'Failed to load items',
      );
    }
  }

  Future<bool> addItem({
    required String name,
    int quantity = 1,
    String? unit,
    String? note,
  }) async {
    final tempId = _uuid.v4();
    final now = DateTime.now();

    final optimisticItem = Item(
      id: tempId,
      listId: state.listId,
      name: name,
      quantity: quantity,
      unit: unit,
      note: note,
      createdBy: '',
      createdAt: now,
      updatedAt: now,
      isLocal: true,
    );

    // Optimistic update - add to end of unchecked items
    state = state.copyWith(
      items: [...state.items, optimisticItem],
      error: null,
    );

    try {
      final createdItem = await _repository.createItem(
        listId: state.listId,
        name: name,
        quantity: quantity,
        unit: unit,
        note: note,
      );

      // Replace temp item with real one
      state = state.copyWith(
        items: state.items.map((i) => i.id == tempId ? createdItem : i).toList(),
      );

      return true;
    } catch (e) {
      if (_repository.isNetworkError(e)) {
        // Keep optimistic item for offline sync later
        state = state.copyWith(
          error: 'Saved locally. Will sync when online.',
        );
        return true;
      } else {
        // Rollback on other errors
        state = state.copyWith(
          items: state.items.where((i) => i.id != tempId).toList(),
          error: e is ApiException ? e.message : 'Failed to add item',
        );
        return false;
      }
    }
  }

  Future<bool> addItemsBatch(String input) async {
    if (input.trim().isEmpty) return false;

    // Split by commas for batch add
    final names = input
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (names.isEmpty) return false;

    // If single item, use regular add
    if (names.length == 1) {
      return addItem(name: names.first);
    }

    final now = DateTime.now();
    final tempIds = <String>[];
    final optimisticItems = <Item>[];

    // Create optimistic items
    for (final name in names) {
      final tempId = _uuid.v4();
      tempIds.add(tempId);
      optimisticItems.add(Item(
        id: tempId,
        listId: state.listId,
        name: name,
        quantity: 1,
        createdBy: '',
        createdAt: now,
        updatedAt: now,
        isLocal: true,
      ));
    }

    // Optimistic update
    state = state.copyWith(
      items: [...state.items, ...optimisticItems],
      error: null,
    );

    try {
      final createdItems = await _repository.createItemsBatch(
        listId: state.listId,
        names: names,
      );

      // Replace temp items with real ones
      final updatedItems = state.items.where((i) => !tempIds.contains(i.id)).toList();
      state = state.copyWith(
        items: [...updatedItems, ...createdItems],
      );

      return true;
    } catch (e) {
      if (_repository.isNetworkError(e)) {
        state = state.copyWith(
          error: 'Saved locally. Will sync when online.',
        );
        return true;
      } else {
        // Rollback
        state = state.copyWith(
          items: state.items.where((i) => !tempIds.contains(i.id)).toList(),
          error: e is ApiException ? e.message : 'Failed to add items',
        );
        return false;
      }
    }
  }

  Future<bool> toggleItem(String itemId) async {
    final itemIndex = state.items.indexWhere((i) => i.id == itemId);
    if (itemIndex == -1) return false;

    final oldItem = state.items[itemIndex];

    // Optimistic update
    final updatedItem = oldItem.copyWith(
      isChecked: !oldItem.isChecked,
      updatedAt: DateTime.now(),
    );

    final optimisticItems = state.items.toList();
    optimisticItems[itemIndex] = updatedItem;
    state = state.copyWith(items: optimisticItems, error: null);

    try {
      final toggledItem = await _repository.toggleItem(
        listId: state.listId,
        itemId: itemId,
      );

      state = state.copyWith(
        items: state.items.map((i) => i.id == itemId ? toggledItem : i).toList(),
      );

      return true;
    } catch (e) {
      // Rollback
      state = state.copyWith(
        items: state.items.map((i) => i.id == itemId ? oldItem : i).toList(),
        error: e is ApiException ? e.message : 'Failed to toggle item',
      );
      return false;
    }
  }

  Future<bool> deleteItem(String itemId) async {
    final itemIndex = state.items.indexWhere((i) => i.id == itemId);
    if (itemIndex == -1) return false;

    final deletedItem = state.items[itemIndex];

    // Optimistic removal
    state = state.copyWith(
      items: state.items.where((i) => i.id != itemId).toList(),
      error: null,
    );

    try {
      await _repository.deleteItem(
        listId: state.listId,
        itemId: itemId,
      );
      return true;
    } catch (e) {
      // Rollback
      state = state.copyWith(
        items: [...state.items.sublist(0, itemIndex), deletedItem, ...state.items.sublist(itemIndex)],
        error: e is ApiException ? e.message : 'Failed to delete item',
      );
      return false;
    }
  }

  Future<bool> clearCheckedItems() async {
    final checkedItems = state.checkedItems;
    if (checkedItems.isEmpty) return true;

    // Optimistic removal
    state = state.copyWith(
      items: state.uncheckedItems,
      error: null,
    );

    try {
      await _repository.clearCheckedItems(state.listId);
      return true;
    } catch (e) {
      // Rollback
      state = state.copyWith(
        items: [...state.items, ...checkedItems],
        error: e is ApiException ? e.message : 'Failed to clear items',
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final itemsProvider =
    StateNotifierProvider.family<ItemsNotifier, ItemsState, String>(
  (ref, listId) {
    final repository = ref.watch(itemRepositoryProvider);
    return ItemsNotifier(repository, listId);
  },
);
