import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import 'api_client.dart';

/// Search 相关 API（后端仍沿用 /discover 路径）
class SearchService {
  final _dio = ApiClient.instance.dio;

  /// POST /discover/chat/stream — 流式搜索，返回 SSE 事件流
  /// [query] 搜索词，[mode] fast | research，[conversationId] 可选
  Stream<Map<String, dynamic>> chatStream({
    required String query,
    String mode = 'research',
    int? conversationId,
  }) async* {
    print('[SearchService.chatStream] query: $query, mode: $mode, conversationId: $conversationId');
    final body = <String, dynamic>{
      'query': query,
      'mode': mode,
    };
    if (conversationId != null) body['conversation_id'] = conversationId;

    final response = await _dio.post<ResponseBody>(
      '/discover/chat/stream',
      data: body,
      options: Options(
        responseType: ResponseType.stream,
        receiveTimeout: const Duration(minutes: 5),
      ),
    );
    print('[SearchService.chatStream] response: $response');

    final responseBody = response.data;
    if (responseBody is! ResponseBody) return;
    final stream = responseBody.stream;

    // 不用 transform(utf8.decoder)：Dio 的 stream 是 Stream<Uint8List>，与 Utf8Decoder 类型不兼容，改为逐 chunk 解码
    String buffer = '';
    await for (final chunk in stream) {
      buffer += utf8.decode(chunk);
      if (!buffer.endsWith('\n')) continue;
      final lines = buffer.split('\n');
      buffer = lines.removeLast();
      for (final line in lines) {
        final trimmed = line.trim();
        if (!trimmed.startsWith('data: ')) continue;
        final data = trimmed.substring(6);
        if (data == '[DONE]') return;
        try {
          final map = jsonDecode(data) as Map<String, dynamic>;
          yield map;
        } catch (_) {
          // ignore parse errors
        }
      }
    }
    if (buffer.trim().isNotEmpty) {
      final trimmed = buffer.trim();
      if (trimmed.startsWith('data: ')) {
        final data = trimmed.substring(6);
        if (data != '[DONE]') {
          try {
            final map = jsonDecode(data) as Map<String, dynamic>;
            print('[SearchService.chatStream] event: $map');
            yield map;
          } catch (_) {}
        }
      }
    }
  }

  // ============== 聊天 ==============

  /// GET /discover/chat/clear — 清除聊天
  Future<void> clearChat() async {
    await _dio.get<void>('/discover/chat/clear');
  }

  // ============== Profile / Network / Enrich ==============

  /// POST /discover/profile — 获取候选人 profile
  /// [params] 如 { "person": Candidate }
  Future<Map<String, dynamic>> getProfile(Map<String, dynamic> params) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/discover/profile',
      data: params,
    );
    return response.data as Map<String, dynamic>;
  }

  /// POST /discover/network — 获取候选人 network
  /// [params] 如 { "person": Candidate }
  Future<Map<String, dynamic>> getNetwork(Map<String, dynamic> params) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/discover/network',
      data: params,
    );
    return response.data as Map<String, dynamic>;
  }

  /// POST /discover/enrich — 丰富候选人信息
  /// [params] 如 { name, match_reason, useful_info, sources }
  Future<Map<String, dynamic>> enrich(Map<String, dynamic> params) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/discover/enrich',
      data: params,
    );
    return response.data as Map<String, dynamic>;
  }

  // ============== 站内用户搜索 ==============

  /// POST /discover/users/search — 站内用户搜索
  /// [params] 与 UserSearchRequest 一致
  Future<Map<String, dynamic>> searchUsers(Map<String, dynamic> params) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/discover/users/search',
      data: params,
    );
    return response.data as Map<String, dynamic>;
  }

  // ============== 会话管理 ==============

  /// POST /discover/conversations — 创建会话
  /// [data] 可选，如 { "title": "..." }
  Future<Map<String, dynamic>> createConversation([Map<String, dynamic>? data]) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/discover/conversations',
      data: data ?? {},
    );
    return response.data as Map<String, dynamic>;
  }

  /// GET /discover/conversations — 会话列表
  /// 参数: keyword?, page?, page_size?
  /// 返回: { items: [...], total, page, page_size }
  Future<Map<String, dynamic>> getConversations({
    String? keyword,
    int? page,
    int? pageSize,
  }) async {
    final query = <String, dynamic>{};
    if (keyword != null && keyword.isNotEmpty) query['keyword'] = keyword;
    if (page != null) query['page'] = page;
    if (pageSize != null) query['page_size'] = pageSize;

    final response = await _dio.get<Map<String, dynamic>>(
      '/discover/conversations',
      queryParameters: query.isNotEmpty ? query : null,
    );
    return response.data as Map<String, dynamic>;
  }

  /// GET /discover/conversations/:id — 获取会话详情（含所有记录）
  Future<Map<String, dynamic>> getConversationDetail(int id) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/discover/conversations/$id',
    );
    return response.data as Map<String, dynamic>;
  }

  /// PUT /discover/conversations/:id — 更新会话（重命名）
  /// [data] 如 { "title": "..." }
  Future<Map<String, dynamic>> updateConversation(int id, Map<String, dynamic> data) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/discover/conversations/$id',
      data: data,
    );
    return response.data as Map<String, dynamic>;
  }

  /// DELETE /discover/conversations/:id — 删除会话（与 example discoverApi.deleteConversation 对齐）
  Future<void> deleteConversation(int id) async {
    await _dio.delete<void>('/discover/conversations/$id');
    // 后端可能返回 code:0 data:null，不依赖 response 结构
  }
}

@Deprecated('Use SearchService instead.')
class DiscoverService extends SearchService {}
