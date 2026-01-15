import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/list_api.dart';
import '../../providers/members_provider.dart';
import '../../../auth/data/user_api.dart';
import '../../../auth/domain/user.dart';

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
  String? _selectedUserId;
  String _selectedRole = 'editor';
  String _searchQuery = '';
  bool _isAddingMember = false;

  @override
  Widget build(BuildContext context) {
    final usersAsyncValue = ref.watch(
      userSearchProvider(_searchQuery),
    );
    final membersState = ref.watch(membersProvider(widget.listId));

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
                    'Add Member',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Select a user to add',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 12),
              TextField(
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
                decoration: InputDecoration(
                  hintText: 'Search users by name...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              usersAsyncValue.when(
                data: (users) {
                  final memberIds = {for (var m in membersState.members) m.id};
                  final availableUsers = users
                      .where((u) => !memberIds.contains(u.id))
                      .toList();

                  if (availableUsers.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        _searchQuery.isEmpty
                            ? 'No available users'
                            : 'No users found matching your search',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    );
                  }

                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedUserId,
                      isExpanded: true,
                      underline: const SizedBox.shrink(),
                      hint: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('Choose a user'),
                      ),
                      items: availableUsers
                          .map(
                            (user) => DropdownMenuItem(
                              value: user.id,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(user.name),
                                    Text(
                                      user.username,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedUserId = value);
                      },
                    ),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: CircularProgressIndicator(),
                ),
                error: (error, stack) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Error loading users: $error',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
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
                'User can ${_selectedRole == 'editor' ? 'edit' : 'view'} the list',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: (_selectedUserId == null || _isAddingMember)
                      ? null
                      : () async {
                          setState(() => _isAddingMember = true);
                          try {
                            final listApi = ref.read(listApiProvider);
                            await listApi.addMember(
                              widget.listId,
                              _selectedUserId!,
                              _selectedRole,
                            );

                            if (mounted) {
                              // Refresh members list
                              ref.invalidate(membersProvider(widget.listId));
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Member added')),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() => _isAddingMember = false);
                            }
                          }
                        },
                  child: _isAddingMember
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
                      : const Text('Add Member'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final userSearchProvider = FutureProvider.family<List<User>, String>(
  (ref, query) async {
    final userApi = ref.watch(userApiProvider);
    return userApi.searchUsers(query: query);
  },
);
