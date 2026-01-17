import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PresenceState {
  final Map<String, String> activeUsers; // userId -> userName
  final String? currentlyTypingUser;

  const PresenceState({
    this.activeUsers = const {},
    this.currentlyTypingUser,
  });

  PresenceState copyWith({
    Map<String, String>? activeUsers,
    String? currentlyTypingUser,
  }) {
    return PresenceState(
      activeUsers: activeUsers ?? this.activeUsers,
      currentlyTypingUser: currentlyTypingUser,
    );
  }

  List<String> get userNames => activeUsers.values.toList();
  int get userCount => activeUsers.length;
}

class PresenceNotifier extends StateNotifier<PresenceState> {
  PresenceNotifier() : super(const PresenceState());

  void handleUserJoined(String userId, String userName) {
    final updatedUsers = Map<String, String>.from(state.activeUsers);
    updatedUsers[userId] = userName;

    state = state.copyWith(activeUsers: updatedUsers);
    debugPrint('User joined: $userName (total: ${updatedUsers.length})');
  }

  void handleUserLeft(String userId, String? userName) {
    final updatedUsers = Map<String, String>.from(state.activeUsers);
    updatedUsers.remove(userId);

    state = state.copyWith(activeUsers: updatedUsers);
    debugPrint('User left: $userName (remaining: ${updatedUsers.length})');
  }

  void handleUserTyping(String userId, String userName) {
    state = state.copyWith(currentlyTypingUser: userName);

    // Clear typing indicator after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (state.currentlyTypingUser == userName) {
        state = state.copyWith(currentlyTypingUser: null);
      }
    });
  }

  void reset() {
    state = const PresenceState();
  }
}

final presenceProvider = StateNotifierProvider<PresenceNotifier, PresenceState>((ref) {
  return PresenceNotifier();
});
