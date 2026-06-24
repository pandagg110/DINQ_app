import 'package:dio/dio.dart';

import '../models/shortlist_models.dart';
import 'api_client.dart';

/// Shortlist 接口：收藏项目（文件夹）+ 收藏候选人。
/// 对应线上 `/favorite-projects` 与 `/favorites`。
class ShortlistService {
  final Dio _dio = ApiClient.instance.dio;

  Future<FavoriteProject> createProject(String name) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/favorite-projects',
      data: {'name': name},
    );
    return FavoriteProject.fromJson(
      Map<String, dynamic>.from(response.data ?? const {}),
    );
  }

  Future<List<FavoriteProject>> listProjects() async {
    final response = await _dio.get('/favorite-projects');
    final data = response.data;
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => FavoriteProject.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<FavoriteProject> renameProject(String id, String name) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/favorite-projects/$id',
      data: {'name': name},
    );
    return FavoriteProject.fromJson(
      Map<String, dynamic>.from(response.data ?? const {}),
    );
  }

  Future<void> deleteProject(String id) async {
    await _dio.delete('/favorite-projects/$id');
  }

  Future<List<FavoriteItem>> listFavorites({
    String? projectId,
    String? name,
    String? status,
    int limit = 20,
    int offset = 0,
    String type = 'talent',
  }) async {
    final response = await _dio.get(
      '/favorites',
      queryParameters: {
        'type': type,
        if (projectId != null && projectId.isNotEmpty) 'projectId': projectId,
        if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
        if (status != null && status.isNotEmpty) 'status': status,
        'limit': limit,
        'offset': offset,
      },
    );
    final data = response.data;
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => FavoriteItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

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

  Future<void> removeFavorite(String id) async {
    await _dio.delete('/favorites/$id');
  }

  Future<FavoriteItem> moveFavorite(String id, String projectId) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/favorites/$id',
      data: {'projectId': projectId},
    );
    return FavoriteItem.fromJson(
      Map<String, dynamic>.from(response.data ?? const {}),
    );
  }

  Future<FavoriteItem> updateFavorite(String id, {String? tags}) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/favorites/$id',
      data: {
        if (tags != null) 'tags': tags,
      },
    );
    return FavoriteItem.fromJson(
      Map<String, dynamic>.from(response.data ?? const {}),
    );
  }

  Future<ShortlistPdfExportResult> exportPdf(List<String> ids) async {
    final response = await _dio.post<List<int>>(
      '/favorites/export-pdf',
      data: {'ids': ids},
      options: Options(
        responseType: ResponseType.bytes,
        headers: {'Accept': 'application/pdf'},
      ),
    );
    final bytes = response.data ?? const [];
    final disposition = response.headers.value('content-disposition');
    final filename = _parseDispositionFilename(disposition);
    return ShortlistPdfExportResult(bytes: bytes, filename: filename);
  }

  String _parseDispositionFilename(String? disposition) {
    if (disposition == null) return 'shortlist.pdf';
    final utf8Match =
        RegExp(r"filename\*=UTF-8''([^;]+)", caseSensitive: false)
            .firstMatch(disposition);
    if (utf8Match != null) {
      try {
        return Uri.decodeComponent(
          utf8Match.group(1)!.replaceAll('"', ''),
        );
      } catch (_) {
        return utf8Match.group(1)!.replaceAll('"', '');
      }
    }
    final match =
        RegExp(r'filename="?([^";]+)"?', caseSensitive: false)
            .firstMatch(disposition);
    return match?.group(1) ?? 'shortlist.pdf';
  }

  String buildCsvContent(List<FavoriteItem> rows) {
    const bom = '\uFEFF';
    const headers = [
      'Name',
      'Company',
      'Title',
      'Evidence',
      'Profile URL',
      'Status',
      'Tags',
      'Added At',
    ];
    final lines = <String>[
      headers.map(_escapeCsvField).join(','),
      for (final item in rows)
        [
          item.name,
          item.company,
          item.roleTitle,
          item.evidence,
          item.profileUrl,
          item.status,
          item.tags,
          item.createdAt ?? '',
        ].map(_escapeCsvField).join(','),
    ];
    return '$bom${lines.join('\n')}';
  }

  String _escapeCsvField(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  String safeFilenamePart(String value) {
    final slug = value
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9_-]+', caseSensitive: false), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return slug.isEmpty ? 'shortlist' : slug;
  }
}
