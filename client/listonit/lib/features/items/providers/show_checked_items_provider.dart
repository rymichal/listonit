import 'package:flutter_riverpod/flutter_riverpod.dart';

class ShowCheckedItemsNotifier extends StateNotifier<bool> {
  ShowCheckedItemsNotifier() : super(true);

  void toggle() {
    state = !state;
  }

  void setVisible(bool visible) {
    state = visible;
  }
}

final showCheckedItemsProvider =
    StateNotifierProvider<ShowCheckedItemsNotifier, bool>((ref) {
  return ShowCheckedItemsNotifier();
});
