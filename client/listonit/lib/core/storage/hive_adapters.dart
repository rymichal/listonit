import 'package:hive/hive.dart';
import '../../features/lists/domain/shopping_list.dart';
import '../../features/items/domain/item.dart';
import 'sync_action.dart';

// TypeAdapter for ShoppingList
class ShoppingListAdapter extends TypeAdapter<ShoppingList> {
  @override
  final int typeId = 0;

  @override
  ShoppingList read(BinaryReader reader) {
    return ShoppingList.fromJson(reader.readMap().cast<String, dynamic>());
  }

  @override
  void write(BinaryWriter writer, ShoppingList obj) {
    writer.writeMap(obj.toJson());
  }
}

// TypeAdapter for Item
class ItemAdapter extends TypeAdapter<Item> {
  @override
  final int typeId = 1;

  @override
  Item read(BinaryReader reader) {
    return Item.fromJson(reader.readMap().cast<String, dynamic>());
  }

  @override
  void write(BinaryWriter writer, Item obj) {
    writer.writeMap(obj.toJson());
  }
}

// TypeAdapter for SyncAction
class SyncActionAdapter extends TypeAdapter<SyncAction> {
  @override
  final int typeId = 2;

  @override
  SyncAction read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numFields; i++) reader.readByte(): reader.read(),
    };

    return SyncAction(
      id: fields[0] as String,
      type: SyncActionType.values[fields[1] as int],
      entityType: SyncEntityType.values[fields[2] as int],
      entityId: fields[3] as String,
      payload: fields[4] as String,
      createdAt: fields[5] as DateTime,
      attempts: fields[6] as int,
    );
  }

  @override
  void write(BinaryWriter writer, SyncAction obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type.index)
      ..writeByte(2)
      ..write(obj.entityType.index)
      ..writeByte(3)
      ..write(obj.entityId)
      ..writeByte(4)
      ..write(obj.payload)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.attempts);
  }
}
