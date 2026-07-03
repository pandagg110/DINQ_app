import 'package:dio/dio.dart';
import 'api_client.dart';

class DatasourceService {
  final Dio _dio = ApiClient.instance.dio;

  Map<String, dynamic> _responseMap(Response<dynamic> response) {
    final data = response.data;
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return <String, dynamic>{};
  }

  Future<Map<String, dynamic>> getDatasources(
    String username, {
    List<String>? dataSourceIds,
  }) async {
    final payload = <String, dynamic>{'username': username};
    if (dataSourceIds != null) {
      payload['data_source_ids'] = dataSourceIds;
    }
    final response = await _dio.post('/datasources/list', data: payload);
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> createDatasource({
    required String type,
    required String url,
    Map<String, dynamic>? extraData,
  }) async {
    final data = {'type': type, 'url': url, ...?extraData};
    final response = await _dio.post('/datasources', data: data);
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<void> deleteDatasource(String id) async {
    await _dio.delete('/datasources/$id');
  }

  Future<Map<String, dynamic>> updateDatasource(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.put('/datasources/$id', data: data);
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> getSocialLinks() async {
    final response = await _dio.get('/datasources/social-links');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> regenerateAllCards() async {
    final response = await _dio.post('/card/regenerate/all', data: {});
    return _responseMap(response);
  }

  Future<Map<String, dynamic>> regenerateCard({
    required String datasourceId,
  }) async {
    final response = await _dio.post(
      '/card/regenerate',
      data: {'datasource_id': datasourceId},
    );
    return _responseMap(response);
  }

  Future<void> updateAchievementNetwork(Map<String, dynamic> data) async {
    await _dio.post('/achievement-network-update', data: data);
  }
}
