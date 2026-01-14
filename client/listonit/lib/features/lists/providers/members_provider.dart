import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/list_api.dart';
import '../domain/list_member.dart';

class MembersState {
  final List<ListMember> members;
  final bool isLoading;
  final String? error;

  const MembersState({
    this.members = const [],
    this.isLoading = false,
    this.error,
  });

  MembersState copyWith({
    List<ListMember>? members,
    bool? isLoading,
    String? error,
  }) {
    return MembersState(
      members: members ?? this.members,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class MembersNotifier extends StateNotifier<MembersState> {
  final ListApi _listApi;

  MembersNotifier(this._listApi) : super(const MembersState());

  Future<void> loadMembers(String listId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final membersData = await _listApi.getListMembers(listId);
      final members = membersData
          .map((data) => ListMember.fromJson(data))
          .toList();
      state = state.copyWith(members: members, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e is ApiException ? e.message : 'Failed to load members',
      );
    }
  }

  Future<bool> updateMemberRole(String listId, String memberId, String role) async {
    state = state.copyWith(error: null);

    try {
      final updatedData = await _listApi.updateMemberRole(listId, memberId, role);
      final updatedMember = ListMember.fromJson(updatedData);

      state = state.copyWith(
        members: state.members.map((m) => m.id == memberId ? updatedMember : m).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e is ApiException ? e.message : 'Failed to update member role',
      );
      return false;
    }
  }

  Future<bool> removeMember(String listId, String memberId) async {
    state = state.copyWith(error: null);

    try {
      await _listApi.removeMember(listId, memberId);
      state = state.copyWith(
        members: state.members.where((m) => m.id != memberId).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e is ApiException ? e.message : 'Failed to remove member',
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final membersProvider = StateNotifierProvider.family<
    MembersNotifier,
    MembersState,
    String>((ref, listId) {
  final listApi = ref.watch(listApiProvider);
  return MembersNotifier(listApi);
});
