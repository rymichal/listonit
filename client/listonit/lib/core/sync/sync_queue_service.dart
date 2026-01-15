import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';
import '../storage/hive_service.dart';
import '../storage/sync_action.dart';

class SyncResult {
  final int successful;
  final int failed;
  final List<Map<String, dynamic>> conflicts;

  SyncResult({
    required this.successful,
    required this.failed,
    required this.conflicts,
  });

  bool get hasConflicts => conflicts.isNotEmpty;
  int get total => successful + failed;
}

class SyncQueueService {
  final ApiClient _apiClient;

  SyncQueueService(this._apiClient);

  /// Add an action to the sync queue
  Future<void> enqueue(
    SyncActionType type,
    SyncEntityType entityType,
    String entityId,
    Map<String, dynamic> payload,
  ) async {
    final action = SyncAction(
      id: _generateId(),
      type: type,
      entityType: entityType,
      entityId: entityId,
      payload: jsonEncode(payload),
      createdAt: DateTime.now(),
      attempts: 0,
    );
    await HiveService.syncQueueBox.put(action.id, action);
  }

  /// Process all queued actions
  Future<SyncResult> processQueue() async {
    final box = HiveService.syncQueueBox;
    final actions = box.values.toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    int successful = 0;
    int failed = 0;
    final conflicts = <Map<String, dynamic>>[];

    for (var action in actions) {
      try {
        await _executeAction(action);
        await box.delete(action.id);
        successful++;
      } catch (e) {
        action = action.copyWith(attempts: action.attempts + 1);

        if (action.attempts >= 5) {
          // Move to dead letter queue (keep in box but mark as failed)
          await box.put(action.id, action);
          failed++;
        } else {
          // Retry later
          await box.put(action.id, action);
        }
      }
    }

    return SyncResult(
      successful: successful,
      failed: failed,
      conflicts: conflicts,
    );
  }

  /// Get pending sync actions count
  Future<int> getPendingCount() async {
    return HiveService.syncQueueBox.length;
  }

  /// Clear all sync actions
  Future<void> clearQueue() async {
    await HiveService.syncQueueBox.clear();
  }

  /// Get failed actions (attempts >= 5)
  Future<List<SyncAction>> getFailedActions() async {
    final box = HiveService.syncQueueBox;
    final actions = box.values.where((a) => a.attempts >= 5).toList();
    return actions;
  }

  /// Execute a single sync action
  Future<void> _executeAction(SyncAction action) async {
    final payload = jsonDecode(action.payload) as Map<String, dynamic>;

    switch (action.type) {
      case SyncActionType.create:
        switch (action.entityType) {
          case SyncEntityType.list:
            await _apiClient.post(
              '/lists',
              data: payload,
              fromJson: (_) => null,
            );
          case SyncEntityType.item:
            await _apiClient.post(
              '/items',
              data: payload,
              fromJson: (_) => null,
            );
        }

      case SyncActionType.update:
        switch (action.entityType) {
          case SyncEntityType.list:
            await _apiClient.patch(
              '/lists/${action.entityId}',
              data: payload,
              fromJson: (_) => null,
            );
          case SyncEntityType.item:
            await _apiClient.patch(
              '/items/${action.entityId}',
              data: payload,
              fromJson: (_) => null,
            );
        }

      case SyncActionType.delete:
        switch (action.entityType) {
          case SyncEntityType.list:
            await _apiClient.delete('/lists/${action.entityId}');
          case SyncEntityType.item:
            await _apiClient.delete('/items/${action.entityId}');
        }
    }
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        (DateTime.now().microsecond % 1000).toString();
  }
}

final syncQueueServiceProvider = Provider<SyncQueueService>(
  (ref) => SyncQueueService(ref.watch(apiClientProvider)),
);
