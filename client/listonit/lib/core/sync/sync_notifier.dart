import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/connectivity_service.dart';
import 'sync_queue_service.dart';

/// Represents the current sync status
enum SyncStatusEnum { idle, syncing, synced, error }

class SyncState {
  final SyncStatusEnum status;
  final int pendingActions;
  final String? error;
  final int failedActions;

  const SyncState({
    required this.status,
    required this.pendingActions,
    this.error,
    required this.failedActions,
  });

  const SyncState.idle()
      : status = SyncStatusEnum.idle,
        pendingActions = 0,
        error = null,
        failedActions = 0;

  SyncState copyWith({
    SyncStatusEnum? status,
    int? pendingActions,
    String? error,
    int? failedActions,
  }) {
    return SyncState(
      status: status ?? this.status,
      pendingActions: pendingActions ?? this.pendingActions,
      error: error,
      failedActions: failedActions ?? this.failedActions,
    );
  }
}

class SyncNotifier extends StateNotifier<SyncState> {
  final SyncQueueService _syncQueueService;
  final ConnectivityNotifier _connectivityNotifier;

  SyncNotifier(
    this._syncQueueService,
    this._connectivityNotifier,
  ) : super(const SyncState.idle()) {
    _initialize();
  }

  void _initialize() {
    // Listen for connectivity changes
    _connectivityNotifier.addListener((newState) {
      if (newState.isOnline) {
        sync();
      }
    });
  }

  /// Manually trigger sync
  Future<void> sync() async {
    // Check for pending actions first
    final pendingCount = await _syncQueueService.getPendingCount();
    if (pendingCount == 0) {
      state = state.copyWith(status: SyncStatusEnum.synced, pendingActions: 0);
      return;
    }

    state = state.copyWith(status: SyncStatusEnum.syncing);

    try {
      final result = await _syncQueueService.processQueue();

      final failedCount = await _syncQueueService.getPendingCount();

      state = state.copyWith(
        status: result.hasConflicts ? SyncStatusEnum.error : SyncStatusEnum.synced,
        pendingActions: failedCount,
        failedActions: result.failed,
        error: result.hasConflicts ? 'Sync conflicts detected' : null,
      );
    } catch (e) {
      state = state.copyWith(
        status: SyncStatusEnum.error,
        error: e.toString(),
      );
    }
  }

  /// Get pending actions count
  Future<int> getPendingCount() async {
    return _syncQueueService.getPendingCount();
  }

  /// Retry failed actions
  Future<void> retryFailed() async {
    await sync();
  }

  /// Clear sync queue
  Future<void> clearQueue() async {
    await _syncQueueService.clearQueue();
    state = const SyncState.idle();
  }
}

final syncNotifierProvider = StateNotifierProvider<SyncNotifier, SyncState>(
  (ref) {
    final syncQueueService = ref.watch(syncQueueServiceProvider);
    final connectivityNotifier = ref.watch(connectivityProvider.notifier);
    return SyncNotifier(syncQueueService, connectivityNotifier);
  },
);
