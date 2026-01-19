import 'package:dio/dio.dart';
import 'api_client.dart';

class DatasourceService {
  final Dio _dio = ApiClient.instance.dio;

  Future<Map<String, dynamic>> getDatasources(String username, List<String> dataSourceIds) async {
    final response = await _dio.post('/datasources', data: {
      'username': username,
      'data_source_ids': dataSourceIds,
    });
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> regenerateAllCards() async {
    final response = await _dio.post('/datasource/regenerate-all');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> regenerateCard({required String datasourceId}) async {
    final response = await _dio.post('/datasource/regenerate', data: {'datasource_id': datasourceId});
    return Map<String, dynamic>.from(response.data as Map);
  }
}


