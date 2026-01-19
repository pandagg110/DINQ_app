import 'package:dio/dio.dart';
import 'api_client.dart';

class ContactRequestService {
  final Dio _dio = ApiClient.instance.dio;

  Future<void> submit(Map<String, dynamic> payload) async {
    await _dio.post('/contact-requests', data: payload);
  }
}

