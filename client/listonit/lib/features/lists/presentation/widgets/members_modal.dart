import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/list_member.dart';
import '../../providers/members_provider.dart';

class MembersModal extends ConsumerStatefulWidget {
  final String listId;
  final String currentUserId;
  final String listOwnerId;

  const MembersModal({
    super.key,
    required this.listId,
    required this.currentUserId,
    required this.listOwnerId,
  });

  @override
  ConsumerState<MembersModal> createState() => _MembersModalState();
}

class _MembersModalState extends ConsumerState<MembersModal> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(membersProvider(widget.listId).notifier).loadMembers(widget.listId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final membersState = ref.watch(membersProvider(widget.listId));

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Members',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          if (membersState.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  membersState.error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ),
          Expanded(
            child: membersState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: membersState.members.length,
                    itemBuilder: (context, index) {
                      final member = membersState.members[index];
                      return _MemberTile(
                        member: member,
                        isOwner: widget.listOwnerId == member.id,
                        isCurrentUser: widget.currentUserId == member.id,
                        canManage: widget.currentUserId == widget.listOwnerId,
                        listId: widget.listId,
                        onRemoved: () {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Member removed')),
                            );
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _MemberTile extends ConsumerWidget {
  final ListMember member;
  final bool isOwner;
  final bool isCurrentUser;
  final bool canManage;
  final String listId;
  final VoidCallback onRemoved;

  const _MemberTile({
    required this.member,
    required this.isOwner,
    required this.isCurrentUser,
    required this.canManage,
    required this.listId,
    required this.onRemoved,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(member.name.isNotEmpty ? member.name[0].toUpperCase() : '?'),
      ),
      title: Text(member.name),
      subtitle: Text(
        isOwner ? 'Owner' : member.role.toUpperCase(),
        style: TextStyle(
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
      trailing: canManage && !isOwner
          ? PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'change_role') {
                  await _showRoleChangeDialog(context, ref);
                } else if (value == 'remove') {
                  await _removeConfirm(context, ref);
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem(
                  value: 'change_role',
                  child: Text('Change role'),
                ),
                const PopupMenuItem(
                  value: 'remove',
                  child: Text('Remove member'),
                ),
              ],
            )
          : isCurrentUser && !isOwner
              ? PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'leave') {
                      await _leaveConfirm(context, ref);
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem(
                      value: 'leave',
                      child: Text('Leave list'),
                    ),
                  ],
                )
              : null,
    );
  }

  Future<void> _showRoleChangeDialog(BuildContext context, WidgetRef ref) async {
    final currentRole = member.role;
    String? selectedRole = currentRole;

    final newRole = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Change role'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('Can edit'),
                value: 'editor',
                groupValue: selectedRole,
                onChanged: (value) {
                  setState(() => selectedRole = value);
                },
              ),
              RadioListTile<String>(
                title: const Text('Can view'),
                value: 'viewer',
                groupValue: selectedRole,
                onChanged: (value) {
                  setState(() => selectedRole = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, selectedRole),
              child: const Text('Change'),
            ),
          ],
        ),
      ),
    );

    if (newRole != null && newRole != currentRole) {
      final success = await ref
          .read(membersProvider(listId).notifier)
          .updateMemberRole(listId, member.id, newRole);

      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Member role updated')),
          );
        } else {
          final error = ref.read(membersProvider(listId)).error;
          if (error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error)),
            );
          }
        }
      }
    }
  }

  Future<void> _removeConfirm(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove member?'),
        content: Text('Remove ${member.name} from this list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(membersProvider(listId).notifier)
          .removeMember(listId, member.id);

      if (context.mounted) {
        if (success) {
          onRemoved();
        } else {
          final error = ref.read(membersProvider(listId)).error;
          if (error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error)),
            );
          }
        }
      }
    }
  }

  Future<void> _leaveConfirm(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave list?'),
        content: const Text('Are you sure you want to leave this list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(membersProvider(listId).notifier)
          .removeMember(listId, member.id);

      if (context.mounted) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You left the list')),
          );
        } else {
          final error = ref.read(membersProvider(listId)).error;
          if (error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error)),
            );
          }
        }
      }
    }
  }
}
