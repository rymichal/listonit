import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/icons.dart';
import '../../items/presentation/widgets/add_item_form.dart';
import '../../items/presentation/widgets/selectable_item_tile.dart';
import '../../items/providers/item_selection_provider.dart';
import '../../items/providers/items_provider.dart';
import '../domain/shopping_list.dart';
import '../providers/lists_provider.dart';
import 'widgets/edit_list_modal.dart';

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
    // Load items when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(itemsProvider(widget.list.id).notifier).loadItems();
    });
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

    final uncheckedItems = itemsState.uncheckedItems;
    final checkedItems = itemsState.checkedItems;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        ...uncheckedItems.map((item) => SelectableItemTile(
              key: Key(item.id),
              item: item,
              listId: widget.list.id,
              accentColor: listColor,
            )),
        if (checkedItems.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Completed (${checkedItems.length})',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          ...checkedItems.map((item) => SelectableItemTile(
                key: Key(item.id),
                item: item,
                listId: widget.list.id,
                accentColor: listColor,
              )),
        ],
        const SizedBox(height: 16),
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
                // TODO: Implement share list
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
