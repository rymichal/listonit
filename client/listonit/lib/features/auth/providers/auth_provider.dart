import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_service.dart';
import '../data/token_storage.dart';
import '../domain/user.dart';

enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  loading,
}

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? error;
  final bool isActiveLogin; // Track if user is actively logging in

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.error,
    this.isActiveLogin = false,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? error,
    bool? isActiveLogin,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
      isActiveLogin: isActiveLogin ?? this.isActiveLogin,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState());

  Future<void> checkAuthStatus() async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        state = AuthState(status: AuthStatus.authenticated, user: user);
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    state = state.copyWith(
      status: AuthStatus.loading,
      error: null,
      isActiveLogin: true,
    );

    try {
      final user = await _authService.login(username: username, password: password);
      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
        isActiveLogin: false,
      );
      return true;
    } on AuthException catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: e.message,
        isActiveLogin: false,
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});
