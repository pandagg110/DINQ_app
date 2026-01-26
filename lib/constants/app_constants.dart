const String appUrl = String.fromEnvironment('APP_URL', defaultValue: 'https://dinq.me');
const String gatewayUrl = String.fromEnvironment(
  'GATEWAY_URL',
  defaultValue: 'https://api.dinq.me',
);

class ApiConfig {
  static const int requestTimeoutMs = 30000;
  static const int defaultPageSize = 50;
  static const int messagesPageSize = 50;
  static const int notificationsPageSize = 50;
}

class WsConfig {
  static const int heartbeatIntervalMs = 20000;
  static const int reconnectDelayMs = 5000;
  static const int errorReconnectDelayMs = 10000;
  static const int normalCloseCode = 1000;
  static const int authFailCode = 1008;
  static const int maxReconnectAttempts = 5;
}

class WsMessageType {
  static const String heartbeat = 'heartbeat';
  static const String message = 'message';
  static const String read = 'read';
  static const String typing = 'typing';
  static const String notification = 'notification';
  static const String setCurrentConversation = 'set_current_conversation';
  static const String conversationUpdate = 'conversation_update';
  static const String notificationUpdate = 'notification_update';
  static const String unreadCountUpdate = 'unread_count_update';
  static const String messageStatusUpdate = 'message_status_update';
  static const String recall = 'recall';
}
