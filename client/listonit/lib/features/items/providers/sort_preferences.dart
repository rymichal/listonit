import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SortPreferences {
  final SharedPreferences _prefs;

  SortPreferences(this._prefs);

  /// Get the sort direction (ascending=A-Z, descending=Z-A) for a list.
  /// Defaults to true (A-Z / newest first).
  bool getSortAscending(String listId) {
    return _prefs.getBool('list_${listId}_sort_ascending') ?? true;
  }

  /// Set the sort direction for a list.
  Future<void> setSortAscending(String listId, bool ascending) {
    return _prefs.setBool('list_${listId}_sort_ascending', ascending);
  }

  /// Toggle the sort direction for a list.
  Future<void> toggleSortAscending(String listId) {
    final current = getSortAscending(listId);
    return setSortAscending(listId, !current);
  }
}

final sortPreferencesProvider = FutureProvider<SortPreferences>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return SortPreferences(prefs);
});
