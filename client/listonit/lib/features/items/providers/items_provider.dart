import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/storage/sync_action.dart';
import '../../../core/sync/sync_queue_service.dart';
import '../data/item_local_data_source.dart';
import '../data/item_repository.dart';
import '../domain/item.dart';
import '../domain/sort_mode.dart';
import '../domain/item_sorting.dart';

class ItemsState {
  final String listId;
  final List<Item> items;
  final bool isLoading;
  final String? error;
  final SortMode sortMode;
  final bool sortAscending;

  const ItemsState({
    required this.listId,
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.sortMode = SortMode.chronological,
    this.sortAscending = true,
  });

  List<Item> get uncheckedItems => items.where((i) => !i.isChecked).toList();
  List<Item> get checkedItems => items.where((i) => i.isChecked).toList();

  /// Get items sorted by the current sort mode
  List<Item> getSortedItems() => items.sorted(sortMode, ascending: sortAscending);

  ItemsState copyWith({
    String? listId,
    List<Item>? items,
    bool? isLoading,
    String? error,
    SortMode? sortMode,
    bool? sortAscending,
  }) {
    return ItemsState(
      listId: listId ?? this.listId,
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      sortMode: sortMode ?? this.sortMode,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }
}

class ItemsNotifier extends StateNotifier<ItemsState> {
  final ItemRepository _repository;
  final SyncQueueService _syncQueueService;
  final Uuid _uuid = const Uuid();

  // For undo functionality
  Item? _lastDeletedItem;
  int? _lastDeletedIndex;

  ItemsNotifier(this._repository, this._syncQueueService, String listId)
      : super(ItemsState(listId: listId));

  Future<void> loadItems() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Load from cache first (instant load)
      final localDataSource = ItemLocalDataSource();
      final cachedItems = await localDataSource.getItems(state.listId);
      if (cachedItems.isNotEmpty) {
        state = state.copyWith(items: cachedItems);
      }

      // Then fetch from server
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
        // Queue for sync
        await _syncQueueService.enqueue(
          SyncActionType.create,
          SyncEntityType.item,
          tempId,
          {
            'list_id': state.listId,
            'name': name,
            'quantity': quantity,
            'unit': unit,
            'note': note,
          },
        );

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

    // Store for undo
    _lastDeletedItem = deletedItem;
    _lastDeletedIndex = itemIndex;

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
      _lastDeletedItem = null;
      _lastDeletedIndex = null;
      state = state.copyWith(
        items: [...state.items.sublist(0, itemIndex), deletedItem, ...state.items.sublist(itemIndex)],
        error: e is ApiException ? e.message : 'Failed to delete item',
      );
      return false;
    }
  }

  /// Get the last deleted item for undo snackbar
  Item? get lastDeletedItem => _lastDeletedItem;

  /// Restore the last deleted item (undo)
  Future<bool> undoDeleteItem() async {
    final item = _lastDeletedItem;
    if (item == null) return false;

    // Clear undo state
    _lastDeletedItem = null;
    _lastDeletedIndex = null;

    // Re-add the item
    return addItem(
      name: item.name,
      quantity: item.quantity,
      unit: item.unit,
      note: item.note,
    );
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

  Future<bool> updateItem({
    required String itemId,
    String? name,
    int? quantity,
    String? unit,
    String? note,
    bool? isChecked,
  }) async {
    final itemIndex = state.items.indexWhere((i) => i.id == itemId);
    if (itemIndex == -1) return false;

    final oldItem = state.items[itemIndex];

    // Optimistic update
    final updatedItem = oldItem.copyWith(
      name: name ?? oldItem.name,
      quantity: quantity ?? oldItem.quantity,
      unit: unit,
      note: note,
      isChecked: isChecked ?? oldItem.isChecked,
      updatedAt: DateTime.now(),
    );

    final optimisticItems = state.items.toList();
    optimisticItems[itemIndex] = updatedItem;
    state = state.copyWith(items: optimisticItems, error: null);

    try {
      final serverItem = await _repository.updateItem(
        listId: state.listId,
        itemId: itemId,
        name: name,
        quantity: quantity,
        unit: unit,
        note: note,
        isChecked: isChecked,
      );

      state = state.copyWith(
        items: state.items.map((i) => i.id == itemId ? serverItem : i).toList(),
      );

      return true;
    } catch (e) {
      if (_repository.isNetworkError(e)) {
        // Keep optimistic update for offline
        state = state.copyWith(
          error: 'Saved locally. Will sync when online.',
        );
        return true;
      } else {
        // Rollback
        state = state.copyWith(
          items: state.items.map((i) => i.id == itemId ? oldItem : i).toList(),
          error: e is ApiException ? e.message : 'Failed to update item',
        );
        return false;
      }
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Batch check/uncheck multiple items
  Future<bool> batchCheckItems(List<String> itemIds, bool checked) async {
    if (itemIds.isEmpty) return true;

    // Store old states for rollback
    final oldItems = Map.fromEntries(
      state.items.where((i) => itemIds.contains(i.id)).map((i) => MapEntry(i.id, i)),
    );

    // Optimistic update
    final now = DateTime.now();
    state = state.copyWith(
      items: state.items.map((i) {
        if (itemIds.contains(i.id)) {
          return i.copyWith(
            isChecked: checked,
            updatedAt: now,
          );
        }
        return i;
      }).toList(),
      error: null,
    );

    try {
      await _repository.batchCheckItems(
        listId: state.listId,
        itemIds: itemIds,
        checked: checked,
      );
      return true;
    } catch (e) {
      // Rollback
      state = state.copyWith(
        items: state.items.map((i) {
          if (oldItems.containsKey(i.id)) {
            return oldItems[i.id]!;
          }
          return i;
        }).toList(),
        error: e is ApiException ? e.message : 'Failed to update items',
      );
      return false;
    }
  }

  /// Batch delete multiple items
  Future<bool> batchDeleteItems(List<String> itemIds) async {
    if (itemIds.isEmpty) return true;

    // Store for potential undo (though batch undo is complex)
    final deletedItems = state.items.where((i) => itemIds.contains(i.id)).toList();

    // Optimistic removal
    state = state.copyWith(
      items: state.items.where((i) => !itemIds.contains(i.id)).toList(),
      error: null,
    );

    try {
      await _repository.batchDeleteItems(
        listId: state.listId,
        itemIds: itemIds,
      );
      return true;
    } catch (e) {
      // Rollback
      state = state.copyWith(
        items: [...state.items, ...deletedItems],
        error: e is ApiException ? e.message : 'Failed to delete items',
      );
      return false;
    }
  }

  /// Reorder items by updating their sort indices
  Future<bool> reorderItems(int oldIndex, int newIndex) async {
    // Get only unchecked items (only these can be reordered)
    final uncheckedItems = state.items.where((i) => !i.isChecked).toList();

    if (oldIndex < 0 || oldIndex >= uncheckedItems.length) return false;
    if (newIndex < 0 || newIndex > uncheckedItems.length) return false;

    // Adjust newIndex if moving down (ReorderableListView behavior)
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    if (oldIndex == newIndex) return true;

    // Store old state for rollback
    final oldItemsList = state.items.toList();

    // Reorder locally (optimistic update)
    final item = uncheckedItems.removeAt(oldIndex);
    uncheckedItems.insert(newIndex, item);

    // Update sort_index for all affected items
    for (int i = 0; i < uncheckedItems.length; i++) {
      uncheckedItems[i] = uncheckedItems[i].copyWith(sortIndex: i);
    }

    // Merge back with checked items (they stay at bottom)
    final checkedItems = state.items.where((i) => i.isChecked).toList();
    state = state.copyWith(items: [...uncheckedItems, ...checkedItems], error: null);

    // Sync with backend
    try {
      await _repository.reorderItems(
        listId: state.listId,
        items: uncheckedItems
            .map((i) => {'item_id': i.id, 'sort_index': i.sortIndex})
            .toList(),
      );
      return true;
    } catch (e) {
      // Rollback on error
      state = state.copyWith(
        items: oldItemsList,
        error: e is ApiException ? e.message : 'Failed to reorder items',
      );
      return false;
    }
  }

  /// Apply reorder changes received from WebSocket (other users' changes)
  void applyReorderFromServer(List<Map<String, dynamic>> reorderedData) {
    final updatedItems = state.items.map((item) {
      final reorderEntry = reorderedData.firstWhere(
        (e) => e['id'] == item.id,
        orElse: () => {},
      );

      if (reorderEntry.isNotEmpty) {
        return item.copyWith(sortIndex: reorderEntry['sort_index'] as int);
      }
      return item;
    }).toList();

    state = state.copyWith(items: updatedItems);
  }

  /// Update the sort mode for this list
  void setSortMode(SortMode mode) {
    state = state.copyWith(sortMode: mode);
  }

  /// Update the sort direction (ascending/descending)
  void setSortAscending(bool ascending) {
    state = state.copyWith(sortAscending: ascending);
  }

  /// Initialize sort mode from list
  void initializeSortMode(String sortModeString, bool ascending) {
    final sortMode = SortMode.fromString(sortModeString);
    state = state.copyWith(sortMode: sortMode, sortAscending: ascending);
  }
}

final itemsProvider =
    StateNotifierProvider.family<ItemsNotifier, ItemsState, String>(
  (ref, listId) {
    final repository = ref.watch(itemRepositoryProvider);
    final syncQueueService = ref.watch(syncQueueServiceProvider);
    return ItemsNotifier(repository, syncQueueService, listId);
  },
);
