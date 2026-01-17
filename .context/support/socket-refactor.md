# WebSocket Architecture Refactor Plan

## Executive Summary

Refactor the WebSocket system from a confusing multi-listener pattern to a clean, centralized message router architecture. This will fix the item sync bug and prevent similar issues in the future.

**Time Estimate:** 2-3 hours
**Risk Level:** Medium (touching critical real-time sync infrastructure)
**Breaking Changes:** None (internal refactor only)

---

## Phase 0: Files to Remove/Rename

### Files to DELETE ❌

None - we'll refactor existing files rather than delete them.

### Files to RENAME 📝

1. **sync_provider.dart** → **presence_provider.dart**
   - Current: [lib/features/lists/providers/sync_provider.dart](client/listonit/lib/features/lists/providers/sync_provider.dart)
   - New: `lib/features/lists/providers/presence_provider.dart`
   - Reason: Name accurately reflects what it does (user presence, not general sync)

### Files to KEEP (but heavily modify) ✏️

1. **list_websocket_service.dart** - Convert from global singleton to Riverpod provider
2. **list_detail_screen.dart** - Remove message handling logic
3. **items_provider.dart** - Add server sync methods
4. **sync_status_indicator.dart** - Update to use new provider names

---

## Phase 1: Create New Core Components

### 1.1 WebSocket Connection Provider
**New File:** `lib/core/websocket/websocket_connection_provider.dart`

**Purpose:** Manages WebSocket connection lifecycle and state

**Code Structure:**
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:async';
import 'dart:convert';

enum ConnectionStatus {
  idle,
  connecting,
  connected,
  disconnected,
  reconnecting,
  error,
}

class ConnectionState {
  final ConnectionStatus status;
  final String? currentListId;
  final String? error;
  final int reconnectAttempts;

  const ConnectionState({
    this.status = ConnectionStatus.idle,
    this.currentListId,
    this.error,
    this.reconnectAttempts = 0,
  });

  ConnectionState copyWith({
    ConnectionStatus? status,
    String? currentListId,
    String? error,
    int? reconnectAttempts,
  }) {
    return ConnectionState(
      status: status ?? this.status,
      currentListId: currentListId ?? this.currentListId,
      error: error,
      reconnectAttempts: reconnectAttempts ?? this.reconnectAttempts,
    );
  }

  bool get isConnected => status == ConnectionStatus.connected;
}

class WebSocketConnection extends StateNotifier<ConnectionState> {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  String? _token;
  Timer? _reconnectTimer;

  static const int maxReconnectAttempts = 5;
  static const Duration reconnectDelay = Duration(seconds: 3);

  final String baseUrl;
  final StreamController<Map<String, dynamic>> _messageController;

  WebSocketConnection({
    required this.baseUrl,
  })  : _messageController = StreamController<Map<String, dynamic>>.broadcast(),
        super(const ConnectionState());

  // Expose message stream for router to consume
  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  Future<void> connect(String listId, String token) async {
    _token = token;
    state = state.copyWith(
      status: ConnectionStatus.connecting,
      currentListId: listId,
      error: null,
      reconnectAttempts: 0,
    );

    await _doConnect();
  }

  Future<void> _doConnect() async {
    try {
      final uri = Uri.parse('$baseUrl/ws/lists/${state.currentListId}?token=$_token');
      _channel = WebSocketChannel.connect(uri);

      _subscription = _channel!.stream.listen(
        _handleMessage,
        onDone: _handleDisconnect,
        onError: _handleError,
      );

      state = state.copyWith(
        status: ConnectionStatus.connected,
        reconnectAttempts: 0,
      );
    } catch (e) {
      _handleError(e);
    }
  }

  void _handleMessage(dynamic rawMessage) {
    try {
      final message = jsonDecode(rawMessage) as Map<String, dynamic>;
      _messageController.add(message);
    } catch (e) {
      debugPrint('Error parsing WebSocket message: $e');
    }
  }

  void _handleDisconnect() {
    state = state.copyWith(status: ConnectionStatus.disconnected);
    _attemptReconnect();
  }

  void _handleError(dynamic error) {
    debugPrint('WebSocket error: $error');
    state = state.copyWith(
      status: ConnectionStatus.error,
      error: error.toString(),
    );
    _attemptReconnect();
  }

  void _attemptReconnect() {
    if (state.reconnectAttempts >= maxReconnectAttempts) {
      debugPrint('Max reconnection attempts reached');
      state = state.copyWith(status: ConnectionStatus.error, error: 'Max reconnection attempts reached');
      return;
    }

    state = state.copyWith(
      status: ConnectionStatus.reconnecting,
      reconnectAttempts: state.reconnectAttempts + 1,
    );

    debugPrint('Attempting to reconnect... (attempt ${state.reconnectAttempts})');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(reconnectDelay, () async {
      if (state.currentListId != null && _token != null) {
        await _doConnect();
      }
    });
  }

  void send(Map<String, dynamic> message) {
    try {
      _channel?.sink.add(jsonEncode(message));
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    state = state.copyWith(
      status: ConnectionStatus.disconnected,
      currentListId: null,
    );
  }

  @override
  void dispose() {
    disconnect();
    _messageController.close();
    super.dispose();
  }
}

// Provider
final websocketConnectionProvider =
    StateNotifierProvider<WebSocketConnection, ConnectionState>((ref) {
  return WebSocketConnection(
    baseUrl: ApiConfig.wsBaseUrl,
  );
});
```

**Key Features:**
- ✅ Riverpod provider (not global singleton)
- ✅ Stream-based message output (not listener pattern)
- ✅ Clean state management
- ✅ Automatic reconnection
- ✅ Testable and mockable

---

### 1.2 WebSocket Message Router
**New File:** `lib/core/websocket/websocket_message_router.dart`

**Purpose:** Single point of message routing to appropriate providers

**Code Structure:**
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

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
```

**Key Features:**
- ✅ Single place to see all message routing logic
- ✅ Clear switch statement for all message types
- ✅ Extracts current user ID to filter own messages
- ✅ Robust error handling
- ✅ Easy to add new message types
- ✅ Centralized logging for debugging

---

### 1.3 Presence Provider (renamed from SyncProvider)
**New File:** `lib/features/lists/providers/presence_provider.dart`

**Purpose:** Track active users and typing indicators (NOT general sync)

**Code Structure:**
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PresenceState {
  final Map<String, String> activeUsers; // userId -> userName
  final String? currentlyTypingUser;

  const PresenceState({
    this.activeUsers = const {},
    this.currentlyTypingUser,
  });

  PresenceState copyWith({
    Map<String, String>? activeUsers,
    String? currentlyTypingUser,
  }) {
    return PresenceState(
      activeUsers: activeUsers ?? this.activeUsers,
      currentlyTypingUser: currentlyTypingUser,
    );
  }

  List<String> get userNames => activeUsers.values.toList();
  int get userCount => activeUsers.length;
}

class PresenceNotifier extends StateNotifier<PresenceState> {
  PresenceNotifier() : super(const PresenceState());

  void handleUserJoined(String userId, String userName) {
    final updatedUsers = Map<String, String>.from(state.activeUsers);
    updatedUsers[userId] = userName;

    state = state.copyWith(activeUsers: updatedUsers);
    debugPrint('User joined: $userName (total: ${updatedUsers.length})');
  }

  void handleUserLeft(String userId, String? userName) {
    final updatedUsers = Map<String, String>.from(state.activeUsers);
    updatedUsers.remove(userId);

    state = state.copyWith(activeUsers: updatedUsers);
    debugPrint('User left: $userName (remaining: ${updatedUsers.length})');
  }

  void handleUserTyping(String userId, String userName) {
    state = state.copyWith(currentlyTypingUser: userName);

    // Clear typing indicator after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (state.currentlyTypingUser == userName) {
        state = state.copyWith(currentlyTypingUser: null);
      }
    });
  }

  void reset() {
    state = const PresenceState();
  }
}

final presenceProvider = StateNotifierProvider<PresenceNotifier, PresenceState>((ref) {
  return PresenceNotifier();
});
```

**Key Features:**
- ✅ Clear, focused responsibility
- ✅ No WebSocket knowledge
- ✅ Called by message router
- ✅ Accurate naming

---

## Phase 2: Modify Existing Components

### 2.1 Update Items Provider
**File:** `lib/features/items/providers/items_provider.dart`

**Changes:** Add server sync methods

**Add to ItemsNotifier class:**
```dart
/// Called by WebSocket router when item is created on another device
void addItemFromServer(Map<String, dynamic> itemData) {
  try {
    final item = Item.fromJson(itemData);

    // Prevent duplicates
    if (state.items.any((i) => i.id == item.id)) {
      debugPrint('Item ${item.id} already exists, skipping add from server');
      return;
    }

    state = state.copyWith(
      items: [...state.items, item],
    );

    debugPrint('Added item from server: ${item.name}');
  } catch (e) {
    debugPrint('Failed to add item from server: $e');
  }
}

/// Called by WebSocket router when item is updated on another device
void updateItemFromServer(Map<String, dynamic> itemData) {
  try {
    final updatedItem = Item.fromJson(itemData);

    final itemIndex = state.items.indexWhere((i) => i.id == updatedItem.id);
    if (itemIndex == -1) {
      debugPrint('Item ${updatedItem.id} not found for update, ignoring');
      return;
    }

    state = state.copyWith(
      items: state.items.map((i) => i.id == updatedItem.id ? updatedItem : i).toList(),
    );

    debugPrint('Updated item from server: ${updatedItem.name}');
  } catch (e) {
    debugPrint('Failed to update item from server: $e');
  }
}

/// Called by WebSocket router when item is deleted on another device
void deleteItemFromServer(String itemId) {
  final itemExists = state.items.any((i) => i.id == itemId);
  if (!itemExists) {
    debugPrint('Item $itemId not found for deletion, ignoring');
    return;
  }

  state = state.copyWith(
    items: state.items.where((i) => i.id != itemId).toList(),
  );

  debugPrint('Deleted item from server: $itemId');
}

// applyReorderFromServer already exists - no changes needed
```

**Location:** Add after line 574 (before the provider definition)

---

### 2.2 Update List Detail Screen
**File:** `lib/features/lists/presentation/list_detail_screen.dart`

**Changes:** Remove ALL WebSocket handling - just connect/disconnect

**Replace lines 69-108 with:**
```dart
Future<void> _connectSync() async {
  final authState = ref.read(authProvider);
  if (authState.isAuthenticated) {
    try {
      final tokenStorage = ref.read(tokenStorageProvider);
      final token = await tokenStorage.getAccessToken();
      if (token != null && mounted) {
        await ref.read(websocketConnectionProvider.notifier).connect(
              widget.list.id,
              token,
            );
      }
    } catch (e) {
      debugPrint('Failed to connect WebSocket: $e');
    }
  }
}

@override
void dispose() {
  try {
    if (mounted) {
      ref.read(websocketConnectionProvider.notifier).disconnect();
    }
  } catch (_) {
    // Safely ignore errors during dispose
  }
  super.dispose();
}
```

**Remove:**
- `_setupSyncListeners()` method (lines 90-92)
- `_handleSyncMessage()` method (lines 94-108)
- Import for `list_websocket_service.dart` (line 17)
- `listWebSocketService.removeListener()` call (line 115)

**Update import on line 16:**
```dart
// OLD
import '../providers/sync_provider.dart';

// NEW
import '../providers/presence_provider.dart';
import '../../../../core/websocket/websocket_connection_provider.dart';
```

---

### 2.3 Update Sync Status Indicator
**File:** `lib/features/lists/presentation/widgets/sync_status_indicator.dart`

**Changes:** Use new provider names

**Update imports:**
```dart
// OLD (line 4)
import '../../providers/sync_provider.dart';

// NEW
import '../../providers/presence_provider.dart';
import '../../../../../core/websocket/websocket_connection_provider.dart';
```

**Update build method (lines 10-27):**
```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final connectionState = ref.watch(websocketConnectionProvider);
  final presenceState = ref.watch(presenceProvider);

  return AnimatedOpacity(
    opacity: connectionState.status == ConnectionStatus.idle ? 0 : 1,
    duration: const Duration(milliseconds: 300),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatusBar(context, connectionState),
          if (presenceState.userCount > 0)
            _buildActiveUsersBar(context, presenceState),
        ],
      ),
    ),
  );
}
```

**Update _buildStatusBar signature (line 30):**
```dart
// OLD
Widget _buildStatusBar(BuildContext context, SyncState syncState)

// NEW
Widget _buildStatusBar(BuildContext context, ConnectionState connectionState)
```

**Update _buildActiveUsersBar signature (line 60):**
```dart
// OLD
Widget _buildActiveUsersBar(BuildContext context, SyncState syncState)

// NEW
Widget _buildActiveUsersBar(BuildContext context, PresenceState presenceState)
```

**Update references inside methods:**
- `syncState.status` → `connectionState.status`
- `syncState.activeUsers` → `presenceState.userNames`
- `syncState.activeUsers.length` → `presenceState.userCount`
- `SyncStatus` → `ConnectionStatus`

---

### 2.4 Delete Old WebSocket Service
**File:** `lib/features/lists/services/list_websocket_service.dart`

**Action:** DELETE this file entirely

**Reason:** Replaced by `websocket_connection_provider.dart`

---

### 2.5 Delete Old Sync Provider
**File:** `lib/features/lists/providers/sync_provider.dart`

**Action:** DELETE this file entirely

**Reason:** Replaced by `presence_provider.dart` + `websocket_connection_provider.dart`

---

## Phase 3: Backend Updates (Add Missing Broadcasts)

### 3.1 Update Item Service - Add Missing Broadcasts
**File:** `backend/services/item_service.py`

**Add broadcast to update_item (line 74-82):**
```python
def update_item(
    self, list_id: str, item_id: str, update_data: ItemUpdate, user_id: str
) -> ItemResponse:
    self._verify_list_access(list_id, user_id)
    item = self._get_item_or_404(item_id, list_id)
    updated = self.repository.update(item, update_data)
    response = ItemResponse.model_validate(updated)

    # Broadcast to WebSocket clients
    import asyncio
    try:
        asyncio.create_task(
            manager.broadcast(
                list_id,
                {
                    "type": "item_updated",
                    "item": response.model_dump(),
                    "user_id": user_id,
                },
            )
        )
    except Exception:
        pass

    return response
```

**Add broadcast to delete_item (line 112-117):**
```python
def delete_item(self, list_id: str, item_id: str, user_id: str) -> None:
    self._verify_list_access(list_id, user_id)
    item = self._get_item_or_404(item_id, list_id)
    self.repository.delete(item)

    # Broadcast to WebSocket clients
    import asyncio
    try:
        asyncio.create_task(
            manager.broadcast(
                list_id,
                {
                    "type": "item_deleted",
                    "item_id": item_id,
                    "user_id": user_id,
                },
            )
        )
    except Exception:
        pass
```

**Add broadcast to create_items_batch (line 43-58):**
```python
def create_items_batch(
    self, list_id: str, names: list[str], user_id: str
) -> list[ItemResponse]:
    self._verify_list_access(list_id, user_id)

    valid_names = [n.strip() for n in names if n.strip()]
    if not valid_names:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No valid item names provided",
        )

    items = self.repository.create_batch(list_id, valid_names, user_id)
    responses = [ItemResponse.model_validate(item) for item in items]

    # Broadcast each item creation
    import asyncio
    try:
        for response in responses:
            asyncio.create_task(
                manager.broadcast(
                    list_id,
                    {
                        "type": "item_added",
                        "item": response.model_dump(),
                        "user_id": user_id,
                    },
                )
            )
    except Exception:
        pass

    return responses
```

**Add broadcast to batch_check (line 125-131):**
```python
def batch_check(
    self, list_id: str, item_ids: list[str], checked: bool, user_id: str
) -> int:
    self._verify_list_access(list_id, user_id)
    count = self.repository.batch_check(list_id, item_ids, checked, user_id)

    # Broadcast update for each item
    import asyncio
    try:
        for item_id in item_ids:
            item = self.repository.get_by_id(item_id)
            if item:
                asyncio.create_task(
                    manager.broadcast(
                        list_id,
                        {
                            "type": "item_updated",
                            "item": ItemResponse.model_validate(item).model_dump(),
                            "user_id": user_id,
                        },
                    )
                )
    except Exception:
        pass

    return count
```

**Add broadcast to reorder_items (line 139-164):**
```python
def reorder_items(
    self, list_id: str, reorder_data: ItemReorder, user_id: str
) -> dict:
    self._verify_list_access(list_id, user_id)

    reorder_entries = [
        {"item_id": entry.item_id, "sort_index": entry.sort_index}
        for entry in reorder_data.items
    ]

    count = self.repository.bulk_update_sort_indices(list_id, reorder_entries)

    # Broadcast reorder event
    import asyncio
    try:
        asyncio.create_task(
            manager.broadcast(
                list_id,
                {
                    "type": "items_reordered",
                    "items": reorder_entries,
                    "user_id": user_id,
                },
            )
        )
    except Exception:
        pass

    return {"success": True, "count": count}
```

---

## Phase 4: Initialize Router on App Start

### 4.1 Update Main App Provider Scope
**File:** `lib/main.dart`

**Find the ProviderScope and ensure router auto-initializes:**

**Add after app initialization (in main()):**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ... existing initialization code ...

  runApp(
    ProviderScope(
      observers: [
        // Existing observers
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize WebSocket router (this starts listening to messages)
    ref.watch(websocketAutoInitProvider);

    // ... rest of build method ...
  }
}
```

---

## Phase 5: Update Tests

### 5.1 Update Mock Providers
**File:** `test/mocks/mock_providers.dart`

**Replace syncProvider mock (line 281):**
```dart
// OLD
syncProvider.overrideWith((ref) {
  // mock implementation
});

// NEW - add both new providers
presenceProvider.overrideWith((ref) {
  return MockPresenceNotifier();
}),
websocketConnectionProvider.overrideWith((ref) {
  return MockWebSocketConnection();
}),
```

**Add mock classes:**
```dart
class MockWebSocketConnection extends StateNotifier<ConnectionState>
    implements WebSocketConnection {
  MockWebSocketConnection() : super(const ConnectionState());

  @override
  Future<void> connect(String listId, String token) async {
    state = state.copyWith(
      status: ConnectionStatus.connected,
      currentListId: listId,
    );
  }

  @override
  void disconnect() {
    state = state.copyWith(status: ConnectionStatus.disconnected);
  }

  @override
  void send(Map<String, dynamic> message) {}

  @override
  Stream<Map<String, dynamic>> get messages => const Stream.empty();
}

class MockPresenceNotifier extends PresenceNotifier {
  // Can use default implementation or override as needed
}
```

---

## Phase 6: Testing Plan

### 6.1 Unit Tests

**Create:** `test/core/websocket/websocket_message_router_test.dart`

Test cases:
- ✅ Routes item_added to ItemsProvider
- ✅ Routes item_updated to ItemsProvider
- ✅ Routes item_deleted to ItemsProvider
- ✅ Routes items_reordered to ItemsProvider
- ✅ Routes user_joined to PresenceProvider
- ✅ Routes user_left to PresenceProvider
- ✅ Routes user_typing to PresenceProvider
- ✅ Filters out current user's messages
- ✅ Handles malformed messages gracefully
- ✅ Logs unknown message types

**Create:** `test/core/websocket/websocket_connection_provider_test.dart`

Test cases:
- ✅ Connects successfully
- ✅ Handles connection errors
- ✅ Reconnects on disconnect
- ✅ Max reconnect attempts
- ✅ Sends messages correctly
- ✅ Parses incoming messages
- ✅ Disconnects cleanly

**Create:** `test/features/lists/providers/presence_provider_test.dart`

Test cases:
- ✅ Tracks user join
- ✅ Tracks user leave
- ✅ Handles typing indicators
- ✅ Typing timeout clears state

### 6.2 Integration Tests

**Update:** `integration_test/sharing_and_collaboration_test.dart`

Add test:
```dart
testWidgets('Real-time item sync between devices', (tester) async {
  // Simulate two devices looking at same list
  // Device A adds item
  // Verify device B receives update via WebSocket
  // Verify item appears in UI
});
```

### 6.3 Manual Testing Checklist

- [ ] Connect two devices to same list
- [ ] Device A adds item → appears on device B
- [ ] Device B toggles item → updates on device A
- [ ] Device A deletes item → disappears on device B
- [ ] Device A reorders items → reorders on device B
- [ ] Disconnect device B → device A still works
- [ ] Reconnect device B → receives missed updates
- [ ] Check connection status indicator updates correctly
- [ ] Check active users count is accurate
- [ ] Check typing indicators work
- [ ] Test with 3+ devices simultaneously
- [ ] Test offline → online transition
- [ ] Test rapid changes (no race conditions)

---

## Migration Checklist

### Pre-Migration
- [ ] Create feature branch: `git checkout -b refactor/websocket-architecture`
- [ ] Ensure all existing tests pass
- [ ] Document current behavior for regression testing

### Phase 1: Create New Components
- [ ] Create `lib/core/websocket/` directory
- [ ] Create `websocket_connection_provider.dart`
- [ ] Create `websocket_message_router.dart`
- [ ] Create `presence_provider.dart` (copy + modify sync_provider.dart)
- [ ] Verify new files compile

### Phase 2: Update Items Provider
- [ ] Add `addItemFromServer()` method
- [ ] Add `updateItemFromServer()` method
- [ ] Add `deleteItemFromServer()` method
- [ ] Verify items_provider still compiles

### Phase 3: Update UI Components
- [ ] Update `list_detail_screen.dart` - remove message handling
- [ ] Update `sync_status_indicator.dart` - use new providers
- [ ] Update imports throughout app
- [ ] Fix any compilation errors

### Phase 4: Delete Old Files
- [ ] Delete `list_websocket_service.dart`
- [ ] Delete `sync_provider.dart`
- [ ] Remove all imports to deleted files

### Phase 5: Backend Updates
- [ ] Add broadcast to `update_item()`
- [ ] Add broadcast to `delete_item()`
- [ ] Add broadcast to `create_items_batch()`
- [ ] Add broadcast to `batch_check()`
- [ ] Add broadcast to `reorder_items()`
- [ ] Test backend broadcasts with curl/Postman

### Phase 6: Initialize Router
- [ ] Update `main.dart` to initialize router
- [ ] Verify router starts on app launch
- [ ] Check logs for message routing

### Phase 7: Update Tests
- [ ] Update mock providers
- [ ] Create router unit tests
- [ ] Create connection provider unit tests
- [ ] Create presence provider unit tests
- [ ] Update integration tests
- [ ] All tests pass

### Phase 8: Manual Testing
- [ ] Test on 2 devices (phone + emulator)
- [ ] Test all CRUD operations sync in real-time
- [ ] Test presence features
- [ ] Test reconnection
- [ ] Test offline scenarios
- [ ] No regressions in existing features

### Phase 9: Cleanup
- [ ] Remove debug print statements (or configure for debug mode only)
- [ ] Add documentation comments
- [ ] Update README if needed
- [ ] Code review

### Phase 10: Deploy
- [ ] Merge to main
- [ ] Deploy backend changes
- [ ] Release app update
- [ ] Monitor error logs for WebSocket issues

---

## Rollback Plan

If issues arise after deployment:

1. **Immediate Rollback:**
   - Revert git commit: `git revert <commit-hash>`
   - Redeploy previous version
   - Investigation can happen offline

2. **Partial Rollback:**
   - If backend is fine but frontend has issues, just roll back app
   - If app is fine but backend has issues, roll back backend

3. **Debug in Production:**
   - Add verbose logging to router
   - Check WebSocket connection logs
   - Monitor message flow through router

---

## Success Metrics

After refactor is complete:

- ✅ Items created on device A appear on device B within 500ms
- ✅ No duplicate items from WebSocket messages
- ✅ Connection status indicator accurate
- ✅ Active users count correct
- ✅ All integration tests pass
- ✅ No increase in error logs
- ✅ Code is easier to understand (fewer "what does this do?" questions)
- ✅ Adding new WebSocket message types takes <5 minutes

---

## Future Enhancements (Post-Refactor)

Once the new architecture is stable:

1. **Message Deduplication:** Track message IDs to prevent duplicate processing
2. **Conflict Resolution:** Handle simultaneous edits gracefully (CRDT or last-write-wins)
3. **Offline Queue Replay:** Sync queued actions when reconnecting
4. **Batch Broadcasts:** Combine rapid changes into single message
5. **Delta Updates:** Only send changed fields, not full objects
6. **Presence Enhancements:** Show who's editing which item
7. **Typing Indicators for Items:** Show when someone is editing a specific item
8. **Message Compression:** Use binary protocol for large lists

---

## Questions / Decisions Needed

1. **Item.fromJson() exists?** If not, need to create fromJson factory method
2. **Debug logging:** Should we keep debug prints or use a logger package?
3. **Error reporting:** Should router report errors to crash analytics (Sentry, Firebase)?
4. **Message versioning:** Should we add version field to messages for future compatibility?
5. **Backend message format:** Confirm list_id is included in all messages or extract from connection context

---

## Estimated Timeline

- **Phase 1 (Create new components):** 1 hour
- **Phase 2-3 (Update existing files):** 45 minutes
- **Phase 4-5 (Backend updates):** 30 minutes
- **Phase 6 (Initialize router):** 15 minutes
- **Phase 7 (Update tests):** 1 hour
- **Phase 8 (Manual testing):** 30 minutes
- **Phase 9 (Cleanup):** 15 minutes

**Total: ~4-5 hours** (including breaks and debugging)

If working in focused sessions: **2-3 coding sessions**

---

## Notes

- This refactor does NOT change any user-facing behavior
- Existing offline sync, optimistic updates, etc. all remain unchanged
- The goal is architectural cleanup + fixing the item sync bug
- Router pattern is industry-standard for message-based systems
- Future developers will thank you for the clear architecture
