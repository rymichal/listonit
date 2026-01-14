import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/list_api.dart';

class ShareLinkState {
  final String? shareLink;
  final String role;
  final bool isLoading;
  final String? error;

  const ShareLinkState({
    this.shareLink,
    this.role = 'editor',
    this.isLoading = false,
    this.error,
  });

  ShareLinkState copyWith({
    String? shareLink,
    String? role,
    bool? isLoading,
    String? error,
  }) {
    return ShareLinkState(
      shareLink: shareLink ?? this.shareLink,
      role: role ?? this.role,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ShareLinkNotifier extends StateNotifier<ShareLinkState> {
  final ListApi _listApi;

  ShareLinkNotifier(this._listApi) : super(const ShareLinkState());

  Future<bool> createShareLink(String listId, {String role = 'editor'}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final link = await _listApi.createShareLink(listId, role: role);
      state = state.copyWith(
        shareLink: link,
        role: role,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e is ApiException ? e.message : 'Failed to create share link',
      );
      return false;
    }
  }

  Future<bool> regenerateShareLink(String listId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final link = await _listApi.regenerateShareLink(listId);
      state = state.copyWith(
        shareLink: link,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e is ApiException ? e.message : 'Failed to regenerate share link',
      );
      return false;
    }
  }

  Future<bool> revokeShareLink(String listId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _listApi.revokeShareLink(listId);
      state = state.copyWith(
        shareLink: null,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e is ApiException ? e.message : 'Failed to revoke share link',
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void clearShareLink() {
    state = const ShareLinkState();
  }
}

final shareLinksProvider = StateNotifierProvider<ShareLinkNotifier, ShareLinkState>((ref) {
  final listApi = ref.watch(listApiProvider);
  return ShareLinkNotifier(listApi);
});
