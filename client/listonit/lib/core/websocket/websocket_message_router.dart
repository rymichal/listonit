import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'websocket_connection_provider.dart';
import '../../features/items/providers/items_provider.dart';
import '../../features/lists/providers/presence_provider.dart';
import '../../features/auth/providers/auth_provider.dart';

class WebSocketMessageRouter {
  final Ref ref;
  StreamSubscription? _messageSubscription;

  WebSocketMessageRouter(this.ref) {
    _setupMessageListener();
  }

  void _setupMessageListener() {
    final connection = ref.read(websocketConnectionProvider.notifier);
    _messageSubscription = connection.messages.listen(_routeMessage);
  }

  void _routeMessage(Map<String, dynamic> message) {
    final type = message['type'] as String?;
    if (type == null) {
      debugPrint('WebSocket message missing type field: $message');
      return;
    }

    debugPrint('Routing WebSocket message: $type');

    try {
      switch (type) {
        // ===== Item Events =====
        case 'item_added':
          _handleItemAdded(message);
          break;

        case 'item_updated':
          _handleItemUpdated(message);
          break;

        case 'item_deleted':
          _handleItemDeleted(message);
          break;

        case 'items_reordered':
          _handleItemsReordered(message);
          break;

        // ===== Presence Events =====
        case 'user_joined':
          _handleUserJoined(message);
          break;

        case 'user_left':
          _handleUserLeft(message);
          break;

        case 'user_typing':
          _handleUserTyping(message);
          break;

        // ===== Unknown Events =====
        default:
          debugPrint('Unhandled WebSocket message type: $type');
      }
    } catch (e, stackTrace) {
      debugPrint('Error routing message type "$type": $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  // ===== Item Event Handlers =====

  void _handleItemAdded(Map<String, dynamic> message) {
    final listId = _extractListId(message);
    final itemData = message['item'] as Map<String, dynamic>?;
    final userId = message['user_id'] as String?;

    if (listId == null || itemData == null) {
      debugPrint('Invalid item_added message: missing listId or item');
      return;
    }

    // Don't process our own messages (optimistic updates already applied)
    if (_isCurrentUser(userId)) {
      debugPrint('Ignoring own item_added message');
      return;
    }

    final notifier = ref.read(itemsProvider(listId).notifier);
    notifier.addItemFromServer(itemData);
  }

  void _handleItemUpdated(Map<String, dynamic> message) {
    final listId = _extractListId(message);
    final itemData = message['item'] as Map<String, dynamic>?;
    final userId = message['user_id'] as String?;

    if (listId == null || itemData == null) {
      debugPrint('Invalid item_updated message: missing listId or item');
      return;
    }

    if (_isCurrentUser(userId)) {
      debugPrint('Ignoring own item_updated message');
      return;
    }

    final notifier = ref.read(itemsProvider(listId).notifier);
    notifier.updateItemFromServer(itemData);
  }

  void _handleItemDeleted(Map<String, dynamic> message) {
    final listId = _extractListId(message);
    final itemId = message['item_id'] as String?;
    final userId = message['user_id'] as String?;

    if (listId == null || itemId == null) {
      debugPrint('Invalid item_deleted message: missing listId or itemId');
      return;
    }

    if (_isCurrentUser(userId)) {
      debugPrint('Ignoring own item_deleted message');
      return;
    }

    final notifier = ref.read(itemsProvider(listId).notifier);
    notifier.deleteItemFromServer(itemId);
  }

  void _handleItemsReordered(Map<String, dynamic> message) {
    final listId = _extractListId(message);
    final items = message['items'] as List?;
    final userId = message['user_id'] as String?;

    if (listId == null || items == null) {
      debugPrint('Invalid items_reordered message: missing listId or items');
      return;
    }

    if (_isCurrentUser(userId)) {
      debugPrint('Ignoring own items_reordered message');
      return;
    }

    final reorderedData = items
        .map((item) => {
              'id': item['id'] as String,
              'sort_index': item['sort_index'] as int,
            })
        .toList();

    final notifier = ref.read(itemsProvider(listId).notifier);
    notifier.applyReorderFromServer(reorderedData);
  }

  // ===== Presence Event Handlers =====

  void _handleUserJoined(Map<String, dynamic> message) {
    final userId = message['user_id'] as String?;
    final userName = message['user_name'] as String?;

    if (userId != null && userName != null) {
      ref.read(presenceProvider.notifier).handleUserJoined(userId, userName);
    }
  }

  void _handleUserLeft(Map<String, dynamic> message) {
    final userId = message['user_id'] as String?;
    final userName = message['user_name'] as String?;

    if (userId != null) {
      ref.read(presenceProvider.notifier).handleUserLeft(userId, userName);
    }
  }

  void _handleUserTyping(Map<String, dynamic> message) {
    final userId = message['user_id'] as String?;
    final userName = message['user_name'] as String?;

    if (userId != null && userName != null) {
      ref.read(presenceProvider.notifier).handleUserTyping(userId, userName);
    }
  }

  // ===== Helper Methods =====

  String? _extractListId(Map<String, dynamic> message) {
    // Try to get list_id from message root
    var listId = message['list_id'] as String?;

    // If not found, try to extract from item data
    if (listId == null) {
      final itemData = message['item'] as Map<String, dynamic>?;
      listId = itemData?['list_id'] as String?;
    }

    // If still not found, get from current connection
    if (listId == null) {
      listId = ref.read(websocketConnectionProvider).currentListId;
    }

    return listId;
  }

  bool _isCurrentUser(String? userId) {
    if (userId == null) return false;

    final currentUser = ref.read(authProvider).user;
    return currentUser?.id == userId;
  }

  void dispose() {
    _messageSubscription?.cancel();
  }
}

// Provider - must be initialized on app start
final websocketMessageRouterProvider = Provider<WebSocketMessageRouter>((ref) {
  final router = WebSocketMessageRouter(ref);
  ref.onDispose(() => router.dispose());
  return router;
});

// Auto-initialize router when app starts
final websocketAutoInitProvider = Provider<void>((ref) {
  ref.watch(websocketMessageRouterProvider);
});
