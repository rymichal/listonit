import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/presence_provider.dart';
import '../../../../core/websocket/websocket_connection_provider.dart' as ws;

class SyncStatusIndicator extends ConsumerWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(ws.websocketConnectionProvider);
    final presenceState = ref.watch(presenceProvider);

    return AnimatedOpacity(
      opacity: connectionState.status == ws.ConnectionStatus.idle ? 0 : 1,
      duration: const Duration(milliseconds: 300),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusBar(context, connectionState),
            if (presenceState.userCount > 0)
              _buildActiveUsersBar(context, presenceState),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar(BuildContext context, ws.ConnectionState connectionState) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _getStatusColor(connectionState.status, colorScheme).withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getStatusColor(connectionState.status, colorScheme).withAlpha(50),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatusIcon(connectionState.status),
          const SizedBox(width: 8),
          Text(
            _getStatusText(connectionState.status),
            style: theme.textTheme.bodySmall?.copyWith(
              color: _getStatusColor(connectionState.status, colorScheme),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveUsersBar(BuildContext context, PresenceState presenceState) {
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
              '${presenceState.userCount} online',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            if (presenceState.userCount <= 3) ...[
              const SizedBox(width: 6),
              Text(
                presenceState.userNames.join(', '),
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

  Widget _buildStatusIcon(ws.ConnectionStatus status) {
    switch (status) {
      case ws.ConnectionStatus.idle:
        return const SizedBox.shrink();
      case ws.ConnectionStatus.connecting:
      case ws.ConnectionStatus.reconnecting:
        return SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade600),
          ),
        );
      case ws.ConnectionStatus.connected:
        return Icon(
          Icons.cloud_done,
          size: 14,
          color: Colors.green.shade600,
        );
      case ws.ConnectionStatus.disconnected:
        return Icon(
          Icons.cloud_off,
          size: 14,
          color: Colors.grey.shade600,
        );
      case ws.ConnectionStatus.error:
        return Icon(
          Icons.cloud_off,
          size: 14,
          color: Colors.red.shade600,
        );
    }
  }

  String _getStatusText(ws.ConnectionStatus status) {
    switch (status) {
      case ws.ConnectionStatus.idle:
        return '';
      case ws.ConnectionStatus.connecting:
        return 'Syncing...';
      case ws.ConnectionStatus.reconnecting:
        return 'Reconnecting...';
      case ws.ConnectionStatus.connected:
        return 'Synced';
      case ws.ConnectionStatus.disconnected:
        return 'Offline';
      case ws.ConnectionStatus.error:
        return 'Sync error';
    }
  }

  Color _getStatusColor(ws.ConnectionStatus status, ColorScheme colorScheme) {
    switch (status) {
      case ws.ConnectionStatus.idle:
        return Colors.transparent;
      case ws.ConnectionStatus.connecting:
      case ws.ConnectionStatus.reconnecting:
        return Colors.orange;
      case ws.ConnectionStatus.connected:
        return Colors.green;
      case ws.ConnectionStatus.disconnected:
        return Colors.grey;
      case ws.ConnectionStatus.error:
        return colorScheme.error;
    }
  }
}
