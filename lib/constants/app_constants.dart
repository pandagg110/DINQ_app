const String appUrl = String.fromEnvironment('APP_URL', defaultValue: 'https://dinq.me');
const String gatewayUrl = String.fromEnvironment(
  'GATEWAY_URL',
  defaultValue: 'https://testapi.dinq.me',
);
const String githubClientId = String.fromEnvironment(
  'GITHUB_CLIENT_ID',
  defaultValue: '',
);
// GitHub OAuth App 允许已配置 callback 的子路径。App 使用专用子路径，
// 避免 WebView 拦截稍晚时命中网关的 Web callback 并提前消费一次性 code。
const String githubRedirectUrl = '$gatewayUrl/auth/oauth/github/callback/app';

/// Password-reset emails must target the deployed web callback route.
const String passwordResetCallbackUrl = '$appUrl/reset/callback';

// ?type=app：web 的 terms/privacy 页检测到该参数会隐藏页内 Back 返回栏
// （app WebView 顶部已有原生返回，避免出现两个返回按钮）。
const String privacyUrl = '$appUrl/privacy?type=app';
const String termsUrl = '$appUrl/terms?type=app';

/// Social Verification OAuth 回调地址，须与后端生成授权 URL 时一致。
const String socialCallbackRedirectUri = '$appUrl/social-callback';

/// 分析页 base URL，与 TSX buildFullAnalysisUrl 一致
const String analysisBaseUrl = 'https://analysis.dinq.me';

class ConstantsTool {
  static const bottomTabHeight = 55.0;
}

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
  // Team Recruit 实时更新（对齐 web services/websocket.ts:255-286）
  static const String teamRecruitUpdated = 'team_recruit_updated';
  static const String teamRecruitClosed = 'team_recruit_closed';
  static const String teamRecruitDeleted = 'team_recruit_deleted';
}
