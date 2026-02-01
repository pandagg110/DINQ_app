import 'package:dio/dio.dart';
import 'api_client.dart';

class ToolService {
  final Dio _dio = ApiClient.instance.dio;

  /// 获取机构 logo URL
  Future<String?> getInstitutionLogo(String institution) async {
    if (institution.trim().isEmpty) return null;
    final response = await _dio.post(
      '/tool/institution-logo',
      data: {'institution': institution.trim()},
    );
    final data = response.data;
    if (data is Map && data['url'] != null) {
      return data['url'].toString();
    }
    return null;
  }
}
