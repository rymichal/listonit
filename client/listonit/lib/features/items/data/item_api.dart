import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/item.dart';

class ItemApi {
  final ApiClient _client;

  ItemApi(this._client);

  Future<List<Item>> getItems(String listId) async {
    return _client.get<List<Item>>(
      '/lists/$listId/items',
      fromJson: (data) => (data as List)
          .map((item) => Item.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<Item> createItem({
    required String listId,
    required String name,
    int quantity = 1,
    String? unit,
    String? note,
  }) async {
    return _client.post<Item>(
      '/lists/$listId/items',
      data: {
        'name': name,
        'quantity': quantity,
        if (unit != null) 'unit': unit,
        if (note != null) 'note': note,
      },
      fromJson: (data) => Item.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<List<Item>> createItemsBatch({
    required String listId,
    required List<String> names,
  }) async {
    return _client.post<List<Item>>(
      '/lists/$listId/items/batch',
      data: {'names': names},
      fromJson: (data) => (data as List)
          .map((item) => Item.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
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
    return _client.patch<Item>(
      '/lists/$listId/items/$itemId',
      data: {
        if (name != null) 'name': name,
        if (quantity != null) 'quantity': quantity,
        if (unit != null) 'unit': unit,
        if (note != null) 'note': note,
        if (isChecked != null) 'is_checked': isChecked,
        if (sortIndex != null) 'sort_index': sortIndex,
      },
      fromJson: (data) => Item.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<Item> toggleItem({
    required String listId,
    required String itemId,
  }) async {
    return _client.post<Item>(
      '/lists/$listId/items/$itemId/toggle',
      data: {},
      fromJson: (data) => Item.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<void> deleteItem({
    required String listId,
    required String itemId,
  }) async {
    await _client.delete('/lists/$listId/items/$itemId');
  }

  Future<void> clearCheckedItems(String listId) async {
    await _client.delete('/lists/$listId/items');
  }

  Future<int> batchCheckItems({
    required String listId,
    required List<String> itemIds,
    required bool checked,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/lists/$listId/items/batch-check',
      data: {
        'item_ids': itemIds,
        'checked': checked,
      },
      fromJson: (data) => data as Map<String, dynamic>,
    );
    return response['count'] as int;
  }

  Future<int> batchDeleteItems({
    required String listId,
    required List<String> itemIds,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/lists/$listId/items/batch-delete',
      data: {'item_ids': itemIds},
      fromJson: (data) => data as Map<String, dynamic>,
    );
    return response['count'] as int;
  }

  Future<int> reorderItems({
    required String listId,
    required List<Map<String, dynamic>> items,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/lists/$listId/items/reorder',
      data: {'items': items},
      fromJson: (data) => data as Map<String, dynamic>,
    );
    return response['count'] as int;
  }
}

final itemApiProvider = Provider<ItemApi>((ref) {
  final client = ref.watch(apiClientProvider);
  return ItemApi(client);
});
