import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/lists/presentation/lists_screen.dart';
import '../core/websocket/websocket_message_router.dart';

class ListonitApp extends ConsumerWidget {
  const ListonitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize WebSocket router (this starts listening to messages)
    ref.watch(websocketAutoInitProvider);

    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'Listonit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: _buildHome(authState),
      ),
    );
  }

  Widget _buildHome(AuthState authState) {
    // If user is actively logging in, show lists screen immediately
    // (even if still loading) to avoid flash to splash screen
    if (authState.isActiveLogin && authState.status == AuthStatus.loading) {
      return const ListsScreen(key: ValueKey('lists'));
    }

    switch (authState.status) {
      case AuthStatus.initial:
      case AuthStatus.loading:
        return const SplashScreen(key: ValueKey('splash'));
      case AuthStatus.authenticated:
        return const ListsScreen(key: ValueKey('lists'));
      case AuthStatus.unauthenticated:
        return const LoginScreen(key: ValueKey('login'));
    }
  }
}
