import 'package:dio/dio.dart';
import '../models/user_models.dart';
import 'api_client.dart';

class ProfileService {
  final Dio _dio = ApiClient.instance.dio;

  Future<UserData> getUserData(String username) async {
    final response = await _dio.get('/user-data', queryParameters: {'username': username});
    return UserData.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<UserData> updateUserData(Map<String, dynamic> payload) async {
    final response = await _dio.post('/user-data', data: payload);
    return UserData.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<Map<String, dynamic>> getVerificationOverview() async {
    final response = await _dio.get('/user/profile/verification/overview');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> getAccounts() async {
    final response = await _dio.get('/user/accounts');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<void> unlinkAccount({required String provider}) async {
    await _dio.post('/user/accounts/unlink', data: {'provider': provider});
  }

  Future<void> recordPageView({required String username}) async {
    await _dio.post('/page-view', data: {'username': username});
  }

  Future<Map<String, dynamic>> getPageViewStats(String username, {String range = 'all'}) async {
    final response = await _dio.get('/page-view/stats', queryParameters: {
      'username': username,
      'range': range,
    });
    return Map<String, dynamic>.from(response.data as Map);
  }
}


