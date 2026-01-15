import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/storage/hive_service.dart';
import '../domain/item.dart';

class ItemLocalDataSource {
  const ItemLocalDataSource();

  Box<Map> get _itemsBox => HiveService.itemsBox;

  /// Get all items for a specific list
  Future<List<Item>> getItems(String listId) async {
    try {
      final maps = _itemsBox.values.cast<Map<String, dynamic>>().toList();
      final items = maps.map((json) => Item.fromJson(json)).toList();
      return items.where((item) => item.listId == listId).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get a specific item by ID
  Future<Item?> getItem(String id) async {
    try {
      final json = _itemsBox.get(id) as Map<String, dynamic>?;
      if (json == null) return null;
      return Item.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  /// Save a single item to local storage
  Future<void> saveItem(Item item) async {
    try {
      await _itemsBox.put(item.id, item.toJson());
    } catch (e) {
      rethrow;
    }
  }

  /// Save multiple items to local storage
  Future<void> saveItems(List<Item> items) async {
    try {
      final map = {for (var item in items) item.id: item.toJson()};
      await _itemsBox.putAll(map);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete an item from local storage
  Future<void> deleteItem(String id) async {
    try {
      await _itemsBox.delete(id);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete all items for a specific list
  Future<void> deleteItemsByListId(String listId) async {
    try {
      final idsToDelete = <String>[];
      final maps = _itemsBox.values.cast<Map<String, dynamic>>().toList();
      for (var json in maps) {
        final item = Item.fromJson(json);
        if (item.listId == listId) {
          idsToDelete.add(item.id);
        }
      }
      await Future.wait([
        for (var id in idsToDelete) _itemsBox.delete(id),
      ]);
    } catch (e) {
      rethrow;
    }
  }

  /// Clear all items from local storage
  Future<void> clearAll() async {
    try {
      await _itemsBox.clear();
    } catch (e) {
      rethrow;
    }
  }
}

final itemLocalDataSourceProvider = Provider<ItemLocalDataSource>(
  (ref) => const ItemLocalDataSource(),
);
