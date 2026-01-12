# Story 5.4: Undo/Redo Support

## Description
Recover from accidental actions.

## Acceptance Criteria
- [ ] Undo snackbar after: delete item, check item, clear checked
- [ ] "Undo" button visible for 5 seconds
- [ ] Multiple undo levels (last 10 actions)
- [ ] Works offline (undo local state)
- [ ] Sync undo actions when online

## Technical Implementation

### Flutter Implementation

```dart
// Action history for undo
class UndoManager {
  final _history = Queue<UndoableAction>();
  static const maxHistory = 10;

  void record(UndoableAction action) {
    if (_history.length >= maxHistory) {
      _history.removeFirst();
    }
    _history.addLast(action);
  }

  Future<void> undo() async {
    if (_history.isEmpty) return;
    final action = _history.removeLast();
    await action.undo();
  }

  bool get canUndo => _history.isNotEmpty;
}

abstract class UndoableAction {
  Future<void> undo();
  String get description;
}

class DeleteItemAction implements UndoableAction {
  final Item deletedItem;
  final ItemsNotifier notifier;

  DeleteItemAction(this.deletedItem, this.notifier);

  @override
  Future<void> undo() async {
    await notifier.restoreItem(deletedItem);
  }

  @override
  String get description => 'Delete ${deletedItem.name}';
}

// Show undo snackbar
void showUndoSnackbar(BuildContext context, UndoableAction action) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(action.description),
      duration: Duration(seconds: 5),
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () => ref.read(undoManagerProvider).undo(),
      ),
    ),
  );
}
```

## Dependencies
- Story 2.4 (Check/Uncheck Items)
- Story 2.5 (Delete Items)

## Estimated Effort
4 story points
