import 'package:dio/dio.dart';
import '../models/user_models.dart';
import 'api_client.dart';

class ProfileService {
  final Dio _dio = ApiClient.instance.dio;

  /// 获取用户数据 (通过 username)
  Future<UserData> getUserData(String username) async {
    final response = await _dio.get('/user-data', queryParameters: {'username': username});
    return UserData.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  /// 更新用户数据
  Future<UserData> updateUserData(Map<String, dynamic> payload) async {
    final response = await _dio.post('/user-data', data: payload);
    return UserData.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  /// 提交职业验证
  Future<Map<String, dynamic>> submitCareerVerification(Map<String, dynamic> data) async {
    final response = await _dio.post('/user/profile/career-verification', data: data);
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// 提交教育验证
  Future<Map<String, dynamic>> submitEducationVerification(Map<String, dynamic> data) async {
    final response = await _dio.post('/user/profile/education-verification', data: data);
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// 获取社交平台OAuth URL
  Future<Map<String, dynamic>> getSocialOAuthURL(Map<String, dynamic> params) async {
    final response = await _dio.get('/user/profile/social-verification/oauth-url', queryParameters: params);
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// 链接社交账号
  Future<Map<String, dynamic>> linkSocialAccount(Map<String, dynamic> data) async {
    final response = await _dio.post('/user/profile/social-verification/link', data: data);
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// 取消链接社交账号
  Future<Map<String, dynamic>> unlinkSocialAccount(Map<String, dynamic> data) async {
    final response = await _dio.post('/user/profile/social-verification/unlink', data: data);
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// 获取验证概览
  Future<Map<String, dynamic>> getVerificationOverview() async {
    final response = await _dio.get('/user/profile/verification/overview');
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// 获取已连接的账号列表
  Future<Map<String, dynamic>> getAccounts() async {
    final response = await _dio.get('/user/accounts');
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// 完成账号绑定
  Future<Map<String, dynamic>> linkAccount({required String platform, required String code}) async {
    final response = await _dio.post('/user/accounts/link/$platform', data: {'code': code});
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// 断开账号连接
  Future<void> unlinkAccount({required String provider}) async {
    await _dio.post('/user/accounts/unlink', data: {'provider': provider});
  }

  /// 获取账号关联的OAuth URL
  Future<Map<String, dynamic>> getAccountLinkOAuthURL({required String platform}) async {
    final response = await _dio.get('/user/accounts/link/$platform');
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// 记录页面访问
  Future<Map<String, dynamic>> recordPageView({required String username}) async {
    final response = await _dio.post('/page-view', data: {'username': username});
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// 获取页面访问统计
  Future<Map<String, dynamic>> getPageViewStats(String username, {String range = 'all'}) async {
    final response = await _dio.get('/page-view/stats', queryParameters: {
      'username': username,
      'range': range,
    });
    return Map<String, dynamic>.from(response.data as Map);
  }
}


