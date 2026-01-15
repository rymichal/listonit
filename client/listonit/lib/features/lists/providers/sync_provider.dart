import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/list_websocket_service.dart';

enum SyncStatus {
  idle,
  connecting,
  connected,
  disconnected,
  error,
}

class SyncState {
  final SyncStatus status;
  final String? currentListId;
  final String? error;
  final List<String> activeUsers;
  final bool isTyping;

  const SyncState({
    this.status = SyncStatus.idle,
    this.currentListId,
    this.error,
    this.activeUsers = const [],
    this.isTyping = false,
  });

  SyncState copyWith({
    SyncStatus? status,
    String? currentListId,
    String? error,
    List<String>? activeUsers,
    bool? isTyping,
  }) {
    return SyncState(
      status: status ?? this.status,
      currentListId: currentListId ?? this.currentListId,
      error: error,
      activeUsers: activeUsers ?? this.activeUsers,
      isTyping: isTyping ?? this.isTyping,
    );
  }

  bool get isConnected => status == SyncStatus.connected;
}

class SyncNotifier extends StateNotifier<SyncState> {
  final ListWebSocketService _webSocketService;

  SyncNotifier(this._webSocketService) : super(const SyncState()) {
    _setupSyncListeners();
  }

  void _setupSyncListeners() {
    _webSocketService.addListener(_handleSyncMessage);
  }

  void _handleSyncMessage(SyncMessage message) {
    switch (message.type) {
      case 'user_joined':
        _handleUserJoined(message);
        break;
      case 'user_left':
        _handleUserLeft(message);
        break;
      case 'user_typing':
        _handleUserTyping(message);
        break;
      case 'items_reordered':
        // Items reordered events will be handled by list_detail_screen
        // which has access to the items provider via ref
        break;
      case 'item_created':
      case 'item_updated':
      case 'item_deleted':
        // These are handled by the items provider
        break;
    }
  }

  void _handleUserJoined(SyncMessage message) {
    final userName = message.data['user_name'] as String?;
    if (userName != null) {
      final updatedUsers = [...state.activeUsers];
      if (!updatedUsers.contains(userName)) {
        updatedUsers.add(userName);
      }
      state = state.copyWith(activeUsers: updatedUsers);
    }
  }

  void _handleUserLeft(SyncMessage message) {
    final userId = message.data['user_id'] as String?;
    if (userId != null) {
      final userName = message.data['user_name'] as String?;
      if (userName != null) {
        final updatedUsers = state.activeUsers.where((u) => u != userName).toList();
        state = state.copyWith(activeUsers: updatedUsers);
      }
    }
  }

  void _handleUserTyping(SyncMessage message) {
    // Set isTyping to true and reset after a timeout
    state = state.copyWith(isTyping: true);
    Future.delayed(const Duration(seconds: 2), () {
      if (state.isTyping) {
        state = state.copyWith(isTyping: false);
      }
    });
  }

  Future<void> connectToList(String listId, String token) async {
    state = state.copyWith(
      status: SyncStatus.connecting,
      currentListId: listId,
      error: null,
    );

    try {
      await _webSocketService.connect(listId, token);
      state = state.copyWith(status: SyncStatus.connected);
    } catch (e) {
      state = state.copyWith(
        status: SyncStatus.error,
        error: e.toString(),
      );
    }
  }

  void disconnect() {
    _webSocketService.disconnect();
    state = state.copyWith(
      status: SyncStatus.disconnected,
      currentListId: null,
      activeUsers: const [],
    );
  }

  void sendTypingIndicator(String userName) {
    if (state.isConnected) {
      _webSocketService.sendTyping(userName);
    }
  }

  void sendSyncAck(String messageId) {
    if (state.isConnected) {
      _webSocketService.sendSyncAck(messageId);
    }
  }

  @override
  void dispose() {
    _webSocketService.removeListener(_handleSyncMessage);
    super.dispose();
  }
}

final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  return SyncNotifier(listWebSocketService);
});
