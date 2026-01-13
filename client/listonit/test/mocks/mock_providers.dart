import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:listonit/features/auth/data/auth_service.dart';
import 'package:listonit/features/auth/domain/user.dart';
import 'package:listonit/features/auth/providers/auth_provider.dart';
import 'package:listonit/features/lists/data/list_repository.dart';
import 'package:listonit/features/lists/domain/shopping_list.dart';
import 'package:listonit/features/lists/providers/lists_provider.dart';

// Mock classes
class MockAuthService extends Mock implements AuthService {}

class MockListRepository extends Mock implements ListRepository {}

// Test data
class TestData {
  static User get testUser => User(
        id: 'test-user-id',
        email: 'test@example.com',
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
  }) {
    final now = DateTime.now();
    return ShoppingList(
      id: id ?? 'list-${DateTime.now().millisecondsSinceEpoch}',
      ownerId: 'test-user-id',
      name: name ?? 'Test List',
      color: color ?? '#4CAF50',
      icon: icon ?? 'shopping_cart',
      isArchived: false,
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
}) {
  return [
    if (authState != null)
      authProvider.overrideWith((ref) => TestAuthNotifier(authState)),
    if (listsState != null)
      listsProvider.overrideWith((ref) => TestListsNotifier(listsState)),
    if (mockAuthService != null)
      authServiceProvider.overrideWithValue(mockAuthService),
    if (mockListRepository != null)
      listRepositoryProvider.overrideWithValue(mockListRepository),
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

  TestListsNotifier(this.initialState) : super(MockListRepository()) {
    state = initialState;
  }

  @override
  Future<void> loadLists() async {}
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
