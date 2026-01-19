import 'package:dio/dio.dart';
import '../models/user_models.dart';
import 'api_client.dart';

class AuthService {
  final Dio _dio = ApiClient.instance.dio;

  Future<Map<String, dynamic>> login({required String email, required String password}) async {
    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String verificationCode,
    String? inviteCode,
  }) async {
    final response = await _dio.post('/auth/register', data: {
      'email': email,
      'password': password,
      'verificationCode': verificationCode,
      if (inviteCode != null) 'inviteCode': inviteCode,
    });
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<void> sendCode({required String email}) async {
    await _dio.post('/auth/send-code', data: {'email': email});
  }

  Future<void> verifyCode({required String email, required String code}) async {
    await _dio.post('/auth/verify', data: {'email': email, 'code': code});
  }

  Future<void> forgotPassword({required String email}) async {
    await _dio.post('/auth/forgot-password', data: {'email': email});
  }

  Future<void> confirmReset({required String code, required String password}) async {
    await _dio.post('/auth/confirm-reset', data: {'code': code, 'password': password});
  }

  Future<void> changePassword({required String oldPassword, required String newPassword}) async {
    await _dio.post('/auth/change-password', data: {
      'oldPassword': oldPassword,
      'newPassword': newPassword,
    });
  }

  Future<UserProfile> getUserProfile() async {
    final response = await _dio.get('/user/profile');
    return UserProfile.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<void> sendBindEmailCode({required String email}) async {
    await _dio.post('/auth/change-email/send-code', data: {'email': email});
  }

  Future<void> bindEmail({required String email, required String code}) async {
    await _dio.post('/auth/change-email', data: {'email': email, 'code': code});
  }

  Future<void> deleteAccount() async {
    await _dio.get('/auth/delete-account');
  }

  Future<void> activate({required String inviteCode}) async {
    await _dio.post('/user/activate', data: {'inviteCode': inviteCode});
  }
}


