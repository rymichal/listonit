import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../sync/sync_notifier.dart';

class SyncStatusIndicator extends ConsumerWidget {
  final double size;
  final bool showLabel;

  const SyncStatusIndicator({
    super.key,
    this.size = 24,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncNotifierProvider);

    Widget indicator;
    String? label;

    switch (syncState.status) {
      case SyncStatusEnum.idle:
        return const SizedBox.shrink();

      case SyncStatusEnum.syncing:
        indicator = SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        );
        label = 'Syncing...';

      case SyncStatusEnum.synced:
        indicator = Icon(
          Icons.cloud_done,
          size: size,
          color: Colors.green.shade600,
        );
        label = 'Synced';

      case SyncStatusEnum.error:
        indicator = Icon(
          Icons.cloud_off,
          size: size,
          color: Colors.red.shade600,
        );
        label = 'Sync failed';
    }

    if (!showLabel) {
      return indicator;
    }

    return Tooltip(
      message: label,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          indicator,
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}
