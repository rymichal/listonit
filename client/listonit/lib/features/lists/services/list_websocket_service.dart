import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/config/api_config.dart';

typedef SyncCallback = void Function(SyncMessage message);

class SyncMessage {
  final String type;
  final Map<String, dynamic> data;

  SyncMessage({
    required this.type,
    required this.data,
  });

  factory SyncMessage.fromJson(Map<String, dynamic> json) {
    return SyncMessage(
      type: json['type'] as String,
      data: json,
    );
  }
}

class ListWebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  final List<SyncCallback> _listeners = [];
  final String _baseUrl;
  String? _currentListId;
  String? _token;
  Timer? _reconnectTimer;
  bool _isConnected = false;
  static const int _maxReconnectAttempts = 5;
  int _reconnectAttempts = 0;
  static const Duration _reconnectDelay = Duration(seconds: 3);

  ListWebSocketService({String? baseUrl}) : _baseUrl = baseUrl ?? ApiConfig.wsBaseUrl;

  bool get isConnected => _isConnected;

  void addListener(SyncCallback callback) {
    _listeners.add(callback);
  }

  void removeListener(SyncCallback callback) {
    _listeners.remove(callback);
  }

  Future<void> connect(String listId, String token) async {
    _currentListId = listId;
    _token = token;
    _reconnectAttempts = 0;
    await _doConnect();
  }

  Future<void> _doConnect() async {
    try {
      final uri = Uri.parse('$_baseUrl/ws/lists/$_currentListId?token=$_token');
      _channel = WebSocketChannel.connect(uri);
      _isConnected = true;
      _reconnectAttempts = 0;

      _subscription = _channel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message);
            final syncMessage = SyncMessage.fromJson(data);
            _notifyListeners(syncMessage);
          } catch (e) {
            print('Error parsing sync message: $e');
          }
        },
        onDone: () {
          _isConnected = false;
          _attemptReconnect();
        },
        onError: (error) {
          _isConnected = false;
          print('WebSocket error: $error');
          _attemptReconnect();
        },
      );
    } catch (e) {
      _isConnected = false;
      print('Failed to connect to WebSocket: $e');
      _attemptReconnect();
    }
  }

  void _attemptReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      print('Max reconnection attempts reached');
      return;
    }

    _reconnectAttempts++;
    print('Attempting to reconnect... (attempt $_reconnectAttempts)');

    _reconnectTimer = Timer(_reconnectDelay, () async {
      if (_currentListId != null && _token != null) {
        await _doConnect();
      }
    });
  }

  void _notifyListeners(SyncMessage message) {
    for (final listener in _listeners) {
      try {
        listener(message);
      } catch (e) {
        print('Error in sync listener: $e');
      }
    }
  }

  void sendTyping(String userName) {
    try {
      _channel?.sink.add(jsonEncode({
        'type': 'typing',
        'user_name': userName,
      }));
    } catch (e) {
      print('Error sending typing indicator: $e');
    }
  }

  void sendSyncAck(String messageId) {
    try {
      _channel?.sink.add(jsonEncode({
        'type': 'sync_ack',
        'message_id': messageId,
      }));
    } catch (e) {
      print('Error sending sync ack: $e');
    }
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _isConnected = false;
    _listeners.clear();
  }
}

// Global WebSocket service instance
final listWebSocketService = ListWebSocketService();
