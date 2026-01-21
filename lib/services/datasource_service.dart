import 'package:dio/dio.dart';
import 'api_client.dart';

class DatasourceService {
  final Dio _dio = ApiClient.instance.dio;

  /// 获取数据源列表
  Future<Map<String, dynamic>> getDatasources(String username, {List<String>? dataSourceIds}) async {
    final response = await _dio.post('/datasources/list', data: {
      'username': username,
      if (dataSourceIds != null) 'data_source_ids': dataSourceIds,
    });
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// 创建数据源
  Future<Map<String, dynamic>> createDatasource({
    required String type,
    required String url,
    Map<String, dynamic>? extraData,
  }) async {
    final data = {
      'type': type,
      'url': url,
      if (extraData != null) ...extraData,
    };
    final response = await _dio.post('/datasources', data: data);
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// 删除数据源
  Future<void> deleteDatasource(String id) async {
    await _dio.delete('/datasources/$id');
  }

  /// 更新数据源
  Future<Map<String, dynamic>> updateDatasource(String id, Map<String, dynamic> data) async {
    final response = await _dio.put('/datasources/$id', data: data);
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// 获取社交链接（通过 token 识别用户）
  Future<Map<String, dynamic>> getSocialLinks() async {
    final response = await _dio.get('/datasources/social-links');
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// 重新生成所有 AI 卡片
  Future<Map<String, dynamic>> regenerateAllCards() async {
    final response = await _dio.post('/card/regenerate/all', data: {});
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// 重新生成单个卡片
  Future<Map<String, dynamic>> regenerateCard({required String datasourceId}) async {
    final response = await _dio.post('/card/regenerate', data: {'datasource_id': datasourceId});
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// 更新 Achievement Network 数据
  Future<Map<String, dynamic>> updateAchievementNetwork(Map<String, dynamic> data) async {
    final response = await _dio.post('/achievement-network-update', data: data);
    return Map<String, dynamic>.from(response.data as Map);
  }
}


