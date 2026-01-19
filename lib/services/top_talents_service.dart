import 'package:dio/dio.dart';
import 'api_client.dart';

class TopTalentsService {
  final Dio _dio = ApiClient.instance.dio;

  Future<Map<String, dynamic>> getTopTalents({required String type, int count = 5}) async {
    final response = await _dio.get('/top-talents', queryParameters: {
      'type': type,
      'count': count,
    });
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> getScholarTalents({int count = 5}) {
    return getTopTalents(type: 'scholar', count: count);
  }

  Future<Map<String, dynamic>> getGitHubTalents({int count = 5}) {
    return getTopTalents(type: 'github', count: count);
  }

  Future<Map<String, dynamic>> getLinkedInTalents({int count = 5}) {
    return getTopTalents(type: 'linkedin', count: count);
  }
}


