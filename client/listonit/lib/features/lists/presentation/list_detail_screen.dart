import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/icons.dart';
import '../../items/domain/item.dart';
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
  final _itemController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Load items when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(itemsProvider(widget.list.id).notifier).loadItems();
    });
  }

  @override
  void dispose() {
    _itemController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _addItem() async {
    final text = _itemController.text.trim();
    if (text.isEmpty) return;

    _itemController.clear();
    _focusNode.requestFocus();

    // Support comma-separated batch add
    await ref.read(itemsProvider(widget.list.id).notifier).addItemsBatch(text);
  }

  Future<void> _toggleItem(String id) async {
    await ref.read(itemsProvider(widget.list.id).notifier).toggleItem(id);
  }

  Future<void> _deleteItem(String id) async {
    await ref.read(itemsProvider(widget.list.id).notifier).deleteItem(id);
  }

  @override
  Widget build(BuildContext context) {
    final listColor = ListColors.fromHex(widget.list.color);
    final listIcon = ListIcons.getIcon(widget.list.icon);
    final itemsState = ref.watch(itemsProvider(widget.list.id));

    return Scaffold(
      appBar: AppBar(
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
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _itemController,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: 'Add an item... (use commas for multiple)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _addItem(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _addItem,
                  style: FilledButton.styleFrom(
                    backgroundColor: listColor,
                    padding: const EdgeInsets.all(12),
                    minimumSize: const Size(48, 48),
                  ),
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildItemsContent(context, itemsState, listColor),
          ),
        ],
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
        ...uncheckedItems.map((item) => _buildItemTile(item, listColor)),
        if (checkedItems.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Completed (${checkedItems.length})',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          ...checkedItems.map((item) => _buildItemTile(item, listColor)),
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

  Widget _buildItemTile(Item item, Color listColor) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Theme.of(context).colorScheme.error,
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      onDismissed: (_) => _deleteItem(item.id),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Checkbox(
            value: item.isChecked,
            onChanged: (_) => _toggleItem(item.id),
            activeColor: listColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          title: Text(
            item.name,
            style: TextStyle(
              decoration: item.isChecked ? TextDecoration.lineThrough : null,
              color: item.isChecked
                  ? Theme.of(context).colorScheme.onSurfaceVariant
                  : null,
            ),
          ),
          subtitle: item.quantity > 1
              ? Text(
                  'Qty: ${item.quantity}${item.unit != null ? ' ${item.unit}' : ''}',
                  style: Theme.of(context).textTheme.bodySmall,
                )
              : null,
          onTap: () => _toggleItem(item.id),
        ),
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
