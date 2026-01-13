import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/shopping_list.dart';

class ListApi {
  final ApiClient _client;

  ListApi(this._client);

  Future<List<ShoppingList>> getLists() async {
    return _client.get<List<ShoppingList>>(
      '/lists',
      fromJson: (data) => (data as List)
          .map((item) => ShoppingList.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ShoppingList> getList(String id) async {
    return _client.get<ShoppingList>(
      '/lists/$id',
      fromJson: (data) => ShoppingList.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ShoppingList> createList({
    required String name,
    String? color,
    String? icon,
  }) async {
    return _client.post<ShoppingList>(
      '/lists',
      data: {
        'name': name,
        if (color != null) 'color': color,
        if (icon != null) 'icon': icon,
      },
      fromJson: (data) => ShoppingList.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ShoppingList> updateList(
    String id, {
    String? name,
    String? color,
    String? icon,
    bool? isArchived,
  }) async {
    return _client.patch<ShoppingList>(
      '/lists/$id',
      data: {
        if (name != null) 'name': name,
        if (color != null) 'color': color,
        if (icon != null) 'icon': icon,
        if (isArchived != null) 'is_archived': isArchived,
      },
      fromJson: (data) => ShoppingList.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<void> deleteList(String id) async {
    await _client.delete('/lists/$id');
  }
}

final listApiProvider = Provider<ListApi>((ref) {
  final client = ref.watch(apiClientProvider);
  return ListApi(client);
});
