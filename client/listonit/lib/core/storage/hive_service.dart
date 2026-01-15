import 'package:hive_flutter/hive_flutter.dart';
import 'hive_adapters.dart';
import 'sync_action.dart';

class HiveService {
  static const String listsBoxName = 'lists';
  static const String itemsBoxName = 'items';
  static const String syncQueueBoxName = 'sync_queue';

  static Future<void> initialize() async {
    await Hive.initFlutter();

    // Register adapters (safe to call multiple times)
    if (!Hive.isAdapterRegistered(ShoppingListAdapter().typeId)) {
      Hive.registerAdapter(ShoppingListAdapter());
    }
    if (!Hive.isAdapterRegistered(ItemAdapter().typeId)) {
      Hive.registerAdapter(ItemAdapter());
    }
    if (!Hive.isAdapterRegistered(SyncActionAdapter().typeId)) {
      Hive.registerAdapter(SyncActionAdapter());
    }

    // Open boxes (safe to call if already open)
    if (!Hive.isBoxOpen(listsBoxName)) {
      await Hive.openBox<Map>(listsBoxName);
    }
    if (!Hive.isBoxOpen(itemsBoxName)) {
      await Hive.openBox<Map>(itemsBoxName);
    }
    if (!Hive.isBoxOpen(syncQueueBoxName)) {
      await Hive.openBox<SyncAction>(syncQueueBoxName);
    }
  }

  static Box<Map> get listsBox => Hive.box<Map>(listsBoxName);
  static Box<Map> get itemsBox => Hive.box<Map>(itemsBoxName);
  static Box<SyncAction> get syncQueueBox => Hive.box<SyncAction>(syncQueueBoxName);

  static Future<void> clearAll() async {
    await listsBox.clear();
    await itemsBox.clear();
    await syncQueueBox.clear();
  }
}
