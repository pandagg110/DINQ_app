import 'package:dio/dio.dart';
import '../models/user_models.dart';
import 'api_client.dart';

class ProfileService {
  final Dio _dio = ApiClient.instance.dio;

  /// 部分接口成功时 `data` 为 null（如账号绑定/解绑），直接 `as Map` 会抛
  /// 类型错误，让调用方误判为失败。
  Map<String, dynamic> _asMap(dynamic data) =>
      data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};

  /// 获取用户数据 (通过 username)
  Future<UserData> getUserData(String username) async {
    final response = await _dio.get(
      '/user-data',
      queryParameters: {'username': username},
    );
    return UserData.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  /// 更新用户数据
  Future<UserData> updateUserData(Map<String, dynamic> payload) async {
    final response = await _dio.post('/user-data', data: payload);
    return UserData.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  /// 提交职业验证
  Future<Map<String, dynamic>> submitCareerVerification(
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.post(
      '/user/profile/career-verification',
      data: data,
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// 提交教育验证
  Future<Map<String, dynamic>> submitEducationVerification(
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.post(
      '/user/profile/education-verification',
      data: data,
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// 获取社交平台OAuth URL
  Future<Map<String, dynamic>> getSocialOAuthURL(
    Map<String, dynamic> params,
  ) async {
    final response = await _dio.get(
      '/user/profile/social-verification/oauth-url',
      queryParameters: params,
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// 链接社交账号
  Future<Map<String, dynamic>> linkSocialAccount(
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.post(
      '/user/profile/social-verification/link',
      data: data,
    );
    return _asMap(response.data);
  }

  /// 取消链接社交账号
  Future<Map<String, dynamic>> unlinkSocialAccount(
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.post(
      '/user/profile/social-verification/unlink',
      data: data,
    );
    return _asMap(response.data);
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
  Future<Map<String, dynamic>> linkAccount({
    required String platform,
    required String code,
  }) async {
    final response = await _dio.post(
      '/user/accounts/link/$platform',
      data: {'code': code},
    );
    return _asMap(response.data);
  }

  /// 断开账号连接
  Future<void> unlinkAccount({required String provider}) async {
    await _dio.post('/user/accounts/unlink', data: {'provider': provider});
  }

  /// 获取账号关联的OAuth URL
  Future<Map<String, dynamic>> getAccountLinkOAuthURL({
    required String platform,
  }) async {
    final response = await _dio.get('/user/accounts/link/$platform');
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// 记录页面访问
  Future<Map<String, dynamic>> recordPageView({
    required String username,
  }) async {
    final response = await _dio.post(
      '/page-view',
      data: {'username': username},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// 获取页面访问统计
  Future<Map<String, dynamic>> getPageViewStats(
    String username, {
    String range = 'all',
  }) async {
    final response = await _dio.get(
      '/page-view/stats',
      queryParameters: {'username': username, 'range': range},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> getViewers({
    int page = 1,
    int pageSize = 50,
    String? username,
  }) async {
    final response = await _dio.get(
      '/page-view/viewers',
      queryParameters: {
        'page': page,
        'page_size': pageSize,
        if (username != null && username.isNotEmpty) 'username': username,
      },
    );
    return Map<String, dynamic>.from(response.data as Map);
  }
}
