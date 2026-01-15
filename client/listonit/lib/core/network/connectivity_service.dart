import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Represents the current connectivity state
class ConnectivityState {
  final bool isOnline;
  final bool hasWifi;
  final bool hasMobile;

  const ConnectivityState({
    required this.isOnline,
    required this.hasWifi,
    required this.hasMobile,
  });

  bool get isOffline => !isOnline;

  const ConnectivityState.online()
      : isOnline = true,
        hasWifi = false,
        hasMobile = false;

  const ConnectivityState.offline()
      : isOnline = false,
        hasWifi = false,
        hasMobile = false;
}

/// State notifier for monitoring connectivity changes
class ConnectivityNotifier extends StateNotifier<ConnectivityState> {
  final Connectivity _connectivity;

  ConnectivityNotifier(this._connectivity) : super(const ConnectivityState.online()) {
    _initialize();
  }

  void _initialize() {
    _connectivity.onConnectivityChanged.listen((results) {
      _updateConnectivityState(results);
    });
  }

  void _updateConnectivityState(List<ConnectivityResult> results) {
    final isOnline = !results.contains(ConnectivityResult.none);
    final hasWifi = results.contains(ConnectivityResult.wifi);
    final hasMobile = results.contains(ConnectivityResult.mobile);

    state = ConnectivityState(
      isOnline: isOnline,
      hasWifi: hasWifi,
      hasMobile: hasMobile,
    );
  }
}

/// Provider for connectivity state
final connectivityProvider = StateNotifierProvider<ConnectivityNotifier, ConnectivityState>(
  (ref) => ConnectivityNotifier(Connectivity()),
);
