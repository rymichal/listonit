import '../domain/item.dart';

enum ConflictResolutionStrategy {
  /// Last write wins - use the most recent update
  lastWriteWins,

  /// Keep local changes and discard remote
  keepLocal,

  /// Accept remote changes and discard local
  acceptRemote,

  /// Merge changes intelligently
  merge,
}

class ConflictResolution {
  final Item resolvedItem;
  final bool hadConflict;
  final String? conflictDescription;

  ConflictResolution({
    required this.resolvedItem,
    required this.hadConflict,
    this.conflictDescription,
  });
}

class ConflictResolver {
  /// Resolve conflicts between local and remote items
  static ConflictResolution resolve({
    required Item localItem,
    required Item remoteItem,
    ConflictResolutionStrategy strategy = ConflictResolutionStrategy.merge,
  }) {
    // If items are identical, no conflict
    if (_itemsAreEqual(localItem, remoteItem)) {
      return ConflictResolution(
        resolvedItem: remoteItem,
        hadConflict: false,
      );
    }

    switch (strategy) {
      case ConflictResolutionStrategy.lastWriteWins:
        return _resolveByLastWrite(localItem, remoteItem);

      case ConflictResolutionStrategy.keepLocal:
        return ConflictResolution(
          resolvedItem: localItem,
          hadConflict: true,
          conflictDescription: 'Kept local changes (${localItem.name})',
        );

      case ConflictResolutionStrategy.acceptRemote:
        return ConflictResolution(
          resolvedItem: remoteItem,
          hadConflict: true,
          conflictDescription: 'Accepted remote changes (${remoteItem.name})',
        );

      case ConflictResolutionStrategy.merge:
        return _mergeDifferences(localItem, remoteItem);
    }
  }

  static ConflictResolution _resolveByLastWrite(Item local, Item remote) {
    final isRemoteNewer = remote.updatedAt.isAfter(local.updatedAt);

    return ConflictResolution(
      resolvedItem: isRemoteNewer ? remote : local,
      hadConflict: true,
      conflictDescription:
          'Resolved using last write wins (${isRemoteNewer ? 'remote' : 'local'})',
    );
  }

  static ConflictResolution _mergeDifferences(Item local, Item remote) {
    final isRemoteNewer = remote.updatedAt.isAfter(local.updatedAt);

    // Merge by taking the most recent value for each field
    final mergedItem = Item(
      id: local.id,
      listId: local.listId,
      name: isRemoteNewer ? remote.name : local.name,
      quantity: isRemoteNewer ? remote.quantity : local.quantity,
      unit: isRemoteNewer ? remote.unit : local.unit,
      note: isRemoteNewer ? remote.note : local.note,
      isChecked: isRemoteNewer ? remote.isChecked : local.isChecked,
      checkedAt: isRemoteNewer ? remote.checkedAt : local.checkedAt,
      checkedBy: isRemoteNewer ? remote.checkedBy : local.checkedBy,
      sortIndex: isRemoteNewer ? remote.sortIndex : local.sortIndex,
      createdAt: local.createdAt,
      updatedAt: isRemoteNewer ? remote.updatedAt : local.updatedAt,
      createdBy: local.createdBy,
      isLocal: false,
    );

    // Detect if name changed
    final nameChanged = local.name != remote.name;
    // Detect if checked status changed
    final statusChanged = local.isChecked != remote.isChecked;
    // Detect if quantity changed
    final quantityChanged = local.quantity != remote.quantity;

    String conflictDesc = 'Merged changes';
    if (nameChanged) conflictDesc += ' (name updated)';
    if (statusChanged) conflictDesc += ' (status changed)';
    if (quantityChanged) conflictDesc += ' (quantity updated)';

    return ConflictResolution(
      resolvedItem: mergedItem,
      hadConflict: true,
      conflictDescription: conflictDesc,
    );
  }

  static bool _itemsAreEqual(Item a, Item b) {
    return a.id == b.id &&
        a.name == b.name &&
        a.quantity == b.quantity &&
        a.unit == b.unit &&
        a.note == b.note &&
        a.isChecked == b.isChecked &&
        a.checkedAt == b.checkedAt &&
        a.checkedBy == b.checkedBy &&
        a.sortIndex == b.sortIndex;
  }

  /// Detect if two updates are conflicting
  /// Returns true if both local and remote have different non-mergeable changes
  static bool hasConflict(Item local, Item remote) {
    if (_itemsAreEqual(local, remote)) return false;

    // Check for status change conflicts (can't merge)
    if (local.isChecked != remote.isChecked) {
      // This is a conflict if both were changed from original
      return true;
    }

    // Check for name conflicts (can't merge)
    if (local.name != remote.name) {
      return true;
    }

    return false;
  }
}
