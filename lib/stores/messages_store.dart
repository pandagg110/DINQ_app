import 'package:flutter/material.dart';
import '../services/message_service.dart';

class MessagesStore extends ChangeNotifier {
  MessagesStore() {
    _messageService = MessageService();
  }

  late final MessageService _messageService;

  List<dynamic> conversations = [];
  Map<String, List<dynamic>> messagesByConversation = {};
  bool isLoading = false;

  Future<void> loadConversations({String? search}) async {
    isLoading = true;
    notifyListeners();
    try {
      final response = await _messageService.getConversations(search: search);
      conversations = response['conversations'] as List<dynamic>? ?? [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMessages(String conversationId, {int? limit, int? offset}) async {
    isLoading = true;
    notifyListeners();
    try {
      final response = await _messageService.getMessages(conversationId, limit: limit, offset: offset);
      messagesByConversation[conversationId] = response['messages'] as List<dynamic>? ?? [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}


