import 'package:dio/dio.dart';
import '../models/user_models.dart';
import 'api_client.dart';

class FlowService {
  final Dio _dio = ApiClient.instance.dio;

  Future<UserFlow> getFlow() async {
    final response = await _dio.get('/flow');
    return UserFlow.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<void> resetFlow() async {
    await _dio.post('/flow/reset');
  }
}


