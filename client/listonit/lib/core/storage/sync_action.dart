enum SyncActionType {
  create,
  update,
  delete,
}

enum SyncEntityType {
  list,
  item,
}

class SyncAction {
  final String id;
  final SyncActionType type;
  final SyncEntityType entityType;
  final String entityId; // Temp ID for creates, real ID for updates/deletes
  final String payload; // JSON string
  final DateTime createdAt;
  int attempts;

  SyncAction({
    required this.id,
    required this.type,
    required this.entityType,
    required this.entityId,
    required this.payload,
    required this.createdAt,
    this.attempts = 0,
  });

  SyncAction copyWith({
    String? id,
    SyncActionType? type,
    SyncEntityType? entityType,
    String? entityId,
    String? payload,
    DateTime? createdAt,
    int? attempts,
  }) {
    return SyncAction(
      id: id ?? this.id,
      type: type ?? this.type,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      attempts: attempts ?? this.attempts,
    );
  }
}
