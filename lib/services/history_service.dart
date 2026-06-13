import 'api_client.dart';

/// 与 TSX historyApi 一致：统一历史会话列表 / 详情 / 删除
class HistoryService {
  final _dio = ApiClient.instance.dio;

  String _conversationPath(String type, Object id) {
    final idStr = id.toString();
    if (type == 'discover') return '/discover/sessions/$idStr';
    return '/$type/history/$idStr';
  }

  /// GET /history — 会话列表（keyword / limit / offset）
  Future<Map<String, dynamic>> getConversations({
    String? keyword,
    int limit = 20,
    int offset = 0,
  }) async {
    final query = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };
    if (keyword != null && keyword.isNotEmpty) {
      query['keyword'] = keyword;
    }

    final response = await _dio.get<Map<String, dynamic>>(
      '/history',
      queryParameters: query,
    );
    return response.data as Map<String, dynamic>;
  }

  /// GET /discover/sessions/:id 或 /:type/history/:id — 会话详情
  Future<Map<String, dynamic>> getConversationDetail(
    String type,
    Object id,
  ) async {
    final response = await _dio.get<Map<String, dynamic>>(
      _conversationPath(type, id),
    );
    return response.data as Map<String, dynamic>;
  }

  /// DELETE — 删除会话
  Future<void> deleteConversation(String type, Object id) async {
    await _dio.delete<void>(_conversationPath(type, id));
  }
}
