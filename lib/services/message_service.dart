import 'package:dio/dio.dart';
import 'api_client.dart';

class MessageService {
  final Dio _dio = ApiClient.instance.dio;

  /// 获取对话列表
  Future<Map<String, dynamic>> getConversations({String? search}) async {
    final response = await _dio.get('/conversations', queryParameters: {
      if (search != null && search.isNotEmpty) 'search': search,
    });
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// 获取对话消息
  Future<Map<String, dynamic>> getMessages(String conversationId, {int? limit, int? offset}) async {
    final response = await _dio.get('/conversations/$conversationId/messages', queryParameters: {
      if (limit != null) 'limit': limit,
      if (offset != null) 'offset': offset,
    });
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// 创建私聊对话
  Future<Map<String, dynamic>> createPrivateConversation(String receiverId) async {
    final response = await _dio.post('/conversations/private', data: {'receiver_id': receiverId});
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// 隐藏/删除对话
  Future<void> hideConversation(String conversationId) async {
    await _dio.post('/conversations/$conversationId/hide');
  }

  /// 获取 WebSocket Token
  Future<Map<String, dynamic>> getWsToken() async {
    final response = await _dio.get('/message/ws-token');
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// 获取通知列表
  Future<Map<String, dynamic>> getNotifications({int? page, int? limit}) async {
    final response = await _dio.get('/notifications', queryParameters: {
      if (page != null) 'page': page,
      if (limit != null) 'limit': limit,
    });
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// 获取通知详情
  Future<Map<String, dynamic>> getNotificationDetail(String id) async {
    final response = await _dio.get('/notifications/$id');
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// 标记所有通知已读
  Future<void> markAllNotificationsRead() async {
    await _dio.post('/notifications/read-all');
  }

  // ============== Team Recruit（与 web messages.ts 对齐）==============

  /// 在会话里发起组队招募，返回 message_type=team_recruit 的消息。
  Future<Map<String, dynamic>> createTeamRecruit(
    String conversationId,
    Map<String, dynamic> data,
  ) async {
    final resp = await _dio.post('/conversations/$conversationId/team-recruit', data: data);
    return Map<String, dynamic>.from(resp.data as Map);
  }

  /// 加入组队招募（满员自动 spawn 子群，响应带 spawned_conv_id）。
  Future<Map<String, dynamic>> joinTeamRecruit(String messageId) async {
    final resp = await _dio.post('/messages/$messageId/team-recruit/join');
    return Map<String, dynamic>.from(resp.data as Map? ?? {});
  }

  /// 离开未满员的组队招募（发起人不能 leave，只能 close）。
  Future<Map<String, dynamic>> leaveTeamRecruit(String messageId) async {
    final resp = await _dio.post('/messages/$messageId/team-recruit/leave');
    return Map<String, dynamic>.from(resp.data as Map? ?? {});
  }

  /// 关闭组队招募（spawn_team=true 用当前成员建子群，仅发起人/管理员）。
  Future<Map<String, dynamic>> closeTeamRecruit(
    String messageId, {
    bool spawnTeam = false,
  }) async {
    final resp = await _dio.post(
      '/messages/$messageId/team-recruit/close',
      data: {'spawn_team': spawnTeam},
    );
    return Map<String, dynamic>.from(resp.data as Map? ?? {});
  }

  /// 从展示中移除组队招募（后端保留 close 业务状态）。
  Future<void> deleteTeamRecruit(String messageId) async {
    await _dio.post('/messages/$messageId/team-recruit/delete');
  }

  /// 查询组队招募当前状态（websocket 重连后对齐）。
  Future<Map<String, dynamic>> getTeamRecruit(String messageId) async {
    final resp = await _dio.get('/messages/$messageId/team-recruit');
    return Map<String, dynamic>.from(resp.data as Map? ?? {});
  }
}
