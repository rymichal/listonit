import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../domain/item.dart';
import 'item_api.dart';

class ItemRepository {
  final ItemApi _api;

  ItemRepository(this._api);

  Future<List<Item>> getItems(String listId) async {
    return _api.getItems(listId);
  }

  Future<Item> createItem({
    required String listId,
    required String name,
    int quantity = 1,
    String? unit,
    String? note,
  }) async {
    return _api.createItem(
      listId: listId,
      name: name,
      quantity: quantity,
      unit: unit,
      note: note,
    );
  }

  Future<List<Item>> createItemsBatch({
    required String listId,
    required List<String> names,
  }) async {
    return _api.createItemsBatch(listId: listId, names: names);
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
    return _api.updateItem(
      listId: listId,
      itemId: itemId,
      name: name,
      quantity: quantity,
      unit: unit,
      note: note,
      isChecked: isChecked,
      sortIndex: sortIndex,
    );
  }

  Future<Item> toggleItem({
    required String listId,
    required String itemId,
  }) async {
    return _api.toggleItem(listId: listId, itemId: itemId);
  }

  Future<void> deleteItem({
    required String listId,
    required String itemId,
  }) async {
    await _api.deleteItem(listId: listId, itemId: itemId);
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

  bool isNetworkError(Object error) {
    return error is NetworkException;
  }
}

final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  final api = ref.watch(itemApiProvider);
  return ItemRepository(api);
});
