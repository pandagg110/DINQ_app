import 'package:dio/dio.dart';

import '../models/user_models.dart';
import '../utils/api_error.dart';
import 'api_client.dart';

Map<String, dynamic> buildThirdPartyLoginPayload({
  required String provider,
  required String idToken,
  String? redirectUri,
  String? authorizationCode,
  String? nonce,
  String? givenName,
  String? familyName,
}) => {
  'provider': provider,
  'id_token': idToken,
  'redirect_uri': ?redirectUri,
  'authorization_code': ?authorizationCode,
  'nonce': ?nonce,
  if (givenName?.trim().isNotEmpty ?? false) 'given_name': givenName!.trim(),
  if (familyName?.trim().isNotEmpty ?? false) 'family_name': familyName!.trim(),
};

Map<String, dynamic> buildVerificationPayload({
  required String email,
  required String code,
  String? purpose,
}) => {
  'email': email,
  'code': code,
  if (purpose != null && purpose.isNotEmpty) 'purpose': purpose,
};

final class GoogleLoginException implements Exception {
  const GoogleLoginException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Clears the locally cached Google account before opening the account picker.
Future<T?> selectGoogleAccount<T>({
  required Future<void> Function() clearCachedAccount,
  required Future<T?> Function() signIn,
}) async {
  await clearCachedAccount();
  return signIn();
}

String requireGoogleIdToken(String? token) {
  final value = token?.trim() ?? '';
  if (value.isEmpty) {
    throw const GoogleLoginException(
      'Google login is not configured for this app build.',
    );
  }
  return value;
}

String googleLoginErrorMessage(Object error) {
  if (error is GoogleLoginException) return error.message;
  return apiErrorMessage(
    error,
    fallback: 'Google login failed. Please try again.',
  );
}

String thirdPartyLoginErrorMessage({
  required String provider,
  required Object error,
}) {
  final message = apiErrorMessage(
    error,
    fallback: '${_providerLabel(provider)} login failed. Please try again.',
  );
  final normalized = message.toLowerCase();
  final isProviderConflict =
      normalized.contains('another provider') ||
      normalized.contains('another sign-in') ||
      normalized.contains('already registered') ||
      normalized.contains('account already exists') ||
      normalized.contains('email already exists');
  if (isProviderConflict) {
    final label = _providerLabel(provider);
    return 'This email is already linked to another sign-in method. '
        'Sign in with that method, then connect $label in Settings.';
  }
  return message;
}

String bindEmailErrorMessage(Object error) {
  const conflictMessage =
      'This email is already linked to another account. '
      'Please use a different email and try again.';
  const fallbackMessage = 'Unable to update email. Please try again.';
  final message = apiErrorMessage(error, fallback: fallbackMessage);
  final normalized = message.toLowerCase();
  final statusCode = error is DioException ? error.response?.statusCode : null;
  final isEmailConflict =
      statusCode == 409 ||
      normalized.contains('already bound') ||
      normalized.contains('already linked') ||
      normalized.contains('already registered') ||
      normalized.contains('already exists') ||
      normalized.contains('email exists') ||
      normalized.contains('email is in use') ||
      normalized.contains('email already in use') ||
      normalized.contains('another account');
  if (isEmailConflict) return conflictMessage;

  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Network timeout. Please try again.';
      case DioExceptionType.connectionError:
        return 'Network error. Please check your connection.';
      default:
        break;
    }

    if (statusCode == 401) {
      return 'Your session has expired. Please sign in again.';
    }
    if (statusCode == 429) {
      return 'Too many attempts. Please try again later.';
    }
  }

  final isInvalidCode =
      normalized.contains('verification code') &&
      (normalized.contains('invalid') ||
          normalized.contains('incorrect') ||
          normalized.contains('expired'));
  if (isInvalidCode) {
    return 'The verification code is invalid or expired. '
        'Please request a new code and try again.';
  }

  return fallbackMessage;
}

String passwordChangeErrorMessage(Object error) {
  const fallbackMessage = 'Unable to update password. Please try again.';
  final statusCode = error is DioException ? error.response?.statusCode : null;

  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Network timeout. Please try again.';
      case DioExceptionType.connectionError:
        return 'Network error. Please check your connection.';
      default:
        break;
    }

    if (statusCode == 401) {
      return 'Your session has expired. Please sign in again.';
    }
    if (statusCode == 429) {
      return 'Too many attempts. Please try again later.';
    }
    if (statusCode != null && statusCode >= 500) return fallbackMessage;
  }

  final normalized = _passwordChangeServerMessage(error).toLowerCase();
  if (normalized.contains('current password is required')) {
    return 'Please enter your current password.';
  }
  if (normalized.contains('current password is incorrect')) {
    return 'Current password is incorrect.';
  }
  if (normalized.contains('different from current password')) {
    return 'The new password must be different from your current password.';
  }
  if (normalized.contains('at least') && normalized.contains('character')) {
    return 'Password must be at least 8 characters.';
  }
  if (statusCode == 400) {
    return 'Unable to update password. Please check your input.';
  }
  return fallbackMessage;
}

bool passwordChangeRequiresCurrentPassword(Object error) =>
    _passwordChangeServerMessage(
      error,
    ).toLowerCase().contains('current password is required');

String _passwordChangeServerMessage(Object error) {
  if (error is! DioException) return '';

  final interceptedMessage = error.error;
  if (interceptedMessage is String && interceptedMessage.isNotEmpty) {
    return interceptedMessage;
  }

  final data = error.response?.data;
  if (data is Map) {
    for (final key in const ['message', 'error', 'msg', 'detail']) {
      final value = data[key];
      if (value is String && value.isNotEmpty) return value;
    }
  }
  return data is String ? data : '';
}

String _providerLabel(String provider) => switch (provider.toLowerCase()) {
  'github' => 'GitHub',
  'google' => 'Google',
  'apple' => 'Apple',
  _ => 'this account',
};

class AuthService {
  final Dio _dio = ApiClient.instance.dio;

  /// POST /api/v1/auth/web-login-ticket
  /// 返回一次性 ticket，用于 Web 页面在 60 秒内换取正式 token。
  ///
  /// 依赖：当前用户已登录，ApiClient 会在请求拦截器里自动带上
  /// Authorization: Bearer <当前 App JWT>。
  Future<Map<String, dynamic>> webLoginTicket() async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/web-login-ticket',
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// 三方登录 google/github
  Future<Map<String, dynamic>> thirdPartyLogin({
    required String provider,
    required String idToken,
    String? redirectUri,
    String? authorizationCode,
    String? nonce,
    String? givenName,
    String? familyName,
  }) async {
    final response = await _dio.post(
      '/auth/oauth/app-login',
      data: buildThirdPartyLoginPayload(
        provider: provider,
        idToken: idToken,
        redirectUri: redirectUri,
        authorizationCode: authorizationCode,
        nonce: nonce,
        givenName: givenName,
        familyName: familyName,
      ),
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String verificationCode,
    String? inviteCode,
  }) async {
    final response = await _dio.post(
      '/auth/register',
      data: {
        'email': email,
        'password': password,
        'verificationCode': verificationCode,
        if (inviteCode != null) 'inviteCode': inviteCode,
      },
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// 发送验证码
  /// [type] 验证码类型: "register" | "reset_password" | "profile_verification"
  /// [inviteCode] 邀请码（可选）
  Future<void> sendCode({
    required String email,
    required String
    type, // "register" | "reset_password" | "profile_verification"
    String? inviteCode,
  }) async {
    await _dio.post(
      '/auth/send-code',
      data: {
        'email': email,
        'type': type,
        if (inviteCode != null) 'inviteCode': inviteCode,
      },
    );
  }

  Future<void> verifyCode({
    required String email,
    required String code,
    String? purpose,
  }) async {
    await _dio.post(
      '/auth/verify',
      data: buildVerificationPayload(
        email: email,
        code: code,
        purpose: purpose,
      ),
    );
  }

  /// 忘记密码 - 发送重置链接到邮箱
  /// [email] 邮箱地址
  /// [redirectUrl] 重定向 URL
  Future<void> forgotPassword({
    required String email,
    required String redirectUrl,
  }) async {
    await _dio.post(
      '/auth/forgot-password',
      data: {'email': email, 'redirectUrl': redirectUrl},
    );
  }

  /// 确认重置密码
  /// [email] 邮箱地址
  /// [code] 验证码
  /// [newPassword] 新密码
  Future<void> confirmReset({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await _dio.post(
      '/auth/confirm-reset',
      data: {'email': email, 'code': code, 'new_password': newPassword},
    );
  }

  /// 修改密码 (已登录用户)
  /// [currentPassword] 当前密码（可选）
  /// [newPassword] 新密码
  Future<void> changePassword({
    String? currentPassword,
    required String newPassword,
  }) async {
    await _dio.post(
      '/auth/change-password',
      data: {
        if (currentPassword != null) 'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }

  Future<UserProfile> getUserProfile() async {
    final response = await _dio.get('/user/profile');
    return UserProfile.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  /// 发送绑定/更换邮箱验证码
  /// [newEmail] 新邮箱地址
  Future<void> sendBindEmailCode({required String newEmail}) async {
    await _dio.post(
      '/auth/change-email/send-code',
      data: {'newEmail': newEmail},
    );
  }

  /// 绑定/更换邮箱
  /// [newEmail] 新邮箱地址
  /// [code] 验证码
  Future<void> bindEmail({
    required String newEmail,
    required String code,
  }) async {
    await _dio.post(
      '/auth/change-email',
      data: {'newEmail': newEmail, 'code': code},
    );
  }

  Future<void> deleteAccount() async {
    await _dio.get('/auth/delete-account');
  }

  /// 激活用户（使用邀请码）
  /// [inviteCode] 邀请码
  Future<void> activate({required String inviteCode}) async {
    await _dio.post('/user/activate', data: {'invite_code': inviteCode});
  }

  /// 查询是否是否同意过协议
  Future<bool> checkAgreement() async {
    final response = await _dio.get('/user/privacy-consent/status');
    final res = Map<String, dynamic>.from(response.data as Map);
    if (res["agreed"] == true) {
      return true;
    } else {
      return false;
    }
  }

  /// 同意协议
  Future<void> agreeToTerms() async {
    await _dio.post('/user/privacy-consent/agree');
  }
}
