import 'package:dio/dio.dart';
import 'api_client.dart';

class UploadService {
  final Dio _dio = ApiClient.instance.dio;

  Future<String> uploadFile({required List<int> bytes, required String filename}) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final response = await _dio.post('/upload', data: formData);
    final data = Map<String, dynamic>.from(response.data as Map);
    return data['url']?.toString() ?? '';
  }
}


