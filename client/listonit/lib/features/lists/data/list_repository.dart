import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../domain/shopping_list.dart';
import 'list_api.dart';
import 'list_local_data_source.dart';

class ListRepository {
  final ListApi _api;
  final ListLocalDataSource _localDataSource;

  ListRepository(this._api, this._localDataSource);

  Future<List<ShoppingList>> getLists() async {
    try {
      final lists = await _api.getLists();
      // Cache to local storage
      await _localDataSource.saveLists(lists);
      return lists;
    } catch (e) {
      // On network error, return cached data
      if (isNetworkError(e)) {
        return _localDataSource.getLists();
      }
      rethrow;
    }
  }

  Future<ShoppingList> getList(String id) async {
    try {
      final list = await _api.getList(id);
      // Cache to local storage
      await _localDataSource.saveList(list);
      return list;
    } catch (e) {
      // On network error, return cached data
      if (isNetworkError(e)) {
        final cachedList = await _localDataSource.getList(id);
        if (cachedList != null) return cachedList;
      }
      rethrow;
    }
  }

  Future<ShoppingList> createList({
    required String name,
    String? color,
    String? icon,
  }) async {
    final createdList = await _api.createList(name: name, color: color, icon: icon);
    // Cache to local storage
    await _localDataSource.saveList(createdList);
    return createdList;
  }

  Future<ShoppingList> updateList(
    String id, {
    String? name,
    String? color,
    String? icon,
    bool? isArchived,
    String? sortMode,
  }) async {
    final updatedList = await _api.updateList(
      id,
      name: name,
      color: color,
      icon: icon,
      isArchived: isArchived,
      sortMode: sortMode,
    );
    // Cache to local storage
    await _localDataSource.saveList(updatedList);
    return updatedList;
  }

  Future<void> deleteList(String id) async {
    await _api.deleteList(id);
    // Remove from local storage
    await _localDataSource.deleteList(id);
  }

  Future<ShoppingList> duplicateList(String id, {String? name}) async {
    final duplicatedList = await _api.duplicateList(id, name: name);
    // Cache to local storage
    await _localDataSource.saveList(duplicatedList);
    return duplicatedList;
  }

  bool isNetworkError(Object error) {
    return error is NetworkException;
  }
}

final listRepositoryProvider = Provider<ListRepository>((ref) {
  final api = ref.watch(listApiProvider);
  final localDataSource = ref.watch(listLocalDataSourceProvider);
  return ListRepository(api, localDataSource);
});
