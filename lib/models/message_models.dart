import 'package:collection/collection.dart';

/// 消息相关数据模型

// 消息类型
enum MessageType { text, image, emoji }

// 消息状态
enum MessageStatus { sent, delivered, read }

// 对话类型
enum ConversationType { private_, group }

// 成员角色
enum MemberRole { owner, admin, member }

/// 消息实体
class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final MessageType messageType;
  final String content;
  final Map<String, dynamic>? metadata;
  final MessageStatus status;
  final bool isRecalled;
  final String? replyToMessageId;
  final String createdAt;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.messageType,
    required this.content,
    this.metadata,
    required this.status,
    this.isRecalled = false,
    this.replyToMessageId,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id']?.toString() ?? '',
      conversationId: json['conversation_id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      messageType: _parseMessageType(json['message_type']?.toString()),
      content: json['content']?.toString() ?? '',
      metadata: json['metadata'] is Map ? Map<String, dynamic>.from(json['metadata'] as Map) : null,
      status: _parseMessageStatus(json['status']?.toString()),
      isRecalled: json['is_recalled'] == true,
      replyToMessageId: json['reply_to_message_id']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  Message copyWith({MessageStatus? status, bool? isRecalled}) {
    return Message(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      messageType: messageType,
      content: content,
      metadata: metadata,
      status: status ?? this.status,
      isRecalled: isRecalled ?? this.isRecalled,
      replyToMessageId: replyToMessageId,
      createdAt: createdAt,
    );
  }

  static MessageType _parseMessageType(String? type) {
    switch (type) {
      case 'image':
        return MessageType.image;
      case 'emoji':
        return MessageType.emoji;
      default:
        return MessageType.text;
    }
  }

  static MessageStatus _parseMessageStatus(String? status) {
    switch (status) {
      case 'delivered':
        return MessageStatus.delivered;
      case 'read':
        return MessageStatus.read;
      default:
        return MessageStatus.sent;
    }
  }
}

/// 对话成员
class ConversationMember {
  final String id;
  final String userId;
  final MemberRole role;
  final int unreadCount;
  final bool isHidden;
  final String? lastReadMessageId;
  final String? lastReadAt;
  // 用户资料信息
  final String? name;
  final String? username;
  final String? avatarUrl;
  final String? displayName;
  final bool? isOnline;
  final String? position;
  final String? company;
  final String? fullPosition;

  ConversationMember({
    required this.id,
    required this.userId,
    required this.role,
    this.unreadCount = 0,
    this.isHidden = false,
    this.lastReadMessageId,
    this.lastReadAt,
    this.name,
    this.username,
    this.avatarUrl,
    this.displayName,
    this.isOnline,
    this.position,
    this.company,
    this.fullPosition,
  });

  factory ConversationMember.fromJson(Map<String, dynamic> json) {
    return ConversationMember(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      role: _parseRole(json['role']?.toString()),
      unreadCount: json['unread_count'] is int
          ? json['unread_count'] as int
          : int.tryParse(json['unread_count']?.toString() ?? '0') ?? 0,
      isHidden: json['is_hidden'] == true,
      lastReadMessageId: json['last_read_message_id']?.toString(),
      lastReadAt: json['last_read_at']?.toString(),
      name: json['name']?.toString(),
      username: json['username']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
      displayName: json['display_name']?.toString(),
      isOnline: json['is_online'] == true,
      position: json['position']?.toString(),
      company: json['company']?.toString(),
      fullPosition: json['full_position']?.toString(),
    );
  }

  ConversationMember copyWith({
    String? lastReadMessageId,
    int? unreadCount,
  }) {
    return ConversationMember(
      id: id,
      userId: userId,
      role: role,
      unreadCount: unreadCount ?? this.unreadCount,
      isHidden: isHidden,
      lastReadMessageId: lastReadMessageId ?? this.lastReadMessageId,
      lastReadAt: lastReadAt,
      name: name,
      username: username,
      avatarUrl: avatarUrl,
      displayName: displayName,
      isOnline: isOnline,
      position: position,
      company: company,
      fullPosition: fullPosition,
    );
  }

  static MemberRole _parseRole(String? role) {
    switch (role) {
      case 'owner':
        return MemberRole.owner;
      case 'admin':
        return MemberRole.admin;
      default:
        return MemberRole.member;
    }
  }
}

/// 对话实体
class Conversation {
  final String id;
  final ConversationType conversationType;
  final String? groupName;
  final String createdAt;
  final String updatedAt;
  final String? lastMessageAt;
  final String? lastMessageId;
  final String? lastMessageTime;
  final String? lastMessageText;
  final int unreadCount;
  final Map<String, bool>? onlineStatus;
  final List<ConversationMember> members;
  final List<String>? tags;

  Conversation({
    required this.id,
    required this.conversationType,
    this.groupName,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessageAt,
    this.lastMessageId,
    this.lastMessageTime,
    this.lastMessageText,
    this.unreadCount = 0,
    this.onlineStatus,
    required this.members,
    this.tags,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final membersJson = json['members'] as List<dynamic>? ?? [];
    final tagsJson = json['tags'] as List<dynamic>?;

    Map<String, bool>? onlineStatus;
    if (json['online_status'] is Map) {
      onlineStatus = {};
      final osMap = json['online_status'] as Map;
      for (final entry in osMap.entries) {
        onlineStatus[entry.key.toString()] = entry.value == true;
      }
    }

    return Conversation(
      id: json['id']?.toString() ?? '',
      conversationType: json['conversation_type']?.toString() == 'group'
          ? ConversationType.group
          : ConversationType.private_,
      groupName: json['group_name']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
      lastMessageAt: json['last_message_at']?.toString(),
      lastMessageId: json['last_message_id']?.toString(),
      lastMessageTime: json['last_message_time']?.toString(),
      lastMessageText: json['last_message_text']?.toString(),
      unreadCount: json['unread_count'] is int
          ? json['unread_count'] as int
          : int.tryParse(json['unread_count']?.toString() ?? '0') ?? 0,
      onlineStatus: onlineStatus,
      members: membersJson.map((m) => ConversationMember.fromJson(m as Map<String, dynamic>)).toList(),
      tags: tagsJson?.map((t) => t.toString()).toList(),
    );
  }

  Conversation copyWith({
    String? lastMessageTime,
    String? lastMessageText,
    String? lastMessageId,
    int? unreadCount,
    List<ConversationMember>? members,
  }) {
    return Conversation(
      id: id,
      conversationType: conversationType,
      groupName: groupName,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastMessageAt: lastMessageAt,
      lastMessageId: lastMessageId ?? this.lastMessageId,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessageText: lastMessageText ?? this.lastMessageText,
      unreadCount: unreadCount ?? this.unreadCount,
      onlineStatus: onlineStatus,
      members: members ?? this.members,
      tags: tags,
    );
  }
}

/// 通知实体
class AppNotification {
  final String id;
  final String userId;
  final String notificationType;
  final String title;
  final String content;
  final bool isRead;
  final String? readAt;
  final int priority;
  final Map<String, dynamic>? metadata;
  final String? expiresAt;
  final String createdAt;
  final String updatedAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.notificationType,
    required this.title,
    required this.content,
    this.isRead = false,
    this.readAt,
    this.priority = 0,
    this.metadata,
    this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      notificationType: json['notification_type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      isRead: json['is_read'] == true,
      readAt: json['read_at']?.toString(),
      priority: json['priority'] is int
          ? json['priority'] as int
          : int.tryParse(json['priority']?.toString() ?? '0') ?? 0,
      metadata: json['metadata'] is Map ? Map<String, dynamic>.from(json['metadata'] as Map) : null,
      expiresAt: json['expires_at']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }

  AppNotification copyWith({bool? isRead, String? readAt}) {
    return AppNotification(
      id: id,
      userId: userId,
      notificationType: notificationType,
      title: title,
      content: content,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      priority: priority,
      metadata: metadata,
      expiresAt: expiresAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// 获取对话的显示信息
class ConversationDisplay {
  final String name;
  final String? avatar;
  final bool isOnline;

  ConversationDisplay({
    required this.name,
    this.avatar,
    this.isOnline = false,
  });
}

ConversationDisplay getConversationDisplay(Conversation conversation, String currentUserId) {
  final isGroup = conversation.conversationType == ConversationType.group;
  final otherMember = conversation.members.where((m) => m.userId != currentUserId).firstOrNull;

  if (isGroup) {
    return ConversationDisplay(
      name: conversation.groupName ?? 'Group Chat',
      avatar: null,
      isOnline: false,
    );
  }

  final name = otherMember?.name ?? otherMember?.displayName ?? otherMember?.username ?? 'Unknown User';
  final avatar = otherMember?.avatarUrl;
  final isOnline = conversation.onlineStatus != null && otherMember != null
      ? (conversation.onlineStatus![otherMember.userId] ?? false)
      : false;

  return ConversationDisplay(name: name, avatar: avatar, isOnline: isOnline);
}

/// 格式化消息时间
String formatMessageDate(String? timestamp) {
  if (timestamp == null || timestamp.isEmpty) return '';

  final date = DateTime.tryParse(timestamp);
  if (date == null) return '';

  final now = DateTime.now();
  final diff = now.difference(date);
  final days = diff.inDays;

  // 今天 - 显示时间
  if (days == 0 && date.day == now.day) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // 3天内 - 显示 X days ago
  if (days > 0 && days <= 3) {
    return '$days day${days > 1 ? 's' : ''} ago';
  }

  // 更早 - 显示月日
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[date.month - 1]} ${date.day}';
}

/// 获取日期分割文本
String getDateDividerText(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final dateOnly = DateTime(date.year, date.month, date.day);

  if (dateOnly == today) return 'Today';
  if (dateOnly == today.subtract(const Duration(days: 1))) return 'Yesterday';

  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}
