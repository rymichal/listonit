import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/icons.dart';
import '../../items/domain/item.dart';
import '../../items/domain/sort_mode.dart';
import '../../items/presentation/widgets/add_item_form.dart';
import '../../items/presentation/widgets/checked_items_section.dart';
import '../../items/presentation/widgets/selectable_item_tile.dart';
import '../../items/providers/item_selection_provider.dart';
import '../../items/providers/items_provider.dart';
import '../../items/providers/sort_preferences.dart';
import '../domain/shopping_list.dart';
import '../providers/lists_provider.dart';
import '../providers/sync_provider.dart';
import '../services/list_websocket_service.dart';
import 'widgets/edit_list_modal.dart';
import 'widgets/share_link_modal.dart';
import 'widgets/members_modal.dart';
import 'widgets/sync_status_indicator.dart';
import '../../auth/providers/auth_provider.dart';

class ListDetailScreen extends ConsumerStatefulWidget {
  final ShoppingList list;

  const ListDetailScreen({
    super.key,
    required this.list,
  });

  @override
  ConsumerState<ListDetailScreen> createState() => _ListDetailScreenState();
}

class _ListDetailScreenState extends ConsumerState<ListDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Load items and connect sync when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final itemsNotifier = ref.read(itemsProvider(widget.list.id).notifier);
      itemsNotifier.loadItems();

      // Initialize sort mode from list
      itemsNotifier.initializeSortMode(
        widget.list.sortMode,
        true, // Will be overridden by saved preference if available
      );

      // Load sort direction preference
      _loadSortPreference();
      _connectSync();
    });
  }

  Future<void> _loadSortPreference() async {
    try {
      final sortPrefs = await ref.read(sortPreferencesProvider.future);
      final ascending = sortPrefs.getSortAscending(widget.list.id);
      if (mounted) {
        ref.read(itemsProvider(widget.list.id).notifier).setSortAscending(ascending);
      }
    } catch (e) {
      debugPrint('Failed to load sort preference: $e');
    }
  }

  Future<void> _connectSync() async {
    final authState = ref.read(authProvider);
    if (authState.isAuthenticated) {
      // Get token from secure storage
      try {
        final tokenStorage = ref.read(tokenStorageProvider);
        final token = await tokenStorage.getAccessToken();
        if (token != null && mounted) {
          await ref.read(syncProvider.notifier).connectToList(
                widget.list.id,
                token,
              );
          // Setup listener for reorder events
          _setupSyncListeners();
        }
      } catch (e) {
        debugPrint('Failed to get token for sync: $e');
      }
    }
  }

  void _setupSyncListeners() {
    listWebSocketService.addListener(_handleSyncMessage);
  }

  void _handleSyncMessage(SyncMessage message) {
    if (message.type == 'items_reordered') {
      final itemsNotifier = ref.read(itemsProvider(widget.list.id).notifier);
      final items = message.data['items'] as List?;
      if (items != null) {
        final reorderedData = items
            .map((item) => {
              'id': item['id'] as String,
              'sort_index': item['sort_index'] as int,
            })
            .toList();
        itemsNotifier.applyReorderFromServer(reorderedData);
      }
    }
  }

  @override
  void dispose() {
    try {
      if (mounted) {
        ref.read(syncProvider.notifier).disconnect();
        listWebSocketService.removeListener(_handleSyncMessage);
      }
    } catch (_) {
      // Safely ignore errors during dispose
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listColor = ListColors.fromHex(widget.list.color);
    final listIcon = ListIcons.getIcon(widget.list.icon);
    final itemsState = ref.watch(itemsProvider(widget.list.id));
    final selectionState = ref.watch(itemSelectionProvider);
    final isSelectionMode = selectionState.isSelectionMode &&
        selectionState.listId == widget.list.id;

    return PopScope(
      canPop: !isSelectionMode,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && isSelectionMode) {
          ref.read(itemSelectionProvider.notifier).exitSelectionMode();
        }
      },
      child: Scaffold(
        appBar: isSelectionMode
            ? _buildSelectionAppBar(context, selectionState, listColor, itemsState)
            : _buildNormalAppBar(context, listColor, listIcon),
        body: Column(
          children: [
            const SyncStatusIndicator(),
            if (!isSelectionMode)
              AddItemForm(
                listId: widget.list.id,
                accentColor: listColor,
              ),
            Expanded(
              child: _buildItemsContent(context, itemsState, listColor),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildNormalAppBar(
    BuildContext context,
    Color listColor,
    IconData listIcon,
  ) {
    return AppBar(
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: listColor.withAlpha(51),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              listIcon,
              color: listColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.list.name,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {
            _showOptionsMenu(context);
          },
        ),
      ],
    );
  }

  PreferredSizeWidget _buildSelectionAppBar(
    BuildContext context,
    ItemSelectionState selectionState,
    Color listColor,
    ItemsState itemsState,
  ) {
    final selectedCount = selectionState.selectedCount;
    final totalCount = itemsState.items.length;

    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () {
          ref.read(itemSelectionProvider.notifier).exitSelectionMode();
        },
      ),
      title: Text('$selectedCount selected'),
      actions: [
        // Select All / Deselect All
        IconButton(
          icon: Icon(
            selectedCount == totalCount
                ? Icons.deselect
                : Icons.select_all,
          ),
          tooltip: selectedCount == totalCount ? 'Deselect all' : 'Select all',
          onPressed: () {
            if (selectedCount == totalCount) {
              ref.read(itemSelectionProvider.notifier).deselectAll();
            } else {
              ref.read(itemSelectionProvider.notifier).selectAll(
                    itemsState.items.map((i) => i.id).toList(),
                  );
            }
          },
        ),
        // Check All Selected
        IconButton(
          icon: const Icon(Icons.check_circle_outline),
          tooltip: 'Check selected',
          onPressed: () => _batchCheckSelected(true),
        ),
        // Uncheck All Selected
        IconButton(
          icon: const Icon(Icons.radio_button_unchecked),
          tooltip: 'Uncheck selected',
          onPressed: () => _batchCheckSelected(false),
        ),
        // Delete Selected
        IconButton(
          icon: Icon(
            Icons.delete_outline,
            color: Theme.of(context).colorScheme.error,
          ),
          tooltip: 'Delete selected',
          onPressed: () => _batchDeleteSelected(selectedCount),
        ),
      ],
    );
  }

  Future<void> _batchCheckSelected(bool checked) async {
    final selectedIds =
        ref.read(itemSelectionProvider).selectedIds.toList();
    if (selectedIds.isEmpty) return;

    await ref
        .read(itemsProvider(widget.list.id).notifier)
        .batchCheckItems(selectedIds, checked);

    ref.read(itemSelectionProvider.notifier).exitSelectionMode();
  }

  Future<void> _batchDeleteSelected(int count) async {
    final selectedIds =
        ref.read(itemSelectionProvider).selectedIds.toList();
    if (selectedIds.isEmpty) return;

    // Confirmation for bulk delete (>3 items)
    if (count > 3) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete items?'),
          content: Text('Are you sure you want to delete $count items?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    await ref
        .read(itemsProvider(widget.list.id).notifier)
        .batchDeleteItems(selectedIds);

    ref.read(itemSelectionProvider.notifier).exitSelectionMode();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted $count items'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildItemsContent(
    BuildContext context,
    ItemsState itemsState,
    Color listColor,
  ) {
    if (itemsState.isLoading && itemsState.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (itemsState.items.isEmpty) {
      return _buildEmptyState(context, listColor);
    }

    final sortedItems = itemsState.getSortedItems();
    final uncheckedItems = sortedItems.where((i) => !i.isChecked).toList();
    final checkedItems = sortedItems.where((i) => i.isChecked).toList();

    final isCustomSort = itemsState.sortMode == SortMode.custom;
    final selectionState = ref.watch(itemSelectionProvider);
    final isSelectionMode = selectionState.isSelectionMode &&
        selectionState.listId == widget.list.id;

    // Use ReorderableListView for custom sort mode (and not in selection mode)
    if (isCustomSort && !isSelectionMode) {
      return _buildReorderableContent(context, uncheckedItems, checkedItems, listColor);
    }

    // Use regular ListView for other modes
    return _buildRegularContent(context, uncheckedItems, checkedItems, listColor);
  }

  Widget _buildReorderableContent(
    BuildContext context,
    List<Item> uncheckedItems,
    List<Item> checkedItems,
    Color listColor,
  ) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        ReorderableListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          buildDefaultDragHandles: false,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: uncheckedItems.length,
          onReorder: (oldIndex, newIndex) {
            ref.read(itemsProvider(widget.list.id).notifier).reorderItems(oldIndex, newIndex);
          },
          itemBuilder: (context, index) {
            final item = uncheckedItems[index];
            return SelectableItemTile(
              key: ValueKey(item.id),
              item: item,
              listId: widget.list.id,
              accentColor: listColor,
              showDragHandle: true,
              dragHandleIndex: index,
            );
          },
        ),
        CheckedItemsSection(
          listId: widget.list.id,
          checkedItems: checkedItems,
          accentColor: listColor,
        ),
      ],
    );
  }

  Widget _buildRegularContent(
    BuildContext context,
    List<Item> uncheckedItems,
    List<Item> checkedItems,
    Color listColor,
  ) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: uncheckedItems
                .map((item) => SelectableItemTile(
                      key: Key(item.id),
                      item: item,
                      listId: widget.list.id,
                      accentColor: listColor,
                    ))
                .toList(),
          ),
        ),
        CheckedItemsSection(
          listId: widget.list.id,
          checkedItems: checkedItems,
          accentColor: listColor,
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, Color listColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.checklist,
            size: 80,
            color: listColor.withAlpha(100),
          ),
          const SizedBox(height: 16),
          Text(
            'No items yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first item above',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit list'),
              onTap: () {
                Navigator.pop(context);
                _showEditModal(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Duplicate list'),
              onTap: () {
                Navigator.pop(context);
                _duplicateList(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share list'),
              onTap: () {
                Navigator.pop(context);
                _showShareModal(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Members'),
              onTap: () {
                Navigator.pop(context);
                _showMembersModal(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.sort),
              title: const Text('Sort items'),
              onTap: () {
                Navigator.pop(context);
                _showSortMenu(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_sweep),
              title: const Text('Clear completed'),
              onTap: () {
                Navigator.pop(context);
                _clearCompleted();
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Delete list',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _clearCompleted() async {
    await ref.read(itemsProvider(widget.list.id).notifier).clearCheckedItems();
  }

  void _showEditModal(BuildContext context) {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => EditListModal(list: widget.list),
    );
  }

  void _showShareModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => ShareLinkModal(
        listId: widget.list.id,
        listName: widget.list.name,
      ),
    );
  }

  void _showMembersModal(BuildContext context) {
    final authState = ref.read(authProvider);
    if (authState.user != null) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (context) => MembersModal(
          listId: widget.list.id,
          currentUserId: authState.user!.id,
          listOwnerId: widget.list.ownerId,
        ),
      );
    }
  }

  void _showSortMenu(BuildContext context) {
    final itemsState = ref.read(itemsProvider(widget.list.id));
    final currentSortMode = itemsState.sortMode;
    final currentAscending = itemsState.sortAscending;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Sort items',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.sort_by_alpha),
              title: const Text('Alphabetical (A-Z)'),
              trailing: currentSortMode == SortMode.alphabetical && currentAscending
                  ? const Icon(Icons.check)
                  : null,
              onTap: () {
                _updateSort(SortMode.alphabetical, true);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.sort_by_alpha),
              title: const Text('Alphabetical (Z-A)'),
              trailing: currentSortMode == SortMode.alphabetical && !currentAscending
                  ? const Icon(Icons.check)
                  : null,
              onTap: () {
                _updateSort(SortMode.alphabetical, false);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Newest First'),
              trailing: currentSortMode == SortMode.chronological && currentAscending
                  ? const Icon(Icons.check)
                  : null,
              onTap: () {
                _updateSort(SortMode.chronological, true);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.drag_handle),
              title: const Text('Custom Order'),
              subtitle: const Text('Drag to reorder'),
              trailing: currentSortMode == SortMode.custom
                  ? const Icon(Icons.check)
                  : null,
              onTap: () {
                _updateSort(SortMode.custom, true);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateSort(SortMode sortMode, bool ascending) async {
    final listId = widget.list.id;

    // Update items provider sort mode
    ref.read(itemsProvider(listId).notifier).setSortMode(sortMode);
    ref.read(itemsProvider(listId).notifier).setSortAscending(ascending);

    // Save sort direction preference locally
    try {
      final sortPrefs = await ref.read(sortPreferencesProvider.future);
      await sortPrefs.setSortAscending(listId, ascending);
    } catch (e) {
      debugPrint('Failed to save sort preference: $e');
    }

    // Update list sort mode on backend if it changed
    if (widget.list.sortMode != sortMode.toString()) {
      try {
        await ref.read(listsProvider.notifier).updateListSortMode(
          listId,
          sortMode.toString(),
        );
      } catch (e) {
        debugPrint('Failed to update sort mode on backend: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update sort: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete list?'),
        content: Text(
          'Are you sure you want to delete "${widget.list.name}"? This will remove the list for all members.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);

              final success = await ref.read(listsProvider.notifier).deleteList(widget.list.id);

              if (mounted && success) {
                Navigator.pop(context);
                _showUndoSnackbar(context);
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showUndoSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('List "${widget.list.name}" deleted'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            ref.read(listsProvider.notifier).undoDeleteList();
          },
        ),
      ),
    );
  }

  Future<void> _duplicateList(BuildContext context) async {
    final duplicatedList = await ref.read(listsProvider.notifier).duplicateList(widget.list.id);

    if (!mounted) return;

    if (duplicatedList != null) {
      // Pop current screen and navigate to the new duplicated list
      Navigator.pushReplacement(
        this.context,
        MaterialPageRoute(
          builder: (ctx) => ListDetailScreen(list: duplicatedList),
        ),
      );

      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(
          content: Text('Created "${duplicatedList.name}"'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      final error = ref.read(listsProvider).error;
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Failed to duplicate list'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(this.context).colorScheme.error,
        ),
      );
    }
  }
}
