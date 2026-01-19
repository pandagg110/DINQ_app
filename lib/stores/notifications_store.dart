import 'package:flutter/material.dart';
import '../services/message_service.dart';

class NotificationsStore extends ChangeNotifier {
  NotificationsStore() {
    _messageService = MessageService();
  }

  late final MessageService _messageService;

  List<dynamic> notifications = [];
  bool isLoading = false;

  Future<void> loadNotifications({int? page, int? limit}) async {
    isLoading = true;
    notifyListeners();
    try {
      final response = await _messageService.getNotifications(page: page, limit: limit);
      notifications = response['notifications'] as List<dynamic>? ?? [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> loadNotificationDetail(String id) async {
    return _messageService.getNotificationDetail(id);
  }

  Future<void> markAllRead() async {
    await _messageService.markAllNotificationsRead();
  }
}


