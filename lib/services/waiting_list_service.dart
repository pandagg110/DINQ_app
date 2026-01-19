import 'package:dio/dio.dart';
import 'api_client.dart';

class WaitingListService {
  final Dio _dio = ApiClient.instance.dio;

  Future<Map<String, dynamic>> join(Map<String, dynamic> payload) async {
    final response = await _dio.post('/waiting-list', data: payload);
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> updateStatus({required String status}) async {
    final response = await _dio.post('/waiting-list/update-status', data: {'status': status});
    return Map<String, dynamic>.from(response.data as Map);
  }
}


