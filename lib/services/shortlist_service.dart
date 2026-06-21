import 'package:dio/dio.dart';

import '../models/shortlist_models.dart';
import 'api_client.dart';

/// Shortlist 接口：收藏项目（文件夹）+ 收藏候选人。
/// 对应线上 `/favorite-projects` 与 `/favorites`。
class ShortlistService {
  final Dio _dio = ApiClient.instance.dio;

  /// 创建收藏项目（文件夹）。
  Future<FavoriteProject> createProject(String name) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/favorite-projects',
      data: {'name': name},
    );
    return FavoriteProject.fromJson(
      Map<String, dynamic>.from(response.data ?? const {}),
    );
  }

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

  /// 创建收藏。
  Future<FavoriteItem> createFavorite({
    required String projectId,
    required String title,
    required Map<String, dynamic> field,
    String type = 'talent',
    String tags = '',
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/favorites',
      data: {
        'type': type,
        'title': title,
        'projectId': projectId,
        'field': field,
        if (tags.isNotEmpty) 'tags': tags,
      },
    );
    return FavoriteItem.fromJson(
      Map<String, dynamic>.from(response.data ?? const {}),
    );
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
