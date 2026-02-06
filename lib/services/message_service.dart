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
}
