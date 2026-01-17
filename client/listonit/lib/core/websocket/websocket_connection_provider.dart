import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:async';
import 'dart:convert';
import '../../core/config/api_config.dart';

enum ConnectionStatus {
  idle,
  connecting,
  connected,
  disconnected,
  reconnecting,
  error,
}

class ConnectionState {
  final ConnectionStatus status;
  final String? currentListId;
  final String? error;
  final int reconnectAttempts;

  const ConnectionState({
    this.status = ConnectionStatus.idle,
    this.currentListId,
    this.error,
    this.reconnectAttempts = 0,
  });

  ConnectionState copyWith({
    ConnectionStatus? status,
    String? currentListId,
    String? error,
    int? reconnectAttempts,
  }) {
    return ConnectionState(
      status: status ?? this.status,
      currentListId: currentListId ?? this.currentListId,
      error: error,
      reconnectAttempts: reconnectAttempts ?? this.reconnectAttempts,
    );
  }

  bool get isConnected => status == ConnectionStatus.connected;
}

class WebSocketConnection extends StateNotifier<ConnectionState> {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  String? _token;
  Timer? _reconnectTimer;

  static const int maxReconnectAttempts = 5;
  static const Duration reconnectDelay = Duration(seconds: 3);

  final String baseUrl;
  final StreamController<Map<String, dynamic>> _messageController;

  WebSocketConnection({
    required this.baseUrl,
  })  : _messageController = StreamController<Map<String, dynamic>>.broadcast(),
        super(const ConnectionState());

  // Expose message stream for router to consume
  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  Future<void> connect(String listId, String token) async {
    _token = token;
    state = state.copyWith(
      status: ConnectionStatus.connecting,
      currentListId: listId,
      error: null,
      reconnectAttempts: 0,
    );

    await _doConnect();
  }

  Future<void> _doConnect() async {
    try {
      final uri = Uri.parse('$baseUrl/ws/lists/${state.currentListId}?token=$_token');
      _channel = WebSocketChannel.connect(uri);

      _subscription = _channel!.stream.listen(
        _handleMessage,
        onDone: _handleDisconnect,
        onError: _handleError,
      );

      state = state.copyWith(
        status: ConnectionStatus.connected,
        reconnectAttempts: 0,
      );
    } catch (e) {
      _handleError(e);
    }
  }

  void _handleMessage(dynamic rawMessage) {
    try {
      final message = jsonDecode(rawMessage) as Map<String, dynamic>;
      _messageController.add(message);
    } catch (e) {
      debugPrint('Error parsing WebSocket message: $e');
    }
  }

  void _handleDisconnect() {
    state = state.copyWith(status: ConnectionStatus.disconnected);
    _attemptReconnect();
  }

  void _handleError(dynamic error) {
    debugPrint('WebSocket error: $error');
    state = state.copyWith(
      status: ConnectionStatus.error,
      error: error.toString(),
    );
    _attemptReconnect();
  }

  void _attemptReconnect() {
    if (state.reconnectAttempts >= maxReconnectAttempts) {
      debugPrint('Max reconnection attempts reached');
      state = state.copyWith(status: ConnectionStatus.error, error: 'Max reconnection attempts reached');
      return;
    }

    state = state.copyWith(
      status: ConnectionStatus.reconnecting,
      reconnectAttempts: state.reconnectAttempts + 1,
    );

    debugPrint('Attempting to reconnect... (attempt ${state.reconnectAttempts})');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(reconnectDelay, () async {
      if (state.currentListId != null && _token != null) {
        await _doConnect();
      }
    });
  }

  void send(Map<String, dynamic> message) {
    try {
      _channel?.sink.add(jsonEncode(message));
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    state = state.copyWith(
      status: ConnectionStatus.disconnected,
      currentListId: null,
    );
  }

  @override
  void dispose() {
    disconnect();
    _messageController.close();
    super.dispose();
  }
}

// Provider
final websocketConnectionProvider =
    StateNotifierProvider<WebSocketConnection, ConnectionState>((ref) {
  return WebSocketConnection(
    baseUrl: ApiConfig.wsBaseUrl,
  );
});
