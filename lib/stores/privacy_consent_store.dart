import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../services/api_client.dart';
import '../services/auth_service.dart';

/// 与 Web privacyConsentStore 一致的同意状态。
enum PrivacyConsentStatus { unknown, required, agreed }

/// 与 Web privacyConsentStore 一致的检查状态。
enum PrivacyConsentCheckState { idle, checking, checked }

/// 全局 privacy consent 状态（对齐 Web store/privacyConsentStore.ts +
/// app/provider.tsx + apis/base.ts）。
///
/// 后端以 /user/privacy-consent 为准：未记录同意的账号，card/generate 等
/// 写操作会返回业务码 4012（privacy consent required）。Web 端的闭环是：
/// 1) 登录后 GET /user/privacy-consent/status，未同意 → 标记 required；
/// 2) 任意接口响应带 code 4012 → 标记 required；
/// 3) required 时全局弹「Public Visibility」弹窗，Agree 调
///    POST /user/privacy-consent/agree。
/// 本 store 提供 1/2 的状态机与接口调用，弹窗由 PrivacyConsentGate 渲染。
class PrivacyConsentStore extends ChangeNotifier {
  PrivacyConsentStore({AuthService? authService})
    : _authService = authService ?? AuthService() {
    _activeStore = this;
    _registerConsentInterceptor();
  }

  final AuthService _authService;

  /// 供 Dio 拦截器回调的当前实例（App 生命周期内只创建一个）。
  static PrivacyConsentStore? _activeStore;
  static bool _interceptorRegistered = false;

  PrivacyConsentStatus status = PrivacyConsentStatus.unknown;
  PrivacyConsentCheckState checkState = PrivacyConsentCheckState.idle;
  bool isAgreeing = false;

  bool get isRequired => status == PrivacyConsentStatus.required;

  /// 与 Web base.ts 一致：任意接口返回业务码 4012 → 标记 required。
  /// ApiClient 的 onResponse 会把非 0 业务码 reject 成 DioException 且保留
  /// 原始 response.data（{code, message}），HTTP 非 2xx 的 4012 也走 onError，
  /// 因此统一在 onError 里识别。
  ///
  /// 另外监听 consent 接口的成功响应：onboarding / 注册等流程通过
  /// UserStore.agreeToTerms 直接写入同意时，本 store 也能同步到 agreed，
  /// 避免残留 required 状态导致弹窗误弹。
  static void _registerConsentInterceptor() {
    if (_interceptorRegistered) return;
    _interceptorRegistered = true;
    ApiClient.instance.dio.interceptors.add(
      InterceptorsWrapper(
        onResponse: (response, handler) {
          final path = response.requestOptions.path;
          if (path.endsWith('/user/privacy-consent/agree')) {
            _activeStore?.markAgreed();
          } else if (path.endsWith('/user/privacy-consent/status')) {
            final data = response.data;
            if (data is Map && data['agreed'] == true) {
              _activeStore?.markAgreed();
            }
          }
          return handler.next(response);
        },
        onError: (error, handler) {
          if (extractBusinessCode(error) == 4012) {
            _activeStore?.markRequired();
          }
          return handler.next(error);
        },
      ),
    );
  }

  /// 从 DioException 中提取业务码（响应体形如 {code, message, ...}）。
  @visibleForTesting
  static int? extractBusinessCode(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      final code = data['code'];
      if (code is int) return code;
      if (code is String) return int.tryParse(code);
    }
    return null;
  }

  void markChecking() {
    checkState = PrivacyConsentCheckState.checking;
    status = PrivacyConsentStatus.unknown;
    notifyListeners();
  }

  void markRequired() {
    if (status == PrivacyConsentStatus.required &&
        checkState == PrivacyConsentCheckState.checked) {
      return;
    }
    status = PrivacyConsentStatus.required;
    checkState = PrivacyConsentCheckState.checked;
    notifyListeners();
  }

  void markAgreed() {
    status = PrivacyConsentStatus.agreed;
    checkState = PrivacyConsentCheckState.checked;
    isAgreeing = false;
    notifyListeners();
  }

  void markUnknownChecked() {
    status = PrivacyConsentStatus.unknown;
    checkState = PrivacyConsentCheckState.checked;
    isAgreeing = false;
    notifyListeners();
  }

  /// 登出时调用（与 Web reset 一致）。
  void reset() {
    status = PrivacyConsentStatus.unknown;
    checkState = PrivacyConsentCheckState.idle;
    isAgreeing = false;
    notifyListeners();
  }

  /// 登录成功 / 登录态恢复后调用（与 Web provider.tsx checkPrivacyConsent
  /// 一致）：agreed → agreed；未同意或 4012 → required；其他失败 →
  /// unknown+checked（不打扰用户，等 4012 兜底）。
  Future<void> syncStatus() async {
    if (checkState == PrivacyConsentCheckState.checking) return;
    markChecking();
    try {
      final agreed = await _authService.checkAgreement();
      if (agreed) {
        markAgreed();
      } else {
        markRequired();
      }
    } on DioException catch (error) {
      if (extractBusinessCode(error) == 4012) {
        markRequired();
      } else {
        markUnknownChecked();
      }
    } catch (_) {
      markUnknownChecked();
    }
  }

  /// 同意协议（与 Web PublicVisibilityModal handleAgree 一致）。
  /// 成功返回 true 并标记 agreed；失败返回 false（4012 时保持 required）。
  Future<bool> agree() async {
    if (isAgreeing) return false;
    isAgreeing = true;
    notifyListeners();
    try {
      await _authService.agreeToTerms();
      markAgreed();
      return true;
    } on DioException catch (error) {
      if (extractBusinessCode(error) == 4012) {
        markRequired();
      }
      isAgreeing = false;
      notifyListeners();
      return false;
    } catch (_) {
      isAgreeing = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    if (identical(_activeStore, this)) {
      _activeStore = null;
    }
    super.dispose();
  }
}
