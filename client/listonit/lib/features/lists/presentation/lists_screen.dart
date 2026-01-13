import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../providers/lists_provider.dart';
import 'widgets/create_list_modal.dart';
import 'widgets/list_tile.dart';

class ListsScreen extends ConsumerStatefulWidget {
  const ListsScreen({super.key});

  @override
  ConsumerState<ListsScreen> createState() => _ListsScreenState();
}

class _ListsScreenState extends ConsumerState<ListsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(listsProvider.notifier).loadLists();
    });
  }

  Future<void> _showCreateListModal() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => const CreateListModal(),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('List created successfully!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showErrorSnackBar(String error, String? pendingRetryId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        behavior: SnackBarBehavior.floating,
        action: pendingRetryId != null
            ? SnackBarAction(
                label: 'Retry',
                onPressed: () {
                  ref.read(listsProvider.notifier).retryCreate(pendingRetryId);
                },
              )
            : null,
      ),
    );
    ref.read(listsProvider.notifier).clearError();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(listsProvider);

    ref.listen<ListsState>(listsProvider, (previous, next) {
      if (next.error != null && previous?.error != next.error) {
        _showErrorSnackBar(next.error!, next.pendingRetryId);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Lists'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              ref.read(authProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: _buildBody(state),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateListModal,
        tooltip: 'Create new list',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(ListsState state) {
    if (state.isLoading && state.lists.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.lists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No shopping lists yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to create your first list',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(listsProvider.notifier).loadLists(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.lists.length,
        itemBuilder: (context, index) {
          final list = state.lists[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ShoppingListTile(
              list: list,
              onTap: () {
                // TODO: Navigate to list detail screen
              },
            ),
          );
        },
      ),
    );
  }
}
