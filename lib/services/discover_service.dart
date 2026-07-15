import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../models/deep_search_channel_models.dart';
import 'api_client.dart';

/// Search 相关 API（后端仍沿用 /discover 路径）
class SearchExportException implements Exception {
  const SearchExportException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SearchService {
  final _dio = ApiClient.instance.dio;

  /// 解析 Dio ResponseBody SSE 流为 JSON 事件。
  ///
  /// 必须用流式 UTF-8 解码（而不是逐 chunk `utf8.decode`）：网络分片会把
  /// 多字节字符（中文/emoji）截断在 chunk 边界上，逐 chunk 解码会抛
  /// FormatException 并中断整轮搜索（QA「搜索过程中出现 FormatException，
  /// 时有时无」的根因）。`allowMalformed: true` 与 Web 端 TextDecoder 的
  /// 默认非 fatal 行为一致：真正畸形的字节替换为 U+FFFD，不再抛异常；
  /// 单条事件 JSON 解析失败由 [_normalizeStreamEvent] 跳过该条，不影响后续。
  Stream<Map<String, dynamic>> _parseSseStream(
    ResponseBody responseBody,
  ) async* {
    const decoder = Utf8Decoder(allowMalformed: true);
    final textStream = decoder.bind(responseBody.stream);
    String buffer = '';
    await for (final text in textStream) {
      buffer += text;
      if (!buffer.contains('\n')) continue;
      final lines = buffer.split('\n');
      buffer = lines.removeLast();
      for (final line in lines) {
        final event = _normalizeStreamEvent(line);
        if (event != null) yield event;
      }
    }
    final event = _normalizeStreamEvent(buffer.trim());
    if (event != null) yield event;
  }

  /// 与 TSX deep-search.ts normalizeStreamEvent 对齐
  Map<String, dynamic>? _normalizeStreamEvent(String line) {
    final trimmed = line.trim();
    if (!trimmed.startsWith('data: ')) return null;
    final data = trimmed.substring(6);
    if (data == '[DONE]') return null;
    try {
      final decoded = jsonDecode(data);
      if (decoded is! Map<String, dynamic>) return null;
      final type = decoded['type']?.toString();
      if (type == 'llm_end') {
        final message = decoded['message']?.toString() ?? '';
        if (RegExp(
          r'insufficient\s+credits',
          caseSensitive: false,
        ).hasMatch(message)) {
          return {
            'type': 'error',
            'message': _normalizeStreamErrorMessage(message),
          };
        }
      }
      return decoded;
    } catch (_) {
      return null;
    }
  }

  String _normalizeStreamErrorMessage(String message) {
    return message
        .replaceFirst(RegExp(r'^⚠️\s*'), '')
        .replaceAll('**', '')
        .trim();
  }

  /// POST /scholar/deep-search/stream（主链路）;
  /// 失败时回退到 /discover/chat/stream（兼容旧后端）
  Stream<Map<String, dynamic>> chatStream({
    String? query,
    String mode = 'research',
    int? conversationId,
    String? sessionId,
    String? claudeSessionId,
    String? userId,
    String? attachment,
    String modelProvider = 'anthropic-hao',
  }) async* {
    final deepSearchBody = <String, dynamic>{
      'scene': 'search_v2',
      'model_provider': modelProvider,
      'permission_mode': 'dontAsk',
    };
    if (query != null && query.trim().isNotEmpty) {
      deepSearchBody['query'] = query.trim();
    }
    if (attachment != null && attachment.trim().isNotEmpty) {
      deepSearchBody['attachment'] = attachment.trim();
    }
    if (sessionId != null && sessionId.isNotEmpty) {
      deepSearchBody['session_id'] = sessionId;
    }
    if (claudeSessionId != null && claudeSessionId.isNotEmpty) {
      deepSearchBody['claude_session_id'] = claudeSessionId;
    }
    if (userId != null && userId.isNotEmpty) {
      deepSearchBody['user_id'] = userId;
    }
    if (conversationId != null) {
      deepSearchBody['conversation_id'] = conversationId;
    }

    final streamOptions = Options(
      responseType: ResponseType.stream,
      receiveTimeout: const Duration(minutes: 8),
    );

    try {
      final response = await _dio.post<ResponseBody>(
        '/scholar/deep-search/stream',
        data: deepSearchBody,
        options: streamOptions,
      );
      final responseBody = response.data;
      if (responseBody is ResponseBody) {
        yield* _parseSseStream(responseBody);
        return;
      }
    } catch (_) {
      // fallback below
    }

    final legacyBody = <String, dynamic>{
      if (query != null && query.trim().isNotEmpty) 'query': query.trim(),
      'mode': mode,
    };
    if (conversationId != null) legacyBody['conversation_id'] = conversationId;
    final fallback = await _dio.post<ResponseBody>(
      '/discover/chat/stream',
      data: legacyBody,
      options: streamOptions,
    );
    final responseBody = fallback.data;
    if (responseBody is! ResponseBody) return;
    yield* _parseSseStream(responseBody);
  }

  /// POST /agent-recommendation/recommend-stream-simple?max_advisors=5
  Stream<Map<String, dynamic>> advisorRecommendStream({
    required String resumeUrl,
    String? additionalInfo,
    List<String>? preferredCountries,
    int maxAdvisors = 5,
  }) async* {
    final body = <String, dynamic>{
      'resume': resumeUrl,
      if (additionalInfo != null && additionalInfo.trim().isNotEmpty)
        'additional_info': additionalInfo.trim(),
      if (preferredCountries != null && preferredCountries.isNotEmpty)
        'preferred_country': preferredCountries,
    };

    final response = await _dio.post<ResponseBody>(
      '/agent-recommendation/recommend-stream-simple',
      queryParameters: {'max_advisors': maxAdvisors},
      data: body,
      options: Options(
        responseType: ResponseType.stream,
        receiveTimeout: const Duration(minutes: 8),
      ),
    );

    final responseBody = response.data;
    if (responseBody is! ResponseBody) return;
    yield* _parseSseStream(responseBody);
  }

  /// POST /analyze/{platform} — Scholar / GitHub / LinkedIn 分析 SSE 流
  /// 与 TSX scholarAnalyzeStream / githubAnalyzeStream / linkedinAnalyzeStream 对齐
  Stream<Map<String, dynamic>> analyzeStream({
    required String platform,
    required String query,
    Map<String, dynamic>? candidateData,
  }) async* {
    final body = <String, dynamic>{
      'query': query,
      if (candidateData != null && candidateData.isNotEmpty)
        'data': candidateData,
    };

    final response = await _dio.post<ResponseBody>(
      '/analyze/$platform',
      data: body,
      options: Options(
        responseType: ResponseType.stream,
        receiveTimeout: const Duration(minutes: 8),
      ),
    );

    final responseBody = response.data;
    if (responseBody is! ResponseBody) return;
    yield* _parseSseStream(responseBody);
  }

  /// POST /scholar/deep-search/{sessionId}/stop
  Future<void> stopDeepSearch(String sessionId) async {
    await _dio.post<void>('/scholar/deep-search/$sessionId/stop');
  }

  /// GET /scholar/deep-search/export-pdf — 与 Web `exportDeepSearchPdf` 对齐。
  Future<List<int>> exportDeepSearchPdf({
    required String userId,
    required String sessionId,
    required String sseEventsId,
  }) async {
    try {
      final response = await _dio.get<List<int>>(
        '/scholar/deep-search/export-pdf',
        queryParameters: {
          'user_id': userId,
          'session_id': sessionId,
          'sse_events_id': sseEventsId,
        },
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data ?? const [];
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 404) {
        throw const SearchExportException('Search record not found');
      }
      if (statusCode != null) {
        throw SearchExportException('Export failed ($statusCode)');
      }
      rethrow;
    }
  }

  /// GET /scholar/deep-search/channels — 模型通道列表（Deep Search v2.5）
  Future<DeepSearchChannelsResponse?> getDeepSearchChannels() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/scholar/deep-search/channels',
      );
      final data = response.data;
      if (data == null) return null;
      final parsed = DeepSearchChannelsResponse.fromJson(data);
      if (parsed.channels.isEmpty) return null;
      return parsed;
    } catch (_) {
      return null;
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

  /// POST /discover/enrich/stream — Deep Search enrich SSE 流
  /// 对齐 Web `deep-search-enrich.ts` enrichStream
  Stream<Map<String, dynamic>> enrichStream({
    required String name,
    required String text,
    required String sessionId,
    String? company,
    String? userLanguage,
    CancelToken? cancelToken,
  }) async* {
    final body = <String, dynamic>{
      'name': name,
      'text': text,
      'session_id': sessionId,
      if (company != null && company.isNotEmpty) 'company': company,
      if (userLanguage != null && userLanguage.isNotEmpty)
        'user_language': userLanguage,
    };

    final response = await _dio.post<ResponseBody>(
      '/discover/enrich/stream',
      data: body,
      cancelToken: cancelToken,
      options: Options(
        responseType: ResponseType.stream,
        receiveTimeout: const Duration(minutes: 8),
      ),
    );
    final responseBody = response.data;
    if (responseBody is! ResponseBody) return;
    yield* _parseSseStream(responseBody);
  }

  /// POST /scholar/deep-search/profile-email — 揭示候选人邮箱
  Future<List<String>> profileEmail({
    required String name,
    required String sessionId,
    String? company,
    String? personalHomepage,
    List<Map<String, String>>? sources,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/scholar/deep-search/profile-email',
      data: {
        'name': name,
        'session_id': sessionId,
        if (company != null && company.isNotEmpty) 'company': company,
        if (personalHomepage != null && personalHomepage.isNotEmpty)
          'personal_homepage': personalHomepage,
        if (sources != null && sources.isNotEmpty) 'sources': sources,
      },
    );
    final data = response.data;
    if (data == null) return const [];
    final emails = data['emails'];
    if (emails is! List) return const [];
    return emails.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
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

  /// GET /citation/scholar-profile?author_name=...&limit=...
  Future<Map<String, dynamic>> getScholarProfile({
    required String authorName,
    int limit = 20,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/citation/scholar-profile',
      queryParameters: {'author_name': authorName, 'limit': limit},
    );
    return response.data as Map<String, dynamic>;
  }

  /// GET /citation/scholar-citations?query=...&citers_limit=...
  Future<Map<String, dynamic>> getScholarCitations({
    required String query,
    int citersLimit = 20,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/citation/scholar-citations',
      queryParameters: {'query': query, 'citers_limit': citersLimit},
    );
    return response.data as Map<String, dynamic>;
  }

  /// POST /citation/paper-citers
  Future<Map<String, dynamic>> getPaperCiters({
    required String paperIdentifier,
    int limit = 20,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/citation/paper-citers',
      data: {'paper_identifier': paperIdentifier, 'limit': limit},
    );
    return response.data as Map<String, dynamic>;
  }

  // ============== 会话管理 ==============

  /// POST /discover/conversations — 创建会话
  /// [data] 可选，如 { "title": "..." }
  Future<Map<String, dynamic>> createConversation([
    Map<String, dynamic>? data,
  ]) async {
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
  Future<Map<String, dynamic>> updateConversation(
    int id,
    Map<String, dynamic> data,
  ) async {
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
