import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/connectivity_service.dart';
import '../sync/sync_notifier.dart';

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityState = ref.watch(connectivityProvider);
    final syncState = ref.watch(syncNotifierProvider);

    // Show banner if offline or if there are pending sync actions
    final isOffline = connectivityState.isOffline;
    final hasPending = syncState.pendingActions > 0;

    if (!isOffline && !hasPending) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: isOffline
          ? Colors.orange.shade700
          : Colors.blue.shade700,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Icon(
              isOffline ? Icons.cloud_off : Icons.cloud_queue,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isOffline ? 'Offline Mode' : 'Pending Changes',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  if (hasPending)
                    Text(
                      '${syncState.pendingActions} change${syncState.pendingActions == 1 ? '' : 's'} waiting to sync',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                      ),
                    )
                  else
                    Text(
                      'Changes will sync when online',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            if (!isOffline && hasPending)
              TextButton(
                onPressed: () {
                  ref.read(syncNotifierProvider.notifier).sync();
                },
                child: const Text(
                  'Sync Now',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
