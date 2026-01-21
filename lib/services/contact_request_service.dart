import 'package:dio/dio.dart';
import 'api_client.dart';

class ContactRequestService {
  final Dio _dio = ApiClient.instance.dio;

  /// 提交联系请求
  Future<void> submit({
    required String name,
    required String email,
    required String affiliation,
    required String country,
    required String jobTitle,
    required String reason,
    String? details,
  }) async {
    await _dio.post('/contact-requests', data: {
      'name': name,
      'email': email,
      'affiliation': affiliation,
      'country': country,
      'job_title': jobTitle,
      'reason': reason,
      if (details != null) 'details': details,
    });
  }
}

