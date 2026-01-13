import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../domain/shopping_list.dart';
import 'list_api.dart';

class ListRepository {
  final ListApi _api;

  ListRepository(this._api);

  Future<List<ShoppingList>> getLists() async {
    return _api.getLists();
  }

  Future<ShoppingList> getList(String id) async {
    return _api.getList(id);
  }

  Future<ShoppingList> createList({
    required String name,
    String? color,
    String? icon,
  }) async {
    return _api.createList(name: name, color: color, icon: icon);
  }

  Future<ShoppingList> updateList(
    String id, {
    String? name,
    String? color,
    String? icon,
    bool? isArchived,
  }) async {
    return _api.updateList(
      id,
      name: name,
      color: color,
      icon: icon,
      isArchived: isArchived,
    );
  }

  Future<void> deleteList(String id) async {
    await _api.deleteList(id);
  }

  Future<ShoppingList> duplicateList(String id, {String? name}) async {
    return _api.duplicateList(id, name: name);
  }

  bool isNetworkError(Object error) {
    return error is NetworkException;
  }
}

final listRepositoryProvider = Provider<ListRepository>((ref) {
  final api = ref.watch(listApiProvider);
  return ListRepository(api);
});
