# Story 3.6: Typing Indicators

## Description
Show when someone is adding items to a shared list.

## Acceptance Criteria
- [ ] "[Name] is typing..." appears below input
- [ ] Multiple typers: "[Name1] and [Name2] are typing..."
- [ ] Disappears after 3 seconds of inactivity
- [ ] Subtle animation (pulsing dots)

## Technical Implementation

### Flutter Implementation

```dart
// Typing indicator widget
class TypingIndicator extends ConsumerWidget {
  final String listId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typingUsers = ref.watch(typingUsersProvider(listId));

    if (typingUsers.isEmpty) {
      return SizedBox.shrink();
    }

    final names = typingUsers.take(2).join(' and ');
    final suffix = typingUsers.length > 2 ? '+ others' : '';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            '$names $suffix ${typingUsers.length > 1 ? 'are' : 'is'} typing',
            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
          ),
          SizedBox(width: 4),
          _buildPulsingDots(),
        ],
      ),
    );
  }

  Widget _buildPulsingDots() {
    return AnimatedBuilder(
      animation: _dotAnimation,
      builder: (context, child) {
        return Row(
          children: [
            Dot(opacity: _dotAnimation.value),
            SizedBox(width: 2),
            Dot(opacity: max(0, _dotAnimation.value - 0.3)),
            SizedBox(width: 2),
            Dot(opacity: max(0, _dotAnimation.value - 0.6)),
          ],
        );
      },
    );
  }
}

// Typing notifier provider
final typingUsersProvider =
    StateNotifierProvider.family<TypingNotifier, List<String>, String>((ref, listId) {
  return TypingNotifier();
});

class TypingNotifier extends StateNotifier<List<String>> {
  Timer? _clearTimer;

  TypingNotifier() : super([]);

  void setTyping(String userId, String userName) {
    if (!state.contains(userName)) {
      state = [...state, userName];
    }

    _clearTimer?.cancel();
    _clearTimer = Timer(Duration(seconds: 3), () {
      state = state.where((name) => name != userName).toList();
    });
  }

  @override
  void dispose() {
    _clearTimer?.cancel();
    super.dispose();
  }
}

// Quick add input with typing indicator
class QuickAddInput extends ConsumerWidget {
  final String listId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _inputController = TextEditingController();

    void _onTextChanged(String value) {
      // Send typing indicator
      _syncService.sendTyping(listId);
    }

    return Column(
      children: [
        TypingIndicator(listId: listId),
        TextField(
          controller: _inputController,
          decoration: InputDecoration(
            hintText: 'Add item...',
            suffixIcon: IconButton(
              icon: Icon(Icons.send),
              onPressed: () {
                ref.read(itemsProvider.notifier).addItem(
                  listId: listId,
                  name: _inputController.text,
                );
                _inputController.clear();
              },
            ),
          ),
          onChanged: _onTextChanged,
          onSubmitted: (value) {
            ref.read(itemsProvider.notifier).addItem(
              listId: listId,
              name: value,
            );
            _inputController.clear();
          },
        ),
      ],
    );
  }
}
```

## Dependencies
- Story 3.4 (Real-Time Sync)

## Estimated Effort
3 story points
