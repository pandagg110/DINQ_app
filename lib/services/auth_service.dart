import 'package:dio/dio.dart';
import '../models/user_models.dart';
import 'api_client.dart';

class AuthService {
  final Dio _dio = ApiClient.instance.dio;

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
    required String type, // "register" | "reset_password" | "profile_verification"
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

  Future<void> verifyCode({required String email, required String code}) async {
    await _dio.post('/auth/verify', data: {'email': email, 'code': code});
  }

  /// 忘记密码 - 发送重置链接到邮箱
  /// [email] 邮箱地址
  /// [redirectUrl] 重定向 URL
  Future<void> forgotPassword({
    required String email,
    required String redirectUrl,
  }) async {
    await _dio.post('/auth/forgot-password', data: {
      'email': email,
      'redirectUrl': redirectUrl,
    });
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
      data: {
        'email': email,
        'code': code,
        'new_password': newPassword,
      },
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
    await _dio.post('/auth/change-email/send-code', data: {'newEmail': newEmail});
  }

  /// 绑定/更换邮箱
  /// [newEmail] 新邮箱地址
  /// [code] 验证码
  Future<void> bindEmail({
    required String newEmail,
    required String code,
  }) async {
    await _dio.post('/auth/change-email', data: {
      'newEmail': newEmail,
      'code': code,
    });
  }

  Future<void> deleteAccount() async {
    await _dio.get('/auth/delete-account');
  }

  /// 激活用户（使用邀请码）
  /// [inviteCode] 邀请码
  Future<void> activate({required String inviteCode}) async {
    await _dio.post('/user/activate', data: {'invite_code': inviteCode});
  }
}
