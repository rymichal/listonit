import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../domain/item.dart';
import 'item_api.dart';
import 'item_local_data_source.dart';

class ItemRepository {
  final ItemApi _api;
  final ItemLocalDataSource _localDataSource;

  ItemRepository(this._api, this._localDataSource);

  Future<List<Item>> getItems(String listId) async {
    try {
      final items = await _api.getItems(listId);
      // Cache to local storage
      await _localDataSource.saveItems(items);
      return items;
    } catch (e) {
      // On network error, return cached data
      if (isNetworkError(e)) {
        return _localDataSource.getItems(listId);
      }
      rethrow;
    }
  }

  Future<Item> createItem({
    required String listId,
    required String name,
    int quantity = 1,
    String? unit,
    String? note,
  }) async {
    final item = await _api.createItem(
      listId: listId,
      name: name,
      quantity: quantity,
      unit: unit,
      note: note,
    );
    // Cache to local storage
    await _localDataSource.saveItem(item);
    return item;
  }

  Future<List<Item>> createItemsBatch({
    required String listId,
    required List<String> names,
  }) async {
    final items = await _api.createItemsBatch(listId: listId, names: names);
    // Cache to local storage
    await _localDataSource.saveItems(items);
    return items;
  }

  Future<Item> updateItem({
    required String listId,
    required String itemId,
    String? name,
    int? quantity,
    String? unit,
    String? note,
    bool? isChecked,
    int? sortIndex,
  }) async {
    final item = await _api.updateItem(
      listId: listId,
      itemId: itemId,
      name: name,
      quantity: quantity,
      unit: unit,
      note: note,
      isChecked: isChecked,
      sortIndex: sortIndex,
    );
    // Cache to local storage
    await _localDataSource.saveItem(item);
    return item;
  }

  Future<Item> toggleItem({
    required String listId,
    required String itemId,
  }) async {
    final item = await _api.toggleItem(listId: listId, itemId: itemId);
    // Cache to local storage
    await _localDataSource.saveItem(item);
    return item;
  }

  Future<void> deleteItem({
    required String listId,
    required String itemId,
  }) async {
    await _api.deleteItem(listId: listId, itemId: itemId);
    // Remove from local storage
    await _localDataSource.deleteItem(itemId);
  }

  Future<void> clearCheckedItems(String listId) async {
    await _api.clearCheckedItems(listId);
  }

  Future<int> batchCheckItems({
    required String listId,
    required List<String> itemIds,
    required bool checked,
  }) async {
    return _api.batchCheckItems(
      listId: listId,
      itemIds: itemIds,
      checked: checked,
    );
  }

  Future<int> batchDeleteItems({
    required String listId,
    required List<String> itemIds,
  }) async {
    return _api.batchDeleteItems(listId: listId, itemIds: itemIds);
  }

  Future<int> reorderItems({
    required String listId,
    required List<Map<String, dynamic>> items,
  }) async {
    return _api.reorderItems(listId: listId, items: items);
  }

  bool isNetworkError(Object error) {
    return error is NetworkException;
  }
}

final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  final api = ref.watch(itemApiProvider);
  final localDataSource = ref.watch(itemLocalDataSourceProvider);
  return ItemRepository(api, localDataSource);
});
