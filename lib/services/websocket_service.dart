import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../constants/app_constants.dart';
import 'message_service.dart';

/// WebSocket 连接状态
enum WsConnectionState { disconnected, connecting, connected }

/// WebSocket 管理器 - 单例模式
class WebSocketManager {
  WebSocketManager._internal();

  static final WebSocketManager instance = WebSocketManager._internal();

  final MessageService _messageService = MessageService();

  WebSocketChannel? _channel;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;

  WsConnectionState _state = WsConnectionState.disconnected;
  WsConnectionState get state => _state;
  bool get isConnected => _state == WsConnectionState.connected;

  // 状态变化监听
  final _stateController = StreamController<WsConnectionState>.broadcast();
  Stream<WsConnectionState> get stateStream => _stateController.stream;

  // 消息流
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  void _setState(WsConnectionState newState) {
    if (_state != newState) {
      _state = newState;
      _stateController.add(newState);
    }
  }

  /// 连接 WebSocket
  Future<void> connect() async {
    if (_state == WsConnectionState.connected || _state == WsConnectionState.connecting) {
      return;
    }

    _setState(WsConnectionState.connecting);

    try {
      final tokenData = await _messageService.getWsToken();
      final wsToken = tokenData['ws_token']?.toString() ?? '';
      final wsUrl = tokenData['ws_url']?.toString() ?? '';

      if (wsToken.isEmpty || wsUrl.isEmpty) {
        debugPrint('WebSocket: token or url is empty');
        _setState(WsConnectionState.disconnected);
        return;
      }

      final uri = Uri.parse('$wsUrl?token=$wsToken');
      _channel = WebSocketChannel.connect(uri);

      // 等待连接建立
      await _channel!.ready;

      _setState(WsConnectionState.connected);
      _reconnectAttempts = 0;
      _startHeartbeat();

      // 监听消息
      _channel!.stream.listen(
        (data) {
          try {
            final message = jsonDecode(data.toString()) as Map<String, dynamic>;
            _messageController.add(message);
          } catch (e) {
            debugPrint('WebSocket: Failed to parse message: $e');
          }
        },
        onError: (error) {
          debugPrint('WebSocket error: $error');
          _handleDisconnect();
        },
        onDone: () {
          debugPrint('WebSocket closed');
          _handleDisconnect();
        },
      );
    } catch (e) {
      debugPrint('WebSocket connect failed: $e');
      _setState(WsConnectionState.disconnected);
      _scheduleReconnect();
    }
  }

  /// 断开连接
  void disconnect() {
    _stopHeartbeat();
    _cancelReconnect();
    _reconnectAttempts = 0;
    _channel?.sink.close(WsConfig.normalCloseCode);
    _channel = null;
    _setState(WsConnectionState.disconnected);
  }

  /// 发送消息
  void sendMessage(Map<String, dynamic> message) {
    if (_channel == null || !isConnected) {
      debugPrint('WebSocket: Cannot send message - not connected');
      return;
    }
    try {
      _channel!.sink.add(jsonEncode(message));
    } catch (e) {
      debugPrint('WebSocket: Failed to send message: $e');
    }
  }

  void _handleDisconnect() {
    _stopHeartbeat();
    _setState(WsConnectionState.disconnected);
    _channel = null;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= WsConfig.maxReconnectAttempts) {
      debugPrint('WebSocket: Max reconnect attempts reached');
      _reconnectAttempts = 0;
      return;
    }

    _reconnectAttempts++;
    final delay = _reconnectAttempts == 1
        ? WsConfig.reconnectDelayMs
        : WsConfig.errorReconnectDelayMs;

    _reconnectTimer = Timer(Duration(milliseconds: delay), () {
      connect();
    });
  }

  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(
      const Duration(milliseconds: WsConfig.heartbeatIntervalMs),
      (_) {
        if (isConnected) {
          sendMessage({'type': WsMessageType.heartbeat});
        }
      },
    );
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _cancelReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  void dispose() {
    disconnect();
    _stateController.close();
    _messageController.close();
  }
}
