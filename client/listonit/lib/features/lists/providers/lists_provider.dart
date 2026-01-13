import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/network/api_exception.dart';
import '../data/list_repository.dart';
import '../domain/shopping_list.dart';

class ListsState {
  final List<ShoppingList> lists;
  final bool isLoading;
  final String? error;
  final String? pendingRetryId;
  final ShoppingList? deletedList;

  const ListsState({
    this.lists = const [],
    this.isLoading = false,
    this.error,
    this.pendingRetryId,
    this.deletedList,
  });

  ListsState copyWith({
    List<ShoppingList>? lists,
    bool? isLoading,
    String? error,
    String? pendingRetryId,
    ShoppingList? deletedList,
  }) {
    return ListsState(
      lists: lists ?? this.lists,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      pendingRetryId: pendingRetryId,
      deletedList: deletedList,
    );
  }
}

class ListsNotifier extends StateNotifier<ListsState> {
  final ListRepository _repository;
  final Uuid _uuid = const Uuid();

  ListsNotifier(this._repository) : super(const ListsState());

  Future<void> loadLists() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final lists = await _repository.getLists();
      state = state.copyWith(lists: lists, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e is ApiException ? e.message : 'Failed to load lists',
      );
    }
  }

  Future<bool> createList({
    required String name,
    String? color,
    String? icon,
  }) async {
    final tempId = _uuid.v4();
    final now = DateTime.now();

    final optimisticList = ShoppingList(
      id: tempId,
      ownerId: '',
      name: name,
      color: color ?? '#4CAF50',
      icon: icon ?? 'shopping_cart',
      isArchived: false,
      createdAt: now,
      updatedAt: now,
      isLocal: true,
    );

    // Optimistic update
    state = state.copyWith(
      lists: [optimisticList, ...state.lists],
      error: null,
    );

    try {
      final createdList = await _repository.createList(
        name: name,
        color: color,
        icon: icon,
      );

      // Replace temp list with real one
      state = state.copyWith(
        lists: state.lists.map((l) => l.id == tempId ? createdList : l).toList(),
      );

      return true;
    } catch (e) {
      if (_repository.isNetworkError(e)) {
        // Keep optimistic list for offline sync later
        state = state.copyWith(
          error: 'Saved locally. Will sync when online.',
          pendingRetryId: tempId,
        );
        return true;
      } else {
        // Rollback on other errors
        state = state.copyWith(
          lists: state.lists.where((l) => l.id != tempId).toList(),
          error: e is ApiException ? e.message : 'Failed to create list',
        );
        return false;
      }
    }
  }

  Future<bool> retryCreate(String tempId) async {
    final tempList = state.lists.firstWhere(
      (l) => l.id == tempId && l.isLocal,
      orElse: () => throw Exception('List not found'),
    );

    try {
      final createdList = await _repository.createList(
        name: tempList.name,
        color: tempList.color,
        icon: tempList.icon,
      );

      state = state.copyWith(
        lists: state.lists.map((l) => l.id == tempId ? createdList : l).toList(),
        error: null,
        pendingRetryId: null,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        error: e is ApiException ? e.message : 'Retry failed',
      );
      return false;
    }
  }

  Future<bool> updateList(
    String listId, {
    String? name,
    String? color,
    String? icon,
  }) async {
    final listIndex = state.lists.indexWhere((l) => l.id == listId);
    if (listIndex == -1) {
      state = state.copyWith(
        error: 'List not found',
      );
      return false;
    }

    final oldList = state.lists[listIndex];

    // Optimistic update
    final updatedList = oldList.copyWith(
      name: name ?? oldList.name,
      color: color ?? oldList.color,
      icon: icon ?? oldList.icon,
      updatedAt: DateTime.now(),
    );

    final optimisticLists = state.lists.toList();
    optimisticLists[listIndex] = updatedList;

    state = state.copyWith(
      lists: optimisticLists,
      error: null,
    );

    try {
      final updatedFromServer = await _repository.updateList(
        listId,
        name: name,
        color: color,
        icon: icon,
      );

      // Update with server response
      state = state.copyWith(
        lists: state.lists.map((l) => l.id == listId ? updatedFromServer : l).toList(),
      );

      return true;
    } catch (e) {
      // Rollback on error
      state = state.copyWith(
        lists: state.lists.map((l) => l.id == listId ? oldList : l).toList(),
        error: e is ApiException ? e.message : 'Failed to update list',
      );
      return false;
    }
  }

  Future<bool> deleteList(String listId) async {
    final listIndex = state.lists.indexWhere((l) => l.id == listId);
    if (listIndex == -1) {
      state = state.copyWith(error: 'List not found');
      return false;
    }

    final deletedList = state.lists[listIndex];

    // Optimistic removal
    state = state.copyWith(
      lists: state.lists.where((l) => l.id != listId).toList(),
      deletedList: deletedList,
      error: null,
    );

    try {
      await _repository.deleteList(listId);
      return true;
    } catch (e) {
      // Rollback - restore the deleted list
      state = state.copyWith(
        lists: [deletedList, ...state.lists],
        deletedList: null,
        error: e is ApiException ? e.message : 'Failed to delete list',
      );
      return false;
    }
  }

  void undoDeleteList() {
    final deletedList = state.deletedList;
    if (deletedList == null) return;

    state = state.copyWith(
      lists: [deletedList, ...state.lists],
      deletedList: null,
      error: null,
    );
  }

  void clearDeletedList() {
    state = state.copyWith(deletedList: null);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  Future<ShoppingList?> duplicateList(String listId, {String? name}) async {
    try {
      final duplicatedList = await _repository.duplicateList(listId, name: name);

      // Add the new list to the beginning of the list
      state = state.copyWith(
        lists: [duplicatedList, ...state.lists],
        error: null,
      );

      return duplicatedList;
    } catch (e) {
      state = state.copyWith(
        error: e is ApiException ? e.message : 'Failed to duplicate list',
      );
      return null;
    }
  }
}

final listsProvider = StateNotifierProvider<ListsNotifier, ListsState>((ref) {
  final repository = ref.watch(listRepositoryProvider);
  return ListsNotifier(repository);
});
