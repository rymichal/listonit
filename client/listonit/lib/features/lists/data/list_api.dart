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
    String? sortMode,
  }) async {
    return _client.patch<ShoppingList>(
      '/lists/$id',
      data: {
        if (name != null) 'name': name,
        if (color != null) 'color': color,
        if (icon != null) 'icon': icon,
        if (isArchived != null) 'is_archived': isArchived,
        if (sortMode != null) 'sort_mode': sortMode,
      },
      fromJson: (data) => ShoppingList.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<void> deleteList(String id) async {
    await _client.delete('/lists/$id');
  }

  Future<ShoppingList> duplicateList(String id, {String? name}) async {
    return _client.post<ShoppingList>(
      '/lists/$id/duplicate',
      data: {
        if (name != null) 'name': name,
      },
      fromJson: (data) => ShoppingList.fromJson(data as Map<String, dynamic>),
    );
  }

Future<List<Map<String, dynamic>>> getListMembers(String listId) async {
    return _client.get<List<Map<String, dynamic>>>(
      '/lists/$listId/members',
      fromJson: (data) => (data as List)
          .map((item) => item as Map<String, dynamic>)
          .toList(),
    );
  }

  Future<Map<String, dynamic>> updateMemberRole(
    String listId,
    String memberId,
    String role,
  ) async {
    return _client.patch<Map<String, dynamic>>(
      '/lists/$listId/members/$memberId',
      data: {'role': role},
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  Future<void> removeMember(String listId, String memberId) async {
    await _client.delete('/lists/$listId/members/$memberId');
  }

  Future<Map<String, dynamic>> addMember(
    String listId,
    String userId,
    String role,
  ) async {
    return _client.post<Map<String, dynamic>>(
      '/lists/$listId/members',
      data: {
        'user_id': userId,
        'role': role,
      },
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }
}

final listApiProvider = Provider<ListApi>((ref) {
  final client = ref.watch(apiClientProvider);
  return ListApi(client);
});
