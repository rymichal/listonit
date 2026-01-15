import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/item.dart';
import '../../providers/items_provider.dart';
import '../../providers/show_checked_items_provider.dart';
import 'selectable_item_tile.dart';

class CheckedItemsSection extends ConsumerWidget {
  final String listId;
  final List<Item> checkedItems;
  final Color accentColor;

  const CheckedItemsSection({
    super.key,
    required this.listId,
    required this.checkedItems,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showChecked = ref.watch(showCheckedItemsProvider);

    if (checkedItems.isEmpty) {
      return const SizedBox.shrink();
    }

    // Collapsed state
    if (!showChecked) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Card(
          margin: const EdgeInsets.only(top: 16, bottom: 16),
          child: ListTile(
            leading: const Icon(Icons.check_circle_outline),
            title: Text(
              '${checkedItems.length} completed ${checkedItems.length == 1 ? 'item' : 'items'}',
            ),
            trailing: const Icon(Icons.expand_more),
            onTap: () {
              ref.read(showCheckedItemsProvider.notifier).toggle();
            },
          ),
        ),
      );
    }

    // Expanded state
    return Column(
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: accentColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Completed (${checkedItems.length})',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.expand_less),
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  ref.read(showCheckedItemsProvider.notifier).toggle();
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tap to restore',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              TextButton(
                onPressed: () {
                  _showClearConfirmation(context, ref);
                },
                child: const Text('Clear all'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: checkedItems
                .map((item) => SelectableItemTile(
                      key: ValueKey(item.id),
                      item: item,
                      listId: listId,
                      accentColor: accentColor,
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _showClearConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear completed items?'),
        content: const Text(
          'This will delete all completed items. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(itemsProvider(listId).notifier)
                  .clearCheckedItems()
                  .then((_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Deleted ${checkedItems.length} item${checkedItems.length == 1 ? '' : 's'}'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              });
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
