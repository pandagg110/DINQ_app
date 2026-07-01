import 'dart:async';

import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../models/message_models.dart';
import '../services/message_service.dart';
import '../services/websocket_service.dart';

class NotificationsStore extends ChangeNotifier {
  NotificationsStore() {
    _messageService = MessageService();
    _listenWebSocket();
  }

  late final MessageService _messageService;
  StreamSubscription<Map<String, dynamic>>? _wsSubscription;

  List<AppNotification> notifications = [];
  int unreadCount = 0;
  bool isLoading = false;

  /// 监听 WebSocket 通知消息
  void _listenWebSocket() {
    final wsManager = WebSocketManager.instance;
    _wsSubscription = wsManager.messageStream.listen((wsMessage) {
      final type = wsMessage['type']?.toString() ?? '';
      final rawData = wsMessage['data'];
      final data = rawData is Map ? Map<String, dynamic>.from(rawData) : null;

      if (type == WsMessageType.notification && data != null) {
        addNotification(AppNotification.fromJson(data));
      } else if (type == WsMessageType.notificationUpdate) {
        loadNotifications();
      }
    });
  }

  /// 加载通知列表
  Future<void> loadNotifications({int? page, int? limit}) async {
    isLoading = true;
    notifyListeners();
    try {
      final response = await _messageService.getNotifications(
        limit: limit ?? ApiConfig.notificationsPageSize,
      );
      final notifList = response['notifications'] as List<dynamic>? ?? [];
      notifications = notifList
          .map((n) => AppNotification.fromJson(n as Map<String, dynamic>))
          .toList();
      unreadCount = response['unread_count'] is int
          ? response['unread_count'] as int
          : int.tryParse(response['unread_count']?.toString() ?? '0') ?? 0;
    } catch (e) {
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// 添加新通知
  void addNotification(AppNotification notification) {
    final exists = notifications.any((n) => n.id == notification.id);
    if (!exists) {
      notifications = [notification, ...notifications];
      unreadCount++;
      notifyListeners();
    }
  }

  /// 标记单条通知已读
  void markAsRead(String notificationId) {
    final index = notifications.indexWhere((n) => n.id == notificationId);
    if (index < 0) return;

    final wasUnread = !notifications[index].isRead;
    notifications[index] = notifications[index].copyWith(
      isRead: true,
      readAt: DateTime.now().toIso8601String(),
    );
    if (wasUnread) {
      unreadCount = (unreadCount - 1).clamp(0, unreadCount);
    }
    notifyListeners();
  }

  /// 标记所有通知已读
  Future<void> markAllRead() async {
    try {
      await _messageService.markAllNotificationsRead();
      notifications = notifications
          .map(
            (n) => n.copyWith(
              isRead: true,
              readAt: n.readAt ?? DateTime.now().toIso8601String(),
            ),
          )
          .toList();
      unreadCount = 0;
      notifyListeners();
    } catch (e) {}
  }

  /// 获取通知详情（会自动标记后端已读）
  Future<Map<String, dynamic>> loadNotificationDetail(String id) async {
    markAsRead(id);
    return _messageService.getNotificationDetail(id);
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    super.dispose();
  }
}
