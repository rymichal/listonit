import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/sync_provider.dart';

class SyncStatusIndicator extends ConsumerWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncProvider);

    return AnimatedOpacity(
      opacity: syncState.status == SyncStatus.idle ? 0 : 1,
      duration: const Duration(milliseconds: 300),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusBar(context, syncState),
            if (syncState.activeUsers.isNotEmpty)
              _buildActiveUsersBar(context, syncState),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar(BuildContext context, SyncState syncState) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _getStatusColor(syncState.status, colorScheme).withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getStatusColor(syncState.status, colorScheme).withAlpha(50),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatusIcon(syncState.status),
          const SizedBox(width: 8),
          Text(
            _getStatusText(syncState.status),
            style: theme.textTheme.bodySmall?.copyWith(
              color: _getStatusColor(syncState.status, colorScheme),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveUsersBar(BuildContext context, SyncState syncState) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withAlpha(12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people,
              size: 14,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              '${syncState.activeUsers.length} online',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            if (syncState.activeUsers.length <= 3) ...[
              const SizedBox(width: 6),
              Text(
                syncState.activeUsers.join(', '),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(SyncStatus status) {
    switch (status) {
      case SyncStatus.idle:
        return const SizedBox.shrink();
      case SyncStatus.connecting:
        return SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade600),
          ),
        );
      case SyncStatus.connected:
        return Icon(
          Icons.cloud_done,
          size: 14,
          color: Colors.green.shade600,
        );
      case SyncStatus.disconnected:
        return Icon(
          Icons.cloud_off,
          size: 14,
          color: Colors.grey.shade600,
        );
      case SyncStatus.error:
        return Icon(
          Icons.cloud_off,
          size: 14,
          color: Colors.red.shade600,
        );
    }
  }

  String _getStatusText(SyncStatus status) {
    switch (status) {
      case SyncStatus.idle:
        return '';
      case SyncStatus.connecting:
        return 'Syncing...';
      case SyncStatus.connected:
        return 'Synced';
      case SyncStatus.disconnected:
        return 'Offline';
      case SyncStatus.error:
        return 'Sync error';
    }
  }

  Color _getStatusColor(SyncStatus status, ColorScheme colorScheme) {
    switch (status) {
      case SyncStatus.idle:
        return Colors.transparent;
      case SyncStatus.connecting:
        return Colors.orange;
      case SyncStatus.connected:
        return Colors.green;
      case SyncStatus.disconnected:
        return Colors.grey;
      case SyncStatus.error:
        return colorScheme.error;
    }
  }
}
