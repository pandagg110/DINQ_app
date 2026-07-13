import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// GA4 / Firebase Analytics 埋点服务（一期）。
///
/// 设计要点：
/// - 单例；所有上报走 [track]，自动补充公共字段 `login_status` / `activation_intent`。
/// - 所有事件参数值必须是 String（布尔用 "true"/"false"）。
/// - Firebase 未初始化（如 iOS 缺 GoogleService-Info.plist、Web/桌面端）时
///   所有方法安全 no-op，绝不抛错、不崩溃。Firebase 由 [PushService.init]
///   （main.dart）负责初始化，本服务只在每次调用时探测 `Firebase.apps`。
/// - user_id 只通过 [setUserId] 走 FirebaseAnalytics.setUserId，禁止进事件参数。
/// - 禁止上报：邮箱/手机号/姓名/token/完整搜索词/附件文件名/完整域名/用户名/
///   社媒完整 URL/订单 ID。debug 模式对可疑参数键做校验提示。
class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();

  /// 全局激活意图：'search' / 'dinq_page' / 'unknown'。
  String _activationIntent = 'unknown';

  /// 登录态：false=guest，true=logged_in。
  bool _loggedIn = false;

  /// trackOnce 去重键（会话内存级，防 rebuild/重挂载重复上报）。
  final Set<String> _onceKeys = <String>{};

  /// 本会话内发起的 checkout（用于 subscription_success 客户端确认）。
  /// 上报时 plan/period 以后端返回的订阅为准，这里只留 provider 与周期兜底。
  String? _pendingCheckoutPeriod;
  String? _pendingCheckoutProvider;

  /// 已上报过 subscription_success 的订阅签名（本地去重，签名不上报）。
  final Set<String> _reportedSubscriptionKeys = <String>{};

  static const Set<String> _intents = {'search', 'dinq_page', 'unknown'};

  /// 事件参数枚举约束（debug 校验用，违规仅告警不崩溃）。
  static const Map<String, Set<String>> _enumParams = {
    'method': {'email', 'google', 'github', 'apple', 'other'},
    'search_type': {'deep_search', 'people_search', 'quick_search'},
    'attachment_type': {
      'resume', 'pdf', 'image', 'doc', 'link', 'other', 'none',
    },
    'create_method': {'resume_upload', 'linkedin_paste', 'manual'},
    'social_platform': {
      'github', 'linkedin', 'scholar', 'x', 'website', 'other',
    },
    'billing_period': {'monthly', 'yearly'},
    'payment_provider': {'stripe', 'apple', 'google_play'},
    'plan': {'free', 'pro', 'team'},
    'target_plan': {'free', 'pro', 'team'},
    'current_plan': {'free', 'pro', 'team'},
  };

  /// 隐私红线：这些键名代表的数据禁止进事件参数（debug 校验）。
  static const Set<String> _forbiddenParamKeys = {
    'email', 'phone', 'name', 'username', 'token', 'query', 'search_query',
    'file_name', 'filename', 'url', 'domain', 'order_id', 'user_id',
  };

  /// Firebase 是否已成功初始化（iOS 缺 plist / Web 等场景为 false → no-op）。
  bool get _enabled {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  FirebaseAnalytics? get _analytics {
    if (!_enabled) return null;
    try {
      return FirebaseAnalytics.instance;
    } catch (_) {
      return null;
    }
  }

  /// 登录成功/注册成功/登录态恢复后调用；user_id 只走这里，不进事件参数。
  Future<void> setUserId(String userId) async {
    if (userId.isEmpty) return;
    _safeCall(() => _analytics?.setUserId(id: userId));
  }

  /// logout 事件上报之后调用。
  Future<void> clearUserId() async {
    _safeCall(() => _analytics?.setUserId(id: null));
  }

  /// 全局激活意图：'search' / 'dinq_page' / 'unknown'。
  void setActivationIntent(String intent) {
    assert(() {
      if (!_intents.contains(intent)) {
        debugPrint(
          '[AnalyticsService] invalid activation_intent "$intent", '
          'expected one of $_intents',
        );
      }
      return true;
    }());
    _activationIntent = _intents.contains(intent) ? intent : 'unknown';
  }

  /// 登录态：登录/注册成功设 true；logout 事件上报后设 false。
  void setLoginStatus(bool loggedIn) {
    _loggedIn = loggedIn;
  }

  /// 上报事件。自动补充 login_status / activation_intent；
  /// [activationIntent] 可对单个事件覆盖全局意图（不改全局状态）。
  Future<void> track(
    String eventName, {
    Map<String, String>? params,
    String? activationIntent,
  }) async {
    final merged = <String, String>{
      ...?params,
      'login_status': _loggedIn ? 'logged_in' : 'guest',
      'activation_intent': activationIntent ?? _activationIntent,
    };
    assert(() {
      _debugValidate(eventName, merged);
      return true;
    }());
    _safeCall(
      () => _analytics?.logEvent(
        name: eventName,
        parameters: Map<String, Object>.from(merged),
      ),
    );
  }

  /// 按 [key] 去重的 track：同一 key 本会话只上报一次
  /// （防 widget rebuild / 重挂载 / 流式更新重复上报）。
  Future<void> trackOnce(
    String key,
    String eventName, {
    Map<String, String>? params,
    String? activationIntent,
  }) async {
    if (_onceKeys.contains(key)) return;
    _onceKeys.add(key);
    await track(eventName, params: params, activationIntent: activationIntent);
  }

  // ---------------------------------------------------------------------
  // 订阅确认（subscription_success 客户端去重）
  // ---------------------------------------------------------------------

  /// checkout 成功发起后调用，记录待确认订阅（内存级，随会话销毁）。
  void markCheckoutStarted({
    required String targetPlan,
    required String billingPeriod,
    required String paymentProvider,
  }) {
    _pendingCheckoutPeriod = billingPeriod;
    _pendingCheckoutProvider = paymentProvider;
  }

  /// 订阅刷新（后端确认）时调用：本会话发起过 checkout 且当前订阅为付费
  /// 计划时上报 subscription_success 一次。[dedupKey] 为订阅签名
  /// （plan + current_period_end），仅本地去重使用，不上报。
  void confirmPendingSubscription({
    required String plan,
    String? billingPeriod,
    required String dedupKey,
  }) {
    final provider = _pendingCheckoutProvider;
    if (provider == null) return;
    if (plan.isEmpty || plan == 'free') return;
    if (_reportedSubscriptionKeys.contains(dedupKey)) return;
    _reportedSubscriptionKeys.add(dedupKey);
    final period = (billingPeriod != null && billingPeriod.isNotEmpty)
        ? billingPeriod
        : (_pendingCheckoutPeriod ?? 'monthly');
    _pendingCheckoutPeriod = null;
    _pendingCheckoutProvider = null;
    track(
      'subscription_success',
      params: {
        'target_plan': plan,
        'billing_period': period,
        'payment_provider': provider,
      },
      activationIntent: 'unknown',
    );
  }

  // ---------------------------------------------------------------------
  // 参数值映射工具（不上报原始文件名/URL/卡片类型）
  // ---------------------------------------------------------------------

  /// 登录 provider → method 枚举。
  static String methodForProvider(String provider) {
    switch (provider.toLowerCase()) {
      case 'email':
        return 'email';
      case 'google':
        return 'google';
      case 'github':
        return 'github';
      case 'apple':
        return 'apple';
      default:
        return 'other';
    }
  }

  /// 附件文件名/URL 扩展名 → attachment_type 枚举（不上报文件名本身）。
  static String attachmentTypeFor(String? fileNameOrUrl) {
    final value = fileNameOrUrl?.trim() ?? '';
    if (value.isEmpty) return 'none';
    final path = Uri.tryParse(value)?.path ?? value;
    final dot = path.lastIndexOf('.');
    final ext = dot >= 0 ? path.substring(dot + 1).toLowerCase() : '';
    switch (ext) {
      case 'pdf':
        return 'pdf';
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
      case 'webp':
      case 'heic':
      case 'bmp':
        return 'image';
      case 'doc':
      case 'docx':
      case 'txt':
      case 'rtf':
      case 'md':
        return 'doc';
      default:
        if (ext.isEmpty && value.startsWith('http')) return 'link';
        return 'other';
    }
  }

  /// 卡片类型 → social_platform 枚举；非社媒链接类卡片返回 null（不上报）。
  static String? socialPlatformForCardType(String cardType) {
    switch (cardType.toUpperCase()) {
      case 'GITHUB':
        return 'github';
      case 'LINKEDIN':
        return 'linkedin';
      case 'SCHOLAR':
        return 'scholar';
      case 'TWITTER':
        return 'x';
      case 'LINK':
        return 'website';
      // 非链接类卡片：不算社媒添加
      case 'MARKDOWN':
      case 'IMAGE':
      case 'NOTE':
      case 'TITLE':
      case 'CAREER_TRAJECTORY':
      case 'ACHIEVEMENT_NETWORK':
      case 'IFRAME':
      case 'VIBE':
        return null;
      default:
        // 其余社媒平台（TikTok/YouTube/Bilibili/…）归入 other
        return 'other';
    }
  }

  // ---------------------------------------------------------------------
  // 内部
  // ---------------------------------------------------------------------

  void _debugValidate(String eventName, Map<String, String> params) {
    for (final entry in params.entries) {
      if (_forbiddenParamKeys.contains(entry.key.toLowerCase())) {
        debugPrint(
          '[AnalyticsService] "$eventName" carries forbidden param key '
          '"${entry.key}" — remove PII/identifiers from event params',
        );
      }
      final allowed = _enumParams[entry.key];
      if (allowed != null && !allowed.contains(entry.value)) {
        debugPrint(
          '[AnalyticsService] "$eventName" param ${entry.key}='
          '"${entry.value}" not in expected enum $allowed',
        );
      }
    }
  }

  Future<void> _safeCall(Future<void>? Function() action) async {
    try {
      await action();
    } catch (e) {
      // Firebase 未初始化 / 平台不支持时静默跳过，不影响业务流程
      assert(() {
        debugPrint('[AnalyticsService] skipped: $e');
        return true;
      }());
    }
  }
}
