# Story 6.3: Anonymous Mode

## Description
Use app without account.

## Acceptance Criteria
- [ ] Skip signup option
- [ ] Data stored locally only
- [ ] Sharing disabled (requires account)
- [ ] Prompt to create account for sync
- [ ] Easy upgrade path (merge local → account)

## Technical Implementation

### Flutter Implementation

```dart
class AuthService {
  Future<void> enableAnonymousMode() async {
    await _secureStorage.setAnonymousMode(true);

    // Create local-only database
    await _localDatabase.initialize(anonymous: true);
  }

  bool get isAnonymous {
    return _secureStorage.isAnonymousMode();
  }
}

// Anonymous mode indicator in UI
class AnonymousModeIndicator extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAnonymous = ref.watch(authServiceProvider).isAnonymous;

    if (!isAnonymous) return SizedBox.shrink();

    return Banner(
      message: 'Anonymous Mode',
      location: BannerLocation.topEnd,
      color: Colors.orange,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Your Lists'),
          actions: [
            TextButton(
              onPressed: () => _showUpgradeDialog(context),
              child: Text('Create Account'),
            ),
          ],
        ),
        body: ListsScreen(),
      ),
    );
  }

  void _showUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create Account'),
        content: Text('Create an account to sync your lists across devices and share with others.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _upgradeToAccount();
            },
            child: Text('Create Account'),
          ),
        ],
      ),
    );
  }

  Future<void> _upgradeToAccount() async {
    // Navigate to signup
    // After signup, merge local data with account
    final localLists = await _localDatabase.getAllLists();
    final user = await _apiClient.getCurrentUser();

    // Upload all local lists as user's lists
    for (final list in localLists) {
      await _apiClient.createList(list.toJson());
    }
  }
}
```

## Dependencies
- Story 6.1 (User Registration)
- Story 1.1 (Create New List)

## Estimated Effort
4 story points
