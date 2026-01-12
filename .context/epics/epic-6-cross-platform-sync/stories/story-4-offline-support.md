# Story 6.4: Offline Support

## Description
Full functionality without internet.

## Acceptance Criteria
- [ ] All CRUD operations work offline
- [ ] Data stored in local SQLite
- [ ] Queue changes for sync
- [ ] Visual indicator: "Offline mode"
- [ ] Sync automatically on reconnect

## Technical Implementation

### Flutter Sync Queue

```dart
// Sync queue implementation
class SyncQueue {
  final _box = Hive.box<SyncAction>('sync_queue');

  Future<void> enqueue(SyncActionType type, dynamic payload) async {
    final action = SyncAction(
      id: uuid.v4(),
      type: type,
      payload: jsonEncode(payload),
      createdAt: DateTime.now(),
      attempts: 0,
    );
    await _box.put(action.id, action);
  }

  Future<void> processQueue() async {
    final actions = _box.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    for (final action in actions) {
      try {
        await _executeAction(action);
        await _box.delete(action.id);
      } catch (e) {
        action.attempts++;
        if (action.attempts >= 5) {
          // Move to dead letter queue
          await _deadLetterQueue.add(action);
          await _box.delete(action.id);
        } else {
          await _box.put(action.id, action);
        }
      }
    }
  }

  Future<void> _executeAction(SyncAction action) async {
    switch (action.type) {
      case SyncActionType.createList:
        final list = ShoppingList.fromJson(jsonDecode(action.payload));
        await _apiClient.createList(list);
        break;
      case SyncActionType.createItem:
        final item = Item.fromJson(jsonDecode(action.payload));
        await _apiClient.createItem(item);
        break;
      // ... more action types
    }
  }
}

// Connectivity monitoring
class ConnectivityService extends ChangeNotifier {
  bool _isConnected = true;
  late StreamSubscription _subscription;

  bool get isConnected => _isConnected;
  bool get isOffline => !_isConnected;

  void initialize() {
    _subscription = Connectivity()
        .onConnectivityChanged
        .listen((result) {
      _isConnected = result != ConnectivityResult.none;

      if (_isConnected) {
        // Sync when connectivity returns
        _syncQueue.processQueue();
      }

      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

// Offline indicator widget
class OfflineBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOffline = ref.watch(connectivityProvider).isOffline;

    if (!isOffline) return SizedBox.shrink();

    return Container(
      color: Colors.orange.shade700,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(Icons.cloud_off, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Offline Mode - Changes will sync when online',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
```

### FastAPI Batch Sync Endpoint

```python
@router.post("/api/v1/sync/batch")
async def batch_sync(
    sync_data: BatchSyncRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Process batched offline changes"""

    results = {
        "created": [],
        "updated": [],
        "deleted": [],
        "conflicts": []
    }

    for action in sync_data.actions:
        try:
            if action.type == "create_list":
                lst = List(**action.data, owner_id=current_user.id)
                db.add(lst)
                db.flush()
                results["created"].append({"type": "list", "id": str(lst.id)})

            elif action.type == "create_item":
                item = Item(**action.data, created_by=current_user.id)
                db.add(item)
                db.flush()
                results["created"].append({"type": "item", "id": str(item.id)})

            elif action.type == "update_item":
                item = db.query(Item).filter(Item.id == action.data["id"]).first()
                if item.updated_at > action.client_updated_at:
                    # Conflict
                    results["conflicts"].append({"id": str(item.id), "server_version": item.to_dict()})
                else:
                    # Merge
                    for key, value in action.data.items():
                        if key != "id":
                            setattr(item, key, value)
                    results["updated"].append({"type": "item", "id": str(item.id)})

            elif action.type == "delete_item":
                db.query(Item).filter(Item.id == action.data["id"]).delete()
                results["deleted"].append({"type": "item", "id": action.data["id"]})

        except Exception as e:
            results["conflicts"].append({"error": str(e)})

    db.commit()
    return results
```

## Dependencies
- Story 2.1 (Add Item - Quick Mode)
- Story 1.1 (Create New List)

## Estimated Effort
7 story points
