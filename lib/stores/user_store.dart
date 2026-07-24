import 'dart:async';

import 'package:dinq_app/utils/toast_util.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_models.dart';
import '../services/analytics_service.dart';
import '../services/apple_iap_service.dart';
import '../services/google_play_iap_service.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/push_service.dart';
import '../services/flow_service.dart';
import '../services/payment_service.dart';
import '../services/profile_service.dart';

class UserStore extends ChangeNotifier {
  UserStore() {
    _authService = AuthService();
    _profileService = ProfileService();
    _flowService = FlowService();
    _paymentService = PaymentService();
    ApiClient.instance.setUnauthorizedHandler(logout);
    ready = _loadToken();
  }

  late final Future<void> ready;

  late final AuthService _authService;
  late final ProfileService _profileService;
  late final FlowService _flowService;
  late final PaymentService _paymentService;

  UserProfile? user;
  UserData? cardOwner;
  String? authToken;
  bool isLoading = false;
  UserFlow? myFlow;
  bool isLoadingFlow = false;
  bool isInitialized = false;
  Map<String, dynamic>? verify;
  List<dynamic> connectedAccounts = [];
  bool isUnlinkingAccount = false;
  Subscription? subscription;
  bool isLoadingSubscription = false;

  bool isLoggedIn() => authToken != null && authToken!.isNotEmpty;

  Future<void> initialize() async {
    if (authToken == null || authToken!.isEmpty) {
      isInitialized = true;
      notifyListeners();
      return;
    }

    await Future.wait([getCurrentUser(), getFlow(), loadSubscription()]);
    isInitialized = true;
    notifyListeners();
    unawaited(AppleIapService.instance.retryPendingTransactions());
    unawaited(GooglePlayIapService.instance.retryPendingTransactions());
    await loadVerifications();
    await loadUserAccounts();
    // 登录态就绪后注册推送设备 Token（真机生效，其余环境内部跳过）
    PushService.instance.registerToken();
  }

  Future<void> _loadToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      authToken = prefs.getString('user.authToken');
      ApiClient.instance.setAuthToken(authToken);
      await initialize();
    } catch (_) {
      // 启动阶段的用户/订阅接口失败不应阻止 App 进入主界面；各页面会自行重试。
    } finally {
      if (!isInitialized) {
        isInitialized = true;
        notifyListeners();
      }
    }
  }

  Future<void> _persistToken() async {
    final prefs = await SharedPreferences.getInstance();
    if (authToken == null) {
      await prefs.remove('user.authToken');
    } else {
      await prefs.setString('user.authToken', authToken!);
    }
  }

  void setCardOwner(UserData? data) {
    cardOwner = data;
    notifyListeners();
  }

  Future<UserProfile?> login({
    required String email,
    required String password,
  }) async {
    isLoading = true;
    notifyListeners();
    try {
      final result = await _authService.login(email: email, password: password);
      authToken = result['token']?.toString();
      ApiClient.instance.setAuthToken(authToken);
      await _persistToken();
      // 登录已成功（token 已持久化）。初始化失败不能让整个登录表现为
      // "密码错误"（H5 可登录、客户端报密码错误的根因之一），
      // 首页各模块会自行拉取数据。
      try {
        await initialize();
      } catch (_) {}
      // 埋点时序：先 setUserId，再报 login_success
      await _setAnalyticsUser(result);
      AnalyticsService.instance.track(
        'login_success',
        params: {'method': 'email'},
      );
      isLoading = false;
      notifyListeners();
      return user;
    } catch (error) {
      isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<UserProfile?> thirdPartyLogin({
    required String provider,
    required String idToken,
  }) async {
    isLoading = true;
    notifyListeners();
    try {
      final result = await _authService.thirdPartyLogin(
        provider: provider,
        idToken: idToken,
      );
      authToken = result['token']?.toString();
      ApiClient.instance.setAuthToken(authToken);
      await _persistToken();
      await initialize();
      // 埋点时序：先 setUserId，再报 login_success。
      // thirdPartyLogin 每次 OAuth 回调成功仅执行一次，天然只报一次。
      await _setAnalyticsUser(result);
      AnalyticsService.instance.track(
        'login_success',
        params: {'method': AnalyticsService.methodForProvider(provider)},
      );
      isLoading = false;
      notifyListeners();
      return user;
    } catch (error) {
      isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String verificationCode,
    String? inviteCode,
  }) async {
    isLoading = true;
    notifyListeners();
    try {
      final result = await _authService.register(
        email: email,
        password: password,
        verificationCode: verificationCode,
        inviteCode: inviteCode,
      );
      authToken = result['token']?.toString();
      ApiClient.instance.setAuthToken(authToken);
      await _persistToken();
      // 埋点时序：注册成功拿到用户 ID（response.data.user.id）后先 setUserId，
      // 再报 sign_up_success。注册自动登录只报 sign_up_success，不报 login_success。
      await _setAnalyticsUser(result);
      AnalyticsService.instance.track(
        'sign_up_success',
        params: {'method': 'email'},
      );
      await initialize();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// 登出清理钩子：持有用户态数据的 Store（如 ShortlistStore）注册自身的
  /// clear()，保证所有登出路径（设置页 Sign out / 头像菜单 / 删号 / 401 过期）
  /// 都能清掉跨账号残留（对齐 ResumeStore.clear 的登出清理语义；ResumeStore
  /// 由 settings_page 登出点调用，但 app_header/401 等路径覆盖不到，故这里
  /// 用注册制统一触达）。
  static final Set<VoidCallback> _logoutCleanups = <VoidCallback>{};

  static void registerLogoutCleanup(VoidCallback cleanup) {
    _logoutCleanups.add(cleanup);
  }

  static void unregisterLogoutCleanup(VoidCallback cleanup) {
    _logoutCleanups.remove(cleanup);
  }

  /// [userInitiated] 为 true 表示用户主动登出（设置页/头像菜单），
  /// 此时按时序报 logout（login_status 仍为 logged_in）→ clearUserId → 本地置 guest。
  /// 401 会话过期走默认 false，只清用户态不报事件。
  void logout({bool userInitiated = false}) {
    if (userInitiated && isLoggedIn()) {
      AnalyticsService.instance.track('logout');
    }
    AnalyticsService.instance.clearUserId();
    AnalyticsService.instance.setLoginStatus(false);
    // 解绑推送 Token，避免给已登出用户继续推送（先于清 token，接口仍需鉴权）
    PushService.instance.unbindToken();
    user = null;
    authToken = null;
    myFlow = null;
    verify = null;
    subscription = null;
    ApiClient.instance.setAuthToken(null);
    _persistToken();
    // 清理各 Store 的跨账号用户态（新建账号看到上一账号 shortlist 老数据的根因）
    for (final cleanup in List<VoidCallback>.of(_logoutCleanups)) {
      cleanup();
    }
    notifyListeners();
  }

  Future<UserProfile?> getCurrentUser() async {
    if (authToken == null || authToken!.isEmpty) return null;
    try {
      user = await _authService.getUserProfile();
      // 登录态恢复（冷启动等）：只 setUserId，不报 login_success
      final userId = user?.user.id;
      if (userId != null && userId.isNotEmpty) {
        await AnalyticsService.instance.setUserId(userId);
        AnalyticsService.instance.setLoginStatus(true);
      }
      notifyListeners();
      return user;
    } catch (_) {
      return null;
    }
  }

  /// 埋点：从 auth 接口返回（response.data.user.id）或已加载的 profile
  /// 中取用户 ID，只走 setUserId，不进事件参数。
  Future<void> _setAnalyticsUser(Map<String, dynamic> authResult) async {
    String? userId;
    final resultUser = authResult['user'];
    if (resultUser is Map) {
      final id = resultUser['id']?.toString();
      if (id != null && id.isNotEmpty) userId = id;
    }
    userId ??= user?.user.id;
    if (userId != null && userId.isNotEmpty) {
      await AnalyticsService.instance.setUserId(userId);
    }
    AnalyticsService.instance.setLoginStatus(true);
  }

  Future<void> updateUserBase(Map<String, dynamic> payload) async {
    if (user == null) return;
    user = UserProfile(
      user: User.fromJson({...user!.user.toJson(), ...payload}),
      userData: user!.userData,
    );
    notifyListeners();
  }

  Future<void> updateUserData(Map<String, dynamic> payload) async {
    if (user == null) return;
    final updated = UserData.fromJson({
      ...user!.userData.toJson(),
      ...payload,
    });
    user = UserProfile(
      user: user!.user,
      userData: updated,
    );
    // Keep profile/share owner in sync when editing own page.
    if (cardOwner != null && cardOwner!.domain == updated.domain) {
      cardOwner = UserData.fromJson({
        ...cardOwner!.toJson(),
        ...payload,
      });
    }
    notifyListeners();
    await _profileService.updateUserData(payload);
  }

  Future<Map<String, dynamic>?> loadVerifications() async {
    if (!isLoggedIn()) {
      verify = null;
      notifyListeners();
      return null;
    }
    try {
      verify = await _profileService.getVerificationOverview();
      notifyListeners();
      return verify;
    } catch (_) {
      return null;
    }
  }

  void updateVerify(String type, Map<String, dynamic> updates) {
    verify ??= {};
    final current = Map<String, dynamic>.from(verify!);
    current[type] = {...(current[type] ?? {}), ...updates};
    verify = current;
    notifyListeners();
  }

  Future<void> loadUserAccounts() async {
    try {
      final response = await _profileService.getAccounts();
      connectedAccounts = response['accounts'] as List<dynamic>? ?? [];
      notifyListeners();
    } catch (_) {
      // ignore
    }
  }

  Future<void> unlinkAccount({required String provider}) async {
    isUnlinkingAccount = true;
    notifyListeners();
    try {
      await _profileService.unlinkAccount(provider: provider);
      await loadUserAccounts();
    } finally {
      isUnlinkingAccount = false;
      notifyListeners();
    }
  }

  Future<UserFlow?> getFlow() async {
    if (!isLoggedIn()) {
      myFlow = null;
      notifyListeners();
      return null;
    }
    isLoadingFlow = true;
    notifyListeners();
    try {
      myFlow = await _flowService.getFlow();
      return myFlow;
    } catch (_) {
      myFlow = null;
      return null;
    } finally {
      isLoadingFlow = false;
      notifyListeners();
    }
  }

  void setMyFlow(UserFlow? flow) {
    myFlow = flow;
    notifyListeners();
  }

  Future<void> resetFlow() async {
    await _flowService.resetFlow();
    await getFlow();
  }

  Future<Subscription?> loadSubscription() async {
    if (!isLoggedIn()) {
      subscription = null;
      notifyListeners();
      return null;
    }
    isLoadingSubscription = true;
    notifyListeners();
    try {
      subscription = await _paymentService.getSubscription();
      // 埋点：本会话发起过 checkout 且后端确认为付费计划时报 subscription_success
      // （签名去重，签名本身不上报）
      final sub = subscription!;
      AnalyticsService.instance.confirmPendingSubscription(
        plan: sub.basePlan,
        billingPeriod: sub.billingPeriod,
        dedupKey: '${sub.plan}|${sub.currentPeriodEnd ?? ''}',
      );
      return subscription;
    } catch (_) {
      subscription = Subscription(
        plan: 'free',
        status: 'active',
        creditsBalance: 3,
        monthlyCredits: 3,
        cancelAtPeriodEnd: false,
        currentPeriodEnd: null,
      );
      return subscription;
    } finally {
      isLoadingSubscription = false;
      notifyListeners();
    }
  }

  Future<void> refreshSubscription() async {
    await loadSubscription();
  }

  void deductCredit([int amount = 1]) {
    if (subscription == null) return;
    subscription = subscription!.copyWith(
      creditsBalance: (subscription!.creditsBalance - amount).clamp(0, 999999),
    );
    notifyListeners();
  }

  /// 查询是否是否同意过协议
  Future<bool> checkAgreement() async {
    try {
      return await _authService.checkAgreement();
    } catch (error) {
      ToastUtil.show('Check agreement error');
      return false;
    }
  }

  /// 同意协议（写入服务端；失败时抛出，调用方勿仅标记本地已同意）
  Future<void> agreeToTerms() async {
    try {
      await _authService.agreeToTerms();
    } catch (error) {
      ToastUtil.show('Failed to agree to terms');
      rethrow;
    }
  }
}
