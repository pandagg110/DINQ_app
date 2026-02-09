import 'package:flutter/material.dart';
import '../services/discover_service.dart';

class ConversationItem {
  ConversationItem({
    required this.id,
    required this.title,
    required this.recordCount,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String title;
  final int recordCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ConversationItem.fromJson(Map<String, dynamic> json) {
    return ConversationItem(
      id: json['id'] as int,
      title: json['title'] as String? ?? 'Untitled',
      recordCount: json['record_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

class ChatHistoryStore extends ChangeNotifier {
  static const int pageSize = 20;

  final DiscoverService _discoverService = DiscoverService();

  List<ConversationItem> conversations = [];
  int total = 0;
  bool isLoading = false;
  int page = 1;
  String searchQuery = '';
  bool isCollapsed = true;
  String? error;
  int? activeConversationId;
  bool isMobileOpen = false;

  bool hasMore() {
    return conversations.length < total;
  }

  Future<void> loadConversations() async {
    if (isLoading) return;

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final response = await _discoverService.getConversations(
        keyword: searchQuery.isEmpty ? null : searchQuery,
        page: 1,
        pageSize: pageSize,
      );

      final rawItems = response['items'];
      final newItems = (rawItems is List<dynamic>)
          ? rawItems
              .map((e) => ConversationItem.fromJson(e as Map<String, dynamic>))
              .toList()
          : <ConversationItem>[];

      conversations = newItems;
      total = (response['total'] is int) ? response['total'] as int : 0;
      page = 1;
    } catch (e) {
      error = e.toString();
      conversations = [];
      total = 0;
      page = 1;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (isLoading || !hasMore()) return;

    isLoading = true;
    notifyListeners();

    try {
      final nextPage = page + 1;
      final response = await _discoverService.getConversations(
        keyword: searchQuery.isEmpty ? null : searchQuery,
        page: nextPage,
        pageSize: pageSize,
      );

      final rawItems = response['items'];
      final newItems = (rawItems is List<dynamic>)
          ? rawItems
              .map((e) => ConversationItem.fromJson(e as Map<String, dynamic>))
              .toList()
          : <ConversationItem>[];

      conversations.addAll(newItems);
      if (response['total'] is int) total = response['total'] as int;
      page = nextPage;
    } catch (e) {
      // 静默失败
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }

  void toggleCollapse() {
    isCollapsed = !isCollapsed;
    notifyListeners();
  }

  void setCollapsed(bool collapsed) {
    isCollapsed = collapsed;
    notifyListeners();
  }

  void setMobileOpen(bool open) {
    isMobileOpen = open;
    notifyListeners();
  }

  void setActiveConversationId(int? id) {
    activeConversationId = id;
    notifyListeners();
  }

  Future<bool> renameConversation(int id, String title) async {
    try {
      await _discoverService.updateConversation(id, {'title': title});

      final index = conversations.indexWhere((item) => item.id == id);
      if (index >= 0) {
        conversations[index] = ConversationItem(
          id: conversations[index].id,
          title: title,
          recordCount: conversations[index].recordCount,
          createdAt: conversations[index].createdAt,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteConversation(int id) async {
    try {
      await _discoverService.deleteConversation(id);

      conversations.removeWhere((item) => item.id == id);
      total = total > 0 ? total - 1 : 0;
      if (activeConversationId == id) {
        activeConversationId = null;
      }
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 获取会话详情（含所有记录），供 SearchStore.loadConversation 使用
  Future<Map<String, dynamic>?> fetchConversationDetail(int id) async {
    try {
      return await _discoverService.getConversationDetail(id);
    } catch (e) {
      return null;
    }
  }

  void addOptimisticConversation(int tempId, {String title = 'Untitled'}) {
    final now = DateTime.now();
    final optimisticConversation = ConversationItem(
      id: tempId,
      title: title,
      recordCount: 0,
      createdAt: now,
      updatedAt: now,
    );
    conversations.insert(0, optimisticConversation);
    activeConversationId = tempId;
    total += 1;
    notifyListeners();
  }

  void updateOptimisticConversation(int tempId, int realId, String title) {
    final index = conversations.indexWhere((item) => item.id == tempId);
    if (index >= 0) {
      final oldItem = conversations[index];
      conversations[index] = ConversationItem(
        id: realId,
        title: title,
        recordCount: oldItem.recordCount + 1,
        createdAt: oldItem.createdAt,
        updatedAt: DateTime.now(),
      );
      
      // 更新活跃会话 ID
      if (activeConversationId == tempId) {
        activeConversationId = realId;
      }
      
      notifyListeners();
    }
  }

  void reset() {
    final wasCollapsed = isCollapsed;
    conversations.clear();
    total = 0;
    isLoading = false;
    page = 1;
    searchQuery = '';
    isCollapsed = wasCollapsed;
    error = null;
    activeConversationId = null;
    notifyListeners();
  }
}
