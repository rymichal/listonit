import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/share_link_provider.dart';

class ShareLinkModal extends ConsumerStatefulWidget {
  final String listId;
  final String listName;

  const ShareLinkModal({
    super.key,
    required this.listId,
    required this.listName,
  });

  @override
  ConsumerState<ShareLinkModal> createState() => _ShareLinkModalState();
}

class _ShareLinkModalState extends ConsumerState<ShareLinkModal> {
  late String _selectedRole = 'editor';

  @override
  void initState() {
    super.initState();
    // Initialize selected role from share state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeShareLink();
    });
  }

  void _initializeShareLink() {
    final shareState = ref.read(shareLinksProvider);
    if (shareState.shareLink != null) {
      setState(() {
        _selectedRole = shareState.role;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final shareLinkState = ref.watch(shareLinksProvider);

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Share List',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (shareLinkState.error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    shareLinkState.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                )
              else if (shareLinkState.shareLink != null)
                _buildLinkSection(context, shareLinkState)
              else
                _buildCreateLinkSection(context, shareLinkState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLinkSection(BuildContext context, ShareLinkState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Share link active',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(
                state.shareLink!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: state.shareLink!),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Link copied to clipboard')),
                        );
                      },
                      child: const Text('Copy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.tonal(
                    onPressed: state.isLoading
                        ? null
                        : () async {
                      final success = await ref
                          .read(shareLinksProvider.notifier)
                          .regenerateShareLink(widget.listId);
                      if (mounted && success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Link regenerated')),
                        );
                      }
                    },
                    child: state.isLoading
                        ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    )
                        : const Text('Regenerate'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Access level',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outline),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: state.role,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            items: const [
              DropdownMenuItem(value: 'editor', child: Text('Can edit')),
              DropdownMenuItem(value: 'viewer', child: Text('Can view')),
            ],
            onChanged: null, // Read-only for now
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: state.isLoading
                ? null
                : () async {
              final success = await ref
                  .read(shareLinksProvider.notifier)
                  .revokeShareLink(widget.listId);
              if (mounted) {
                if (success) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Share link revoked')),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: state.isLoading
                ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(
                  Theme.of(context).colorScheme.onError,
                ),
              ),
            )
                : const Text('Revoke link'),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateLinkSection(BuildContext context, ShareLinkState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Access level',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outline),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: _selectedRole,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            items: const [
              DropdownMenuItem(value: 'editor', child: Text('Can edit')),
              DropdownMenuItem(value: 'viewer', child: Text('Can view')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedRole = value);
              }
            },
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Anyone with the link can ${_selectedRole == 'editor' ? 'edit' : 'view'} this list.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: state.isLoading
                ? null
                : () async {
              await ref
                  .read(shareLinksProvider.notifier)
                  .createShareLink(widget.listId, role: _selectedRole);
              // State updates automatically through Riverpod watch
            },
            child: state.isLoading
                ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(
                  Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            )
                : const Text('Create share link'),
          ),
        ),
      ],
    );
  }
}
