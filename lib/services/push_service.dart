import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'api_client.dart';

/// 后台/终止态收到消息时触发的顶层处理函数（FCM 要求是顶层或 static）。
/// 带 notification 字段的消息系统会自动展示，这里一般无需额外处理。
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // no-op：保留入口，后续如需后台静默处理数据消息可在此扩展
}

/// 消息推送服务（FCM / APNs）。
/// 负责：初始化 Firebase、申请通知权限、获取/上报设备 Token、前台消息本地展示、
/// 点击通知跳转、登出解绑。
///
/// 仅在 Android / iOS 真机有效；Web 与未配置 Firebase 的环境会安全跳过，不影响主流程。
/// 需要的外部配置见 FCM_SETUP.md（google-services.json / APNs / 后端 /devices 接口）。
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  final _local = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  String? _lastToken;

  /// 点击通知后的跳转回调，由 app 层注入（通常指向 router.go）。
  void Function(String route)? onNavigate;

  static const _channelId = 'dinq_default';
  static const _channelName = 'DINQ Notifications';

  bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;
  bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// App 启动时调用（main 中）。内部捕获所有异常，未配置 Firebase 时静默跳过。
  Future<void> init() async {
    if (!_supported || _ready) return;
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await _initLocalNotifications();

      // 前台消息：自行用本地通知展示（前台时系统默认不弹）
      FirebaseMessaging.onMessage.listen(_onForegroundMessage);
      // 后台 → 点击通知进入 App
      FirebaseMessaging.onMessageOpenedApp.listen((m) => _handleTap(m.data));
      // 冷启动（终止态点击通知拉起）
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) _handleTap(initial.data);
      // Token 刷新自动重新上报
      FirebaseMessaging.instance.onTokenRefresh.listen(_uploadToken);

      _ready = true;
    } catch (e) {}
  }

  Future<void> _initLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (resp) {
        final payload = resp.payload;
        if (payload != null && payload.isNotEmpty) onNavigate?.call(payload);
      },
    );
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: '私信、Talent Radar 与系统通知',
      importance: Importance.high,
    );
    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  void _onForegroundMessage(RemoteMessage message) {
    final n = message.notification;
    if (n == null) return;
    _local.show(
      n.hashCode,
      n.title,
      n.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: _routeFromData(message.data),
    );
  }

  /// 申请通知权限 + 取 Token + 上报后端。登录成功后调用。
  Future<void> registerToken() async {
    if (!_supported) return;
    if (!_ready) await init();
    if (!_ready) return;
    try {
      // 无 GMS / 权限弹窗卡住时，限制等待，避免拖死登录 loading。
      await _registerTokenBody().timeout(const Duration(seconds: 8));
    } catch (_) {}
  }

  Future<void> _registerTokenBody() async {
    final settings = await FirebaseMessaging.instance.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return;
    }
    if (_isIOS) {
      // iOS 需先拿到 APNs token，否则 getToken 可能为空
      await FirebaseMessaging.instance.getAPNSToken();
    }
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) await _uploadToken(token);
  }

  Future<void> _uploadToken(String token) async {
    if (token == _lastToken) return;
    _lastToken = token;
    try {
      // TODO(pandagg110): 确认后端实际路径与字段。对应 Notion「设备 Token：注册/更新」。
      await ApiClient.instance.dio.post(
        '/devices',
        data: {'token': token, 'platform': _isIOS ? 'ios' : 'android'},
      );
    } catch (e) {}
  }

  /// 登出时解绑设备 Token，避免给已登出用户继续推送。
  Future<void> unbindToken() async {
    if (!_supported) return;
    final token = _lastToken;
    _lastToken = null;
    if (token == null) return;
    try {
      // TODO(pandagg110): 确认后端解绑接口。对应 Notion「设备 Token：登出解绑」。
      await ApiClient.instance.dio.delete('/devices/$token');
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {}
  }

  /// 从推送 data 解析跳转路由。
  /// 与后端约定（今早 fyr 确认推送含 4 类通知）：data 带 `type` + 对应 id。
  ///   message / team_recruit → 会话页 /admin/inbox/{conversation_id}
  ///   radar                  → 通知中心（暂无候选人详情深链路由，先落通知中心）
  ///   system（系统通知/公告）  → 通知中心 /admin/inbox/notifications
  /// 兼容：直接给 `route` 时优先用；只给 conversation_id（无 type）时按会话跳。
  String? _routeFromData(Map<String, dynamic> data) {
    final route = data['route'];
    if (route is String && route.isNotEmpty) return route;

    final conv = (data['conversation_id'] ?? data['conversationId'])
        ?.toString();
    final type = (data['type'] ?? '').toString();
    switch (type) {
      case 'message':
      case 'team_recruit':
        if (conv != null && conv.isNotEmpty) return '/admin/inbox/$conv';
        return '/admin/inbox';
      case 'radar':
      case 'system':
        return '/admin/inbox/notifications';
    }

    // 无 type 时的兜底：有会话 id 就进会话
    if (conv != null && conv.isNotEmpty) return '/admin/inbox/$conv';
    return null;
  }

  void _handleTap(Map<String, dynamic> data) {
    final route = _routeFromData(data);
    if (route != null) onNavigate?.call(route);
  }
}
