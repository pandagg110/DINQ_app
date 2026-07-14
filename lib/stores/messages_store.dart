import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../models/message_models.dart';
import '../services/message_service.dart';
import '../services/websocket_service.dart';

class MessagesStore extends ChangeNotifier {
  MessagesStore() {
    _messageService = MessageService();
    _wsManager = WebSocketManager.instance;
    _listenWebSocket();
  }

  late final MessageService _messageService;
  late final WebSocketManager _wsManager;
  StreamSubscription<Map<String, dynamic>>? _wsSubscription;
  StreamSubscription<WsConnectionState>? _wsStateSubscription;

  /// WebSocket 错误消息回调（由 UI 层设置，用于显示对话框）
  void Function(String message)? onWsError;

  // 对话列表
  List<Conversation> conversations = [];
  Conversation? currentConversation;
  bool isLoadingConversations = false;

  // 消息列表
  List<Message> messages = [];
  bool isLoadingMessages = false;
  int? unreadMessageStartIndex;
  bool hasMoreMessages = true;
  bool isLoadingMoreMessages = false;

  // 未读总数
  int totalUnreadCount = 0;

  // 当前用户 ID（用于已读逻辑）
  String? currentUserId;

  // WebSocket 连接状态
  bool get isWsConnected => _wsManager.isConnected;

  /// 监听 WebSocket 消息
  void _listenWebSocket() {
    _wsSubscription = _wsManager.messageStream.listen(_handleWsMessage);
    // 监听连接状态变化
    _wsStateSubscription = _wsManager.stateStream.listen(
      (_) => notifyListeners(),
    );
  }

  /// 处理 WebSocket 消息
  void _handleWsMessage(Map<String, dynamic> wsMessage) {
    final type = wsMessage['type']?.toString() ?? '';
    final rawData = wsMessage['data'];
    final data = rawData is Map ? Map<String, dynamic>.from(rawData) : null;

    switch (type) {
      case WsMessageType.message:
        if (data != null) {
          final message = Message.fromJson(data);
          addMessage(message);
        }
        break;

      case WsMessageType.conversationUpdate:
        if (data != null) {
          final conversationId = data['conversation_id']?.toString() ?? '';
          updateConversation(conversationId, {
            'last_message_time': data['last_message_time'],
            'last_message_text': data['last_message_text'],
            'unread_count': data['unread_count'],
          });
        }
        break;

      case WsMessageType.read:
        if (data != null) {
          final conversationId = data['conversation_id']?.toString() ?? '';
          final messageId = data['message_id']?.toString() ?? '';
          // 更新对方已读消息的 last_read_message_id
          if (currentConversation != null &&
              currentConversation!.id == conversationId) {
            final updatedMembers = currentConversation!.members.map((m) {
              // 只更新非当前用户的成员
              if (currentUserId != null && m.userId == currentUserId) {
                return m;
              }
              return m.copyWith(lastReadMessageId: messageId);
            }).toList();
            currentConversation = currentConversation!.copyWith(
              members: updatedMembers,
            );
            notifyListeners();
          }
        }
        break;

      case WsMessageType.unreadCountUpdate:
        if (data != null) {
          final conversationId = data['conversation_id']?.toString() ?? '';
          final count = data['unread_count'] is int
              ? data['unread_count'] as int
              : int.tryParse(data['unread_count']?.toString() ?? '0') ?? 0;
          updateUnreadCount(conversationId, count);
        }
        break;

      case WsMessageType.messageStatusUpdate:
        if (data != null) {
          final conversationId = data['conversation_id']?.toString() ?? '';
          final messageId = data['message_id']?.toString() ?? '';
          final statusStr = data['status']?.toString() ?? '';
          final status = statusStr == 'read'
              ? MessageStatus.read
              : statusStr == 'delivered'
              ? MessageStatus.delivered
              : MessageStatus.sent;
          updateMessageStatus(conversationId, messageId, status);
        }
        break;

      case WsMessageType.recall:
        loadConversations();
        break;

      // Team Recruit 实时更新：其他成员 join/leave/close/delete 时刷新卡片
      //（对齐 web services/websocket.ts:255-286）
      case WsMessageType.teamRecruitUpdated:
      case WsMessageType.teamRecruitClosed:
        if (data != null) {
          final messageId = data['message_id']?.toString() ?? '';
          updateMessageMetadata(messageId, {
            if (data.containsKey('team_members')) 'team_members': data['team_members'],
            if (data.containsKey('team_members_info'))
              'team_members_info': data['team_members_info'],
            if (data.containsKey('team_state')) 'team_state': data['team_state'],
            if (type == WsMessageType.teamRecruitClosed &&
                data.containsKey('team_conv_id'))
              'team_conv_id': data['team_conv_id'],
          });
        }
        break;

      case WsMessageType.teamRecruitDeleted:
        if (data != null) {
          final messageId = data['message_id']?.toString() ?? '';
          markMessageRecalled(messageId);
        }
        break;

      case 'error':
        if (data != null) {
          final errorMessage = data['message']?.toString() ?? '';
          if (errorMessage.isNotEmpty) {
            onWsError?.call(errorMessage);
          }
        }
        break;
    }
  }

  /// 连接 WebSocket
  Future<void> connectWebSocket() async {
    await _wsManager.connect();
  }

  /// 设置当前用户 ID（用于已读逻辑）
  void setCurrentUserId(String userId) {
    if (currentUserId != userId) {
      currentUserId = userId;
    }
  }

  /// 断开 WebSocket
  void disconnectWebSocket() {
    _wsManager.disconnect();
  }

  /// 加载对话列表
  Future<void> loadConversations({String? search}) async {
    isLoadingConversations = true;
    notifyListeners();
    try {
      final response = await _messageService.getConversations(search: search);
      final convList = response['conversations'] as List<dynamic>? ?? [];
      conversations = convList
          .map((c) => Conversation.fromJson(c as Map<String, dynamic>))
          .toList();

      // 计算总未读数
      totalUnreadCount = conversations.fold(
        0,
        (sum, conv) => sum + conv.unreadCount,
      );
    } catch (e) {
    } finally {
      isLoadingConversations = false;
      notifyListeners();
    }
  }

  /// 搜索对话
  Future<List<Conversation>> searchConversations(String query) async {
    try {
      final response = await _messageService.getConversations(search: query);
      final convList = response['conversations'] as List<dynamic>? ?? [];
      return convList
          .map((c) => Conversation.fromJson(c as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// 加载消息
  Future<void> loadMessages(String conversationId, {int? unreadCount}) async {
    isLoadingMessages = true;
    notifyListeners();
    try {
      final response = await _messageService.getMessages(
        conversationId,
        limit: ApiConfig.messagesPageSize,
      );
      final msgList = response['messages'] as List<dynamic>? ?? [];
      messages = msgList
          .map((m) => Message.fromJson(m as Map<String, dynamic>))
          .toList();

      // 计算未读消息起始位置
      int? actualUnreadCount = unreadCount;
      if (actualUnreadCount == null) {
        final conv = conversations
            .where((c) => c.id == conversationId)
            .firstOrNull;
        actualUnreadCount = conv?.unreadCount ?? 0;
      }

      if (actualUnreadCount > 0 && messages.isNotEmpty) {
        unreadMessageStartIndex = (messages.length - actualUnreadCount).clamp(
          0,
          messages.length,
        );
      } else {
        unreadMessageStartIndex = null;
      }

      hasMoreMessages = messages.length >= ApiConfig.messagesPageSize;
    } catch (e) {
    } finally {
      isLoadingMessages = false;
      notifyListeners();
    }
  }

  /// 加载更多消息（分页）
  Future<void> loadMoreMessages() async {
    if (isLoadingMoreMessages ||
        !hasMoreMessages ||
        currentConversation == null)
      return;

    isLoadingMoreMessages = true;
    notifyListeners();

    try {
      final response = await _messageService.getMessages(
        currentConversation!.id,
        limit: ApiConfig.messagesPageSize,
        offset: messages.length,
      );
      final olderMsgList = response['messages'] as List<dynamic>? ?? [];
      final olderMessages = olderMsgList
          .map((m) => Message.fromJson(m as Map<String, dynamic>))
          .toList();

      // 旧消息放在前面
      messages = [...olderMessages, ...messages];

      if (unreadMessageStartIndex != null) {
        unreadMessageStartIndex =
            unreadMessageStartIndex! + olderMessages.length;
      }

      hasMoreMessages = olderMessages.length >= ApiConfig.messagesPageSize;
    } catch (e) {
    } finally {
      isLoadingMoreMessages = false;
      notifyListeners();
    }
  }

  /// 设置当前对话
  void setCurrentConversation(Conversation? conversation) {
    if (currentConversation?.id == conversation?.id) return;

    currentConversation = conversation;
    messages = [];
    unreadMessageStartIndex = null;
    notifyListeners();

    if (conversation != null) {
      loadMessages(conversation.id, unreadCount: conversation.unreadCount);
    }

    // 通知 WebSocket 当前对话变化
    _wsManager.sendMessage({
      'type': WsMessageType.setCurrentConversation,
      'data': {'conversation_id': conversation?.id},
    });
  }

  /// 添加新消息
  void addMessage(Message message) {
    // 只在当前对话时添加
    if (currentConversation != null &&
        message.conversationId == currentConversation!.id) {
      final exists = messages.any((m) => m.id == message.id);
      if (!exists) {
        messages = [...messages, message];
        notifyListeners();
      }
    }

    // 更新对话的最后消息
    updateConversation(message.conversationId, {
      'last_message_text': message.content,
      'last_message_time': message.createdAt,
    });
  }

  /// 更新消息状态
  void updateMessageStatus(
    String conversationId,
    String messageId,
    MessageStatus status,
  ) {
    if (currentConversation != null &&
        conversationId == currentConversation!.id) {
      messages = messages
          .map(
            (msg) => msg.id == messageId ? msg.copyWith(status: status) : msg,
          )
          .toList();
      notifyListeners();
    }
  }

  /// 用服务端返回的最新消息整条替换（Team Recruit 加入/退出/关闭后刷新卡片）
  void replaceMessage(Message updated) {
    if (currentConversation != null &&
        updated.conversationId == currentConversation!.id) {
      messages = messages.map((m) => m.id == updated.id ? updated : m).toList();
      notifyListeners();
    }
  }

  /// 合并更新某条消息的 metadata（Team Recruit websocket 增量推送，
  /// 对齐 web messagesStore.updateMessageMetadata）
  void updateMessageMetadata(String messageId, Map<String, dynamic> partial) {
    if (messageId.isEmpty || partial.isEmpty) return;
    var changed = false;
    messages = messages.map((m) {
      if (m.id != messageId) return m;
      changed = true;
      return m.copyWith(metadata: {...?m.metadata, ...partial});
    }).toList();
    if (changed) notifyListeners();
  }

  /// 将某条消息标记为已撤回/删除（team_recruit_deleted 推送后隐藏卡片）
  void markMessageRecalled(String messageId) {
    if (messageId.isEmpty) return;
    var changed = false;
    messages = messages.map((m) {
      if (m.id != messageId) return m;
      changed = true;
      return m.copyWith(isRecalled: true);
    }).toList();
    if (changed) notifyListeners();
  }

  /// 更新对话
  void updateConversation(String conversationId, Map<String, dynamic> updates) {
    conversations = conversations.map((conv) {
      if (conv.id != conversationId) return conv;
      return conv.copyWith(
        lastMessageTime:
            updates['last_message_time']?.toString() ?? conv.lastMessageTime,
        lastMessageText:
            updates['last_message_text']?.toString() ?? conv.lastMessageText,
        unreadCount: updates.containsKey('unread_count')
            ? (updates['unread_count'] is int
                  ? updates['unread_count'] as int
                  : int.tryParse(updates['unread_count']?.toString() ?? '') ??
                        conv.unreadCount)
            : conv.unreadCount,
      );
    }).toList();

    // 将有新消息的对话移到列表顶部（与 H5 行为一致）
    final idx = conversations.indexWhere((c) => c.id == conversationId);
    if (idx > 0) {
      final conv = conversations.removeAt(idx);
      conversations.insert(0, conv);
    }

    if (currentConversation?.id == conversationId) {
      currentConversation =
          conversations.where((c) => c.id == conversationId).firstOrNull ??
          currentConversation;
    }

    totalUnreadCount = conversations.fold(
      0,
      (sum, conv) => sum + conv.unreadCount,
    );
    notifyListeners();
  }

  /// 更新未读数
  void updateUnreadCount(String conversationId, int count) {
    conversations = conversations.map((conv) {
      if (conv.id != conversationId) return conv;
      return conv.copyWith(unreadCount: count);
    }).toList();
    totalUnreadCount = conversations.fold(
      0,
      (sum, conv) => sum + conv.unreadCount,
    );
    notifyListeners();
  }

  /// 标记对话已读
  void markConversationAsRead(String conversationId) {
    conversations = conversations.map((conv) {
      if (conv.id != conversationId) return conv;
      return conv.copyWith(unreadCount: 0);
    }).toList();
    totalUnreadCount = conversations.fold(
      0,
      (sum, conv) => sum + conv.unreadCount,
    );
    unreadMessageStartIndex = null;
    notifyListeners();
  }

  /// 发送已读回执
  void sendReadReceipt(String conversationId, String messageId) {
    _wsManager.sendMessage({
      'type': WsMessageType.read,
      'data': {'conversation_id': conversationId, 'message_id': messageId},
    });
  }

  /// 发送文本消息
  void sendTextMessage(String conversationId, String content) {
    _wsManager.sendMessage({
      'type': WsMessageType.message,
      'data': {
        'conversation_id': conversationId,
        'content': content,
        'message_type': 'text',
      },
    });
  }

  /// 删除对话
  Future<void> deleteConversation(String conversationId) async {
    await _messageService.hideConversation(conversationId);
    if (currentConversation?.id == conversationId) {
      currentConversation = null;
      messages = [];
    }
    await loadConversations();
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    _wsStateSubscription?.cancel();
    super.dispose();
  }
}
