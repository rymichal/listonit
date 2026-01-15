import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/storage/hive_service.dart';
import '../domain/shopping_list.dart';

class ListLocalDataSource {
  const ListLocalDataSource();

  Box<Map> get _listsBox => HiveService.listsBox;

  /// Get all lists from local storage
  Future<List<ShoppingList>> getLists() async {
    try {
      final maps = _listsBox.values.cast<Map<String, dynamic>>().toList();
      return maps.map((json) => ShoppingList.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get a specific list by ID
  Future<ShoppingList?> getList(String id) async {
    try {
      final json = _listsBox.get(id) as Map<String, dynamic>?;
      if (json == null) return null;
      return ShoppingList.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  /// Save a single list to local storage
  Future<void> saveList(ShoppingList list) async {
    try {
      await _listsBox.put(list.id, list.toJson());
    } catch (e) {
      rethrow;
    }
  }

  /// Save multiple lists to local storage
  Future<void> saveLists(List<ShoppingList> lists) async {
    try {
      final map = {for (var list in lists) list.id: list.toJson()};
      await _listsBox.putAll(map);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a list from local storage
  Future<void> deleteList(String id) async {
    try {
      await _listsBox.delete(id);
    } catch (e) {
      rethrow;
    }
  }

  /// Clear all lists from local storage
  Future<void> clearAll() async {
    try {
      await _listsBox.clear();
    } catch (e) {
      rethrow;
    }
  }
}

final listLocalDataSourceProvider = Provider<ListLocalDataSource>(
  (ref) => const ListLocalDataSource(),
);
