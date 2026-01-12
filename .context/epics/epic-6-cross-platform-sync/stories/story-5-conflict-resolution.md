# Story 6.5: Conflict Resolution

## Description
Handle sync conflicts gracefully.

## Acceptance Criteria
- [ ] Detect conflicts via updated_at comparison
- [ ] Non-conflicting fields: merge automatically
- [ ] Conflicting fields: last-write-wins
- [ ] Edge case: both users edit same item name → keep most recent
- [ ] Log conflicts for debugging

## Technical Implementation

### Conflict Resolution Strategy

```python
# Conflict detection and resolution
class ConflictResolver:
    """
    Conflict resolution using vector clocks and last-write-wins.

    Strategy:
    1. Compare timestamps for conflicting changes
    2. For non-conflicting fields, merge from both versions
    3. For conflicting fields, use last-write-wins
    4. Log all conflicts for debugging
    """

    @staticmethod
    def resolve_item_conflict(server_version, client_version, server_updated_at, client_updated_at):
        """
        Resolve conflict between server and client versions of an item.

        Args:
            server_version: Current state on server
            client_version: State being synced from client
            server_updated_at: Timestamp of last server update
            client_updated_at: Timestamp of last client update

        Returns:
            Resolved version of the item
        """

        # If client is older, keep server version
        if client_updated_at < server_updated_at:
            return server_version

        # If client is newer, apply client changes
        if client_updated_at > server_updated_at:
            return client_version

        # Same timestamp - use field-level resolution
        resolved = {}

        for field in ['name', 'quantity', 'unit', 'note']:
            server_val = server_version.get(field)
            client_val = client_version.get(field)

            if server_val == client_val:
                # No conflict
                resolved[field] = server_val
            else:
                # Conflict - prefer client (user's local change)
                # This encourages merging: if user made a change, respect it
                resolved[field] = client_val

        # Special handling for checked status
        # If either version has newer timestamp, use that
        if server_version.get('checked_at') and client_version.get('checked_at'):
            if server_version['checked_at'] > client_version['checked_at']:
                resolved['is_checked'] = server_version['is_checked']
            else:
                resolved['is_checked'] = client_version['is_checked']

        return resolved

    @staticmethod
    def log_conflict(item_id, server_version, client_version, resolution):
        """Log conflict for debugging and analysis"""
        logger.info(
            f"Conflict resolved for item {item_id}: "
            f"server={server_version}, client={client_version}, "
            f"resolved={resolution}"
        )
```

### FastAPI Sync Endpoint with Conflict Handling

```python
@router.post("/api/v1/sync/batch")
async def batch_sync(
    sync_data: BatchSyncRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Process batched offline changes with automatic conflict resolution.
    """

    results = {
        "created": [],
        "updated": [],
        "deleted": [],
        "conflicts": []
    }

    resolver = ConflictResolver()

    for action in sync_data.actions:
        try:
            if action.type == "update_item":
                item = db.query(Item).filter(Item.id == action.data["id"]).first()

                if not item:
                    results["conflicts"].append({
                        "id": action.data["id"],
                        "error": "Item deleted on server"
                    })
                    continue

                # Check for conflict
                if item.updated_at > action.client_updated_at:
                    # Conflict detected
                    resolved = resolver.resolve_item_conflict(
                        server_version=item.to_dict(),
                        client_version=action.data,
                        server_updated_at=item.updated_at,
                        client_updated_at=action.client_updated_at
                    )

                    # Apply resolved version
                    for key, value in resolved.items():
                        if key != "id":
                            setattr(item, key, value)

                    item.updated_at = datetime.utcnow()

                    results["conflicts"].append({
                        "id": str(item.id),
                        "resolved_version": item.to_dict()
                    })
                else:
                    # No conflict - apply changes
                    for key, value in action.data.items():
                        if key != "id":
                            setattr(item, key, value)

                    item.updated_at = datetime.utcnow()
                    results["updated"].append({"type": "item", "id": str(item.id)})

        except Exception as e:
            results["conflicts"].append({
                "error": str(e),
                "action": action.type
            })

    db.commit()
    return results
```

### Flutter Conflict Handling

```dart
class SyncConflictHandler {
  Future<void> handleConflicts(List<ConflictInfo> conflicts) async {
    for (final conflict in conflicts) {
      if (conflict.type == 'item') {
        // Auto-resolve: prefer server version for non-editable fields
        // but show notification to user
        _showConflictNotification(conflict);

        // Update local database with resolved version
        await _localDb.upsertItem(conflict.resolvedVersion);
      }
    }
  }

  void _showConflictNotification(ConflictInfo conflict) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sync conflict resolved for ${conflict.itemName}'),
        duration: Duration(seconds: 3),
      ),
    );
  }
}
```

## Dependencies
- Story 6.4 (Offline Support)

## Estimated Effort
6 story points
