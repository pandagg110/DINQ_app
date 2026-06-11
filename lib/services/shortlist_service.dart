import 'package:dio/dio.dart';

import '../models/shortlist_models.dart';
import 'api_client.dart';

/// Shortlist 接口：收藏项目（文件夹）+ 收藏候选人。
/// 对应线上 `/favorite-projects` 与 `/favorites`。
class ShortlistService {
  final Dio _dio = ApiClient.instance.dio;

  /// 收藏项目（文件夹）列表。
  Future<List<FavoriteProject>> listProjects() async {
    final response = await _dio.get('/favorite-projects');
    final data = response.data;
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => FavoriteProject.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// 收藏候选人列表。可选按项目过滤；不传则返回全部。
  Future<List<FavoriteItem>> listFavorites({String? projectId}) async {
    final response = await _dio.get(
      '/favorites',
      queryParameters: {
        if (projectId != null && projectId.isNotEmpty) 'projectId': projectId,
      },
    );
    final data = response.data;
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => FavoriteItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// 移除收藏。
  Future<void> removeFavorite(String id) async {
    await _dio.delete('/favorites/$id');
  }

  /// 移动收藏到其他项目。
  Future<void> moveFavorite(String id, String projectId) async {
    await _dio.put('/favorites/$id', data: {'projectId': projectId});
  }
}
