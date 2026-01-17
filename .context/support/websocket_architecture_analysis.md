# WebSocket Architecture Analysis: Current vs Ideal

## Current Architecture Overview

### The Four Components

#### 1. **ListWebSocketService** (Low-level transport)
**File:** [list_websocket_service.dart](client/listonit/lib/features/lists/services/list_websocket_service.dart)

**What it does:**
- Raw WebSocket connection management
- Connect/disconnect/reconnect logic
- Message parsing (JSON → SyncMessage)
- Listener pattern (broadcast to multiple listeners)
- Send messages to server

**Responsibilities:**
- ✅ Network layer (WebSocketChannel)
- ✅ Reconnection with exponential backoff
- ✅ Message serialization/deserialization
- ✅ Error handling at transport level

**Pattern:** Global singleton (`listWebSocketService`)

---

#### 2. **SyncProvider / SyncNotifier** (State management)
**File:** [sync_provider.dart](client/listonit/lib/features/lists/providers/sync_provider.dart)

**What it does:**
- Manages sync connection STATE (idle, connecting, connected, disconnected, error)
- Tracks active users in the list
- Handles user presence events (user_joined, user_left)
- Handles typing indicators
- **Wraps** listWebSocketService with Riverpod state management

**Responsibilities:**
- ✅ Connection state (for UI)
- ✅ Active users list (for UI)
- ✅ Typing indicator state (for UI)
- ❌ Does NOT handle item sync events (item_added, item_updated, item_deleted)

**Pattern:** Riverpod StateNotifierProvider

**Key Problem:** It adds a listener to `listWebSocketService` but ONLY for presence/typing. Item events are ignored with a comment "handled by items provider" but **items provider has no listener!**

---

#### 3. **list_detail_screen._handleSyncMessage()** (Business logic handler)
**File:** [list_detail_screen.dart](client/listonit/lib/features/lists/presentation/list_detail_screen.dart#L94-L108)

**What it does:**
- Adds ANOTHER listener to `listWebSocketService` (bypassing SyncProvider)
- Handles `items_reordered` events ONLY
- Calls items provider methods to update state

**Responsibilities:**
- ✅ Reordering sync logic
- ❌ Missing item creation/update/delete sync logic

**Key Problem:** Mixing UI layer with business logic

---

#### 4. **SyncStatusIndicator** (UI component)
**File:** [sync_status_indicator.dart](client/listonit/lib/features/lists/presentation/widgets/sync_status_indicator.dart)

**What it does:**
- Displays connection status (connecting, synced, offline, error)
- Shows active users ("2 online: Alice, Bob")

**Responsibilities:**
- ✅ Purely presentational UI
- ✅ Reads from SyncProvider state

**Pattern:** Riverpod ConsumerWidget

---

## Architecture Problems

### Problem 1: Confusing Responsibility Split
```
listWebSocketService (transport layer)
         ↓ broadcasts to ALL listeners
    ┌────┴──────┬─────────────┐
    ↓           ↓             ↓
SyncProvider   list_detail   (potential other listeners)
(presence)     (reorder)     (missing!)
```

**Multiple listeners to the same global service is confusing because:**
- No single source of truth for message routing
- Easy to forget to add handlers
- Hard to reason about which component handles what
- Listeners don't coordinate (could have race conditions)

### Problem 2: Sync Provider Name is Misleading
`SyncProvider` sounds like it handles ALL sync, but it only handles:
- Connection state
- User presence
- Typing indicators

It does NOT handle the actual data sync (items)!

**Better names:**
- `PresenceProvider` or `ConnectionStateProvider`
- `WebSocketConnectionProvider`
- `RealtimePresenceProvider`

### Problem 3: Business Logic in UI Layer
`list_detail_screen._handleSyncMessage()` is a UI component doing business logic:
- Parsing messages
- Deciding what to do with each event type
- Calling provider methods

**This violates separation of concerns!**

### Problem 4: Items Provider is Unaware of WebSocket
[items_provider.dart](client/listonit/lib/features/items/providers/items_provider.dart) has:
- ✅ `applyReorderFromServer()` - added specifically for WebSocket
- ❌ No `addItemFromServer()`, `updateItemFromServer()`, `deleteItemFromServer()`
- ❌ No listener setup in the provider itself

**The items provider should be responsible for its own sync!**

### Problem 5: Global Singleton vs Riverpod
`listWebSocketService` is a global singleton (line 151):
```dart
final listWebSocketService = ListWebSocketService();
```

But the app uses Riverpod everywhere else. This is inconsistent:
- Can't mock for testing
- Can't override in different contexts
- Doesn't participate in Riverpod's dependency injection
- Harder to manage lifecycle

---

## How I Would Design This From Scratch

### Clean Architecture Approach

```
┌─────────────────────────────────────────────────────────┐
│                      UI Layer                            │
│  - list_detail_screen.dart                              │
│  - sync_status_indicator.dart                           │
│  - Watches providers, displays state                    │
└────────────────────┬────────────────────────────────────┘
                     │ ref.watch()
┌────────────────────┴────────────────────────────────────┐
│              State Management Layer                      │
│                                                          │
│  ┌────────────────┐  ┌─────────────┐  ┌──────────────┐ │
│  │ ItemsProvider  │  │   Presence   │  │  Connection  │ │
│  │                │  │   Provider   │  │   Provider   │ │
│  │ - items state  │  │ - active     │  │ - status     │ │
│  │ - CRUD ops     │  │   users      │  │ - error      │ │
│  │ - sync from WS │  │ - typing     │  │              │ │
│  └───────┬────────┘  └──────┬──────┘  └──────┬───────┘ │
│          │                  │                 │         │
└──────────┼──────────────────┼─────────────────┼─────────┘
           │                  │                 │
           └──────────┬───────┴─────────────────┘
                      │ subscribes to
┌─────────────────────┴─────────────────────────────────┐
│               Message Bus / Router                     │
│  - Receives ALL WebSocket messages                    │
│  - Routes to appropriate provider based on type       │
│  - Single listener to WebSocketService                │
└────────────────────┬──────────────────────────────────┘
                     │ uses
┌────────────────────┴──────────────────────────────────┐
│            WebSocket Service                          │
│  - Pure transport layer                               │
│  - Connect/disconnect/reconnect                       │
│  - Send/receive raw messages                          │
│  - No business logic                                  │
└───────────────────────────────────────────────────────┘
```

### Proposed Component Breakdown

#### 1. **WebSocketService** (Transport Layer)
**Responsibility:** Raw WebSocket communication ONLY

```dart
@riverpod
class WebSocketService {
  WebSocketChannel? _channel;

  Future<void> connect(String listId, String token);
  void disconnect();
  void send(Map<String, dynamic> message);
  Stream<Map<String, dynamic>> get messages; // Stream instead of listeners
}
```

**Changes from current:**
- ✅ Use Stream<> instead of listener pattern (more Dart-idiomatic)
- ✅ Make it a Riverpod provider (not global singleton)
- ✅ No message type parsing (just pass raw JSON)
- ✅ No reconnection logic here (move to higher layer)

---

#### 2. **WebSocketMessageRouter** (Message Bus)
**NEW component - this is what's missing!**

```dart
@riverpod
class WebSocketMessageRouter {
  WebSocketMessageRouter(this.ref) {
    // Single point of message handling
    ref.listen(webSocketServiceProvider, (prev, next) {
      next.messages.listen((message) => _routeMessage(message));
    });
  }

  void _routeMessage(Map<String, dynamic> message) {
    final type = message['type'] as String;

    switch (type) {
      // Item events → ItemsProvider
      case 'item_added':
      case 'item_updated':
      case 'item_deleted':
        _handleItemEvent(message);
        break;

      // Presence events → PresenceProvider
      case 'user_joined':
      case 'user_left':
      case 'user_typing':
        _handlePresenceEvent(message);
        break;

      // Reorder events → ItemsProvider
      case 'items_reordered':
        _handleReorderEvent(message);
        break;
    }
  }

  void _handleItemEvent(Map<String, dynamic> message) {
    final listId = message['list_id'] as String;
    final notifier = ref.read(itemsProvider(listId).notifier);

    switch (message['type']) {
      case 'item_added':
        notifier.addItemFromServer(message['item']);
        break;
      case 'item_updated':
        notifier.updateItemFromServer(message['item']);
        break;
      case 'item_deleted':
        notifier.deleteItemFromServer(message['item_id']);
        break;
    }
  }

  void _handlePresenceEvent(Map<String, dynamic> message) {
    // Route to presence provider
  }
}
```

**Why this is better:**
- ✅ Single place to see ALL message routing
- ✅ Easy to add new message types
- ✅ Decouples providers from WebSocket details
- ✅ Testable (can inject mock messages)
- ✅ Can add middleware (logging, filtering, deduplication)

---

#### 3. **ItemsProvider** (unchanged, except add sync methods)

```dart
class ItemsNotifier extends StateNotifier<ItemsState> {
  // Existing methods...
  Future<bool> addItem(...) async { }
  Future<bool> toggleItem(...) async { }

  // NEW: Server-initiated updates
  void addItemFromServer(Map<String, dynamic> itemData) {
    // Called by router when 'item_added' received
    final item = Item.fromJson(itemData);
    if (!state.items.any((i) => i.id == item.id)) {
      state = state.copyWith(items: [...state.items, item]);
    }
  }

  void updateItemFromServer(Map<String, dynamic> itemData) {
    // Called by router when 'item_updated' received
  }

  void deleteItemFromServer(String itemId) {
    // Called by router when 'item_deleted' received
  }
}
```

**Why this is better:**
- ✅ Items provider owns all item state changes
- ✅ Clear separation: `addItem()` = user action, `addItemFromServer()` = remote action
- ✅ No WebSocket knowledge needed

---

#### 4. **PresenceProvider** (renamed from SyncProvider)

```dart
@riverpod
class PresenceNotifier extends StateNotifier<PresenceState> {
  PresenceNotifier() : super(PresenceState());

  // Called by message router
  void handleUserJoined(String userId, String userName) {
    state = state.copyWith(
      activeUsers: [...state.activeUsers, userName],
    );
  }

  void handleUserLeft(String userId) {
    // ...
  }

  void handleUserTyping(String userId) {
    // ...
  }
}
```

**Changes:**
- ✅ Renamed to reflect actual purpose
- ✅ No WebSocket listener (router calls methods)
- ✅ Only handles presence, not connection state

---

#### 5. **ConnectionProvider** (NEW - split from SyncProvider)

```dart
@riverpod
class ConnectionNotifier extends StateNotifier<ConnectionState> {
  ConnectionNotifier(this.ref) : super(ConnectionState());

  Future<void> connect(String listId, String token) async {
    state = state.copyWith(status: ConnectionStatus.connecting);

    try {
      await ref.read(webSocketServiceProvider).connect(listId, token);
      state = state.copyWith(status: ConnectionStatus.connected);
    } catch (e) {
      state = state.copyWith(
        status: ConnectionStatus.error,
        error: e.toString(),
      );
    }
  }

  void disconnect() {
    ref.read(webSocketServiceProvider).disconnect();
    state = state.copyWith(status: ConnectionStatus.disconnected);
  }
}

class ConnectionState {
  final ConnectionStatus status;
  final String? error;

  // No activeUsers, no typing - that's PresenceProvider's job
}
```

---

#### 6. **UI Components** (simplified)

```dart
class ListDetailScreen extends ConsumerStatefulWidget {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Just connect - no manual listener setup!
      ref.read(connectionProvider.notifier).connect(widget.list.id, token);

      // Load items
      ref.read(itemsProvider(widget.list.id).notifier).loadItems();
    });
  }

  @override
  void dispose() {
    ref.read(connectionProvider.notifier).disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // No _handleSyncMessage, no _setupSyncListeners
    // Just watch providers!
    final items = ref.watch(itemsProvider(widget.list.id));
    final presence = ref.watch(presenceProvider);
    final connection = ref.watch(connectionProvider);

    return Scaffold(...);
  }
}
```

**Why this is better:**
- ✅ No business logic in UI
- ✅ No manual listener setup/teardown
- ✅ Just connect and watch state
- ✅ Much simpler!

---

## Comparison Table

| Aspect | Current Architecture | Proposed Architecture |
|--------|---------------------|----------------------|
| **Message Routing** | Multiple listeners to global service | Single router component |
| **Separation of Concerns** | UI handles sync logic | Router handles routing, providers handle state |
| **Testability** | Hard (global singleton) | Easy (all providers, mockable) |
| **Discoverability** | Need to grep for listeners | Look at router to see all handlers |
| **Item Sync** | Broken (no handlers) | Router → ItemsProvider methods |
| **Naming Clarity** | "SyncProvider" ambiguous | "PresenceProvider", "ConnectionProvider" clear |
| **WebSocket Service** | Global singleton | Riverpod provider |
| **Lifecycle Management** | Manual in UI | Riverpod automatic |
| **Adding New Events** | Remember to add listener somewhere | Add case to router |

---

## Migration Path

If you want to refactor to the clean architecture:

### Phase 1: Add Message Router (no breaking changes)
1. Create `WebSocketMessageRouter`
2. Move all message handling from `list_detail_screen` and `SyncNotifier` into router
3. Keep existing code working alongside new router

### Phase 2: Add Missing Sync Methods
1. Add `addItemFromServer()`, `updateItemFromServer()`, `deleteItemFromServer()` to ItemsProvider
2. Router calls these methods
3. Remove listener from list_detail_screen

### Phase 3: Rename and Split Providers
1. Rename `SyncProvider` → `PresenceProvider`
2. Extract connection state → `ConnectionProvider`
3. Update UI to use new provider names

### Phase 4: Convert Service to Provider
1. Make `ListWebSocketService` a Riverpod provider
2. Replace global singleton with provider access
3. Change listener pattern to Stream

---

## Recommendation

**For fixing the current bug (minimum effort):**
- Keep current architecture
- Just add item sync handlers to `list_detail_screen._handleSyncMessage()`
- Add sync methods to `ItemsProvider`
- **Time: 30 minutes**

**For clean, maintainable code (proper fix):**
- Implement the Message Router pattern
- Split SyncProvider into PresenceProvider + ConnectionProvider
- Remove business logic from UI layer
- **Time: 2-3 hours**

**The current architecture works, but it's confusing and brittle.** The presence of this bug (missing item sync) proves how easy it is to forget to add handlers with the current design.

With the router pattern, adding a new event type is one obvious place to edit (the router switch statement), not a "where should I add this listener?" question.
