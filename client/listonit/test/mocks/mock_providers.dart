import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:listonit/features/auth/data/auth_service.dart';
import 'package:listonit/features/auth/domain/user.dart';
import 'package:listonit/features/auth/providers/auth_provider.dart';
import 'package:listonit/features/auth/data/token_storage.dart';
import 'package:listonit/features/lists/data/list_repository.dart';
import 'package:listonit/features/lists/domain/shopping_list.dart';
import 'package:listonit/features/lists/providers/lists_provider.dart';
import 'package:listonit/features/lists/providers/presence_provider.dart';
import 'package:listonit/core/websocket/websocket_connection_provider.dart' as ws;
import 'package:listonit/features/items/providers/items_provider.dart';
import 'package:listonit/features/items/providers/item_selection_provider.dart';
import 'package:listonit/features/items/data/item_repository.dart';
import 'package:listonit/features/items/domain/item.dart';
import 'package:listonit/core/sync/sync_queue_service.dart';
import 'package:listonit/core/sync/sync_notifier.dart' as offline_sync;
import 'package:listonit/core/storage/sync_action.dart';
import 'package:listonit/core/network/connectivity_service.dart';

// Mock classes
class MockAuthService extends Mock implements AuthService {}

class MockTokenStorage extends Mock implements TokenStorage {
  @override
  Future<String?> getAccessToken() async => 'test-token';

  @override
  Future<String?> getRefreshToken() async => 'test-refresh-token';

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {}

  @override
  Future<void> clearTokens() async {}
}

class MockListRepository extends Mock implements ListRepository {}

class MockSyncQueueService extends Mock implements SyncQueueService {
  @override
  Future<void> enqueue(
    SyncActionType type,
    SyncEntityType entityType,
    String entityId,
    Map<String, dynamic> payload,
  ) async {}

  @override
  Future<SyncResult> processQueue() async {
    return SyncResult(successful: 0, failed: 0, conflicts: []);
  }

  @override
  Future<int> getPendingCount() async => 0;

  @override
  Future<void> clearQueue() async {}

  @override
  Future<List<SyncAction>> getFailedActions() async => [];
}

class MockConnectivityNotifier extends ConnectivityNotifier {
  MockConnectivityNotifier()
      : super(Connectivity()) {
    state = const ConnectivityState.online();
  }
}

class MockItemRepository extends Mock implements ItemRepository {
  // Store items to maintain state during tests
  final Map<String, Item> _items = {};

  @override
  bool isNetworkError(Object error) => false;

  @override
  Future<Item> createItem({
    required String listId,
    required String name,
    int quantity = 1,
    String? unit,
    String? note,
  }) async {
    final now = DateTime.now();
    final item = Item(
      id: 'item-${DateTime.now().millisecondsSinceEpoch}',
      listId: listId,
      name: name,
      quantity: quantity,
      unit: unit,
      note: note,
      isChecked: false,
      createdBy: 'test-user-id',
      createdAt: now,
      updatedAt: now,
    );
    _items[item.id] = item;
    return item;
  }

  @override
  Future<List<Item>> createItemsBatch({
    required String listId,
    required List<String> names,
  }) async {
    final now = DateTime.now();
    final items = names
        .map((name) {
          final item = Item(
            id: 'item-${DateTime.now().millisecondsSinceEpoch}',
            listId: listId,
            name: name,
            quantity: 1,
            createdBy: 'test-user-id',
            createdAt: now,
            updatedAt: now,
          );
          _items[item.id] = item;
          return item;
        })
        .toList();
    return items;
  }

  @override
  Future<Item> toggleItem({
    required String listId,
    required String itemId,
  }) async {
    // Get the existing item or create a placeholder
    final existingItem = _items[itemId];
    if (existingItem == null) {
      throw Exception('Item not found');
    }

    // Toggle the checked state but preserve all other properties
    final toggledItem = existingItem.copyWith(
      isChecked: !existingItem.isChecked,
      updatedAt: DateTime.now(),
    );
    _items[itemId] = toggledItem;
    return toggledItem;
  }

  @override
  Future<Item> updateItem({
    required String listId,
    required String itemId,
    String? name,
    int? quantity,
    String? unit,
    String? note,
    bool? isChecked,
    int? sortIndex,
  }) async {
    final existingItem = _items[itemId];
    if (existingItem == null) {
      throw Exception('Item not found');
    }

    final updatedItem = existingItem.copyWith(
      name: name ?? existingItem.name,
      quantity: quantity ?? existingItem.quantity,
      unit: unit ?? existingItem.unit,
      note: note ?? existingItem.note,
      isChecked: isChecked ?? existingItem.isChecked,
      sortIndex: sortIndex ?? existingItem.sortIndex,
      updatedAt: DateTime.now(),
    );
    _items[itemId] = updatedItem;
    return updatedItem;
  }
}

// Mock WebSocket Connection
class MockWebSocketConnection extends ws.WebSocketConnection {
  MockWebSocketConnection() : super(baseUrl: 'ws://test');

  @override
  Future<void> connect(String listId, String token) async {
    state = state.copyWith(
      status: ws.ConnectionStatus.connected,
      currentListId: listId,
    );
  }

  @override
  void disconnect() {
    state = state.copyWith(status: ws.ConnectionStatus.disconnected);
  }

  @override
  void send(Map<String, dynamic> message) {}

  @override
  Stream<Map<String, dynamic>> get messages => const Stream.empty();
}

// Mock Presence Notifier
class MockPresenceNotifier extends PresenceNotifier {
  // Can use default implementation or override as needed
}

// Test data
class TestData {
  static User get testUser => User(
        id: 'test-user-id',
        username: 'test',
        name: 'Test User',
        isActive: true,
        isAdmin: false,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

  static ShoppingList createList({
    String? id,
    String? name,
    String? color,
    String? icon,
    String? sortMode,
  }) {
    final now = DateTime.now();
    return ShoppingList(
      id: id ?? 'list-${DateTime.now().millisecondsSinceEpoch}',
      ownerId: 'test-user-id',
      name: name ?? 'Test List',
      color: color ?? '#4CAF50',
      icon: icon ?? 'shopping_cart',
      isArchived: false,
      sortMode: sortMode ?? 'chronological',
      createdAt: now,
      updatedAt: now,
    );
  }

  static List<ShoppingList> get sampleLists => [
        createList(id: 'list-1', name: 'Groceries', color: '#4CAF50', icon: 'local_grocery_store'),
        createList(id: 'list-2', name: 'Hardware Store', color: '#2196F3', icon: 'build'),
        createList(id: 'list-3', name: 'Party Supplies', color: '#E91E63', icon: 'cake'),
      ];
}

// Provider overrides for testing
List<Override> createTestOverrides({
  AuthState? authState,
  ListsState? listsState,
  MockAuthService? mockAuthService,
  MockListRepository? mockListRepository,
  MockTokenStorage? mockTokenStorage,
  MockItemRepository? mockItemRepository,
  MockSyncQueueService? mockSyncQueueService,
}) {
  final tokenStorage = mockTokenStorage ?? MockTokenStorage();
  final itemRepository = mockItemRepository ?? MockItemRepository();
  final syncQueueService = mockSyncQueueService ?? MockSyncQueueService();

  return [
    if (authState != null)
      authProvider.overrideWith((ref) => TestAuthNotifier(authState)),
    if (listsState != null)
      listsProvider.overrideWith((ref) => TestListsNotifier(listsState)),
    if (mockAuthService != null)
      authServiceProvider.overrideWithValue(mockAuthService),
    if (mockListRepository != null)
      listRepositoryProvider.overrideWithValue(mockListRepository),
    // Mock token storage - return access token
    tokenStorageProvider.overrideWithValue(tokenStorage),
    // Mock item repository
    itemRepositoryProvider.overrideWithValue(itemRepository),
    // Mock items provider - returns empty items
    itemsProvider.overrideWith((ref, listId) {
      return ItemsNotifier(itemRepository, syncQueueService, listId);
    }),
    // Mock item selection provider
    itemSelectionProvider.overrideWith((ref) {
      return ItemSelectionNotifier();
    }),
    // Mock WebSocket connection provider
    ws.websocketConnectionProvider.overrideWith((ref) {
      return MockWebSocketConnection();
    }),
    // Mock presence provider
    presenceProvider.overrideWith((ref) {
      return MockPresenceNotifier();
    }),
    // Mock offline sync notifier - for offline support testing
    offline_sync.syncNotifierProvider.overrideWith((ref) {
      return offline_sync.SyncNotifier(
        MockSyncQueueService(),
        // Create a mock connectivity notifier that stays online
        MockConnectivityNotifier(),
      );
    }),
  ];
}

// Test notifiers that start with a specific state
class TestAuthNotifier extends AuthNotifier {
  final AuthState initialState;

  TestAuthNotifier(this.initialState) : super(MockAuthService()) {
    state = initialState;
  }

  @override
  Future<void> checkAuthStatus() async {}
}

class TestListsNotifier extends ListsNotifier {
  final ListsState initialState;

  TestListsNotifier(this.initialState) : super(MockListRepository(), MockSyncQueueService()) {
    state = initialState;
  }

  @override
  Future<void> loadLists() async {}

  @override
  Future<bool> createList({
    required String name,
    String? color,
    String? icon,
  }) async {
    // Optimistically add the list to state
    final tempId = 'temp-${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();

    final newList = ShoppingList(
      id: tempId,
      ownerId: 'test-user-id',
      name: name,
      color: color ?? '#4CAF50',
      icon: icon ?? 'shopping_cart',
      isArchived: false,
      sortMode: 'chronological',
      createdAt: now,
      updatedAt: now,
      isLocal: true,
    );

    state = state.copyWith(
      lists: [newList, ...state.lists],
      error: null,
    );

    return true;
  }
}


// Helper to create an authenticated state
AuthState authenticatedState() => AuthState(
      status: AuthStatus.authenticated,
      user: TestData.testUser,
    );

// Helper to create a state with sample lists
ListsState listsStateWithData() => ListsState(
      lists: TestData.sampleLists,
      isLoading: false,
    );

ListsState emptyListsState() => const ListsState(
      lists: [],
      isLoading: false,
    );

ListsState loadingListsState() => const ListsState(
      lists: [],
      isLoading: true,
    );
