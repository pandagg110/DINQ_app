import 'package:flutter/material.dart';

import '../services/history_service.dart';
import '../services/search_service.dart';

class ConversationItem {
  ConversationItem({
    required this.id,
    required this.title,
    required this.type,
    required this.recordCount,
    required this.createdAt,
    required this.updatedAt,
  });

  final Object id;
  final String title;
  final String type;
  final int recordCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get key => '$type-$id';

  factory ConversationItem.fromJson(Map<String, dynamic> json) {
    return ConversationItem(
      id: json['id'] ?? '',
      title: json['title'] as String? ?? 'Untitled',
      type: json['type'] as String? ?? 'discover',
      recordCount: json['record_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.parse(json['created_at'] as String),
    );
  }
}

class ChatHistoryStore extends ChangeNotifier {
  static const int pageSize = 20;

  final HistoryService _historyService = HistoryService();
  final SearchService _searchService = SearchService();

  List<ConversationItem> conversations = [];
  int total = 0;
  bool hasMoreResults = false;
  bool isLoading = false;
  int offset = 0;
  String searchQuery = '';
  bool isCollapsed = true;
  String? error;
  String? activeConversationKey;
  bool isMobileOpen = false;

  bool hasMore() => hasMoreResults;

  bool isActiveConversation(ConversationItem item) {
    return activeConversationKey == item.key;
  }

  Future<void> loadConversations([String? query]) async {
    if (isLoading) return;

    final nextQuery = query ?? searchQuery;
    isLoading = true;
    error = null;
    searchQuery = nextQuery;
    notifyListeners();

    try {
      final response = await _historyService.getConversations(
        keyword: nextQuery.isEmpty ? null : nextQuery,
        limit: pageSize,
        offset: 0,
      );

      final rawConversations = response['conversations'];
      final newItems = (rawConversations is List<dynamic>)
          ? rawConversations
              .map((e) => ConversationItem.fromJson(e as Map<String, dynamic>))
              .toList()
          : <ConversationItem>[];

      conversations = newItems;
      final backendTotal = response['total'] is int
          ? response['total'] as int
          : newItems.length;
      total = backendTotal;
      offset = newItems.length;
      hasMoreResults = offset < backendTotal;
    } catch (e) {
      error = e.toString();
      conversations = [];
      total = 0;
      offset = 0;
      hasMoreResults = false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (isLoading || !hasMoreResults) return;

    isLoading = true;
    notifyListeners();

    try {
      final response = await _historyService.getConversations(
        keyword: searchQuery.isEmpty ? null : searchQuery,
        limit: pageSize,
        offset: offset,
      );

      final existingKeys = conversations.map((c) => c.key).toSet();
      final rawConversations = response['conversations'];
      final rawItems = (rawConversations is List<dynamic>)
          ? rawConversations
              .map((e) => ConversationItem.fromJson(e as Map<String, dynamic>))
              .toList()
          : <ConversationItem>[];
      final incoming =
          rawItems.where((c) => !existingKeys.contains(c.key)).toList();

      conversations = [...conversations, ...incoming];
      final backendTotal =
          response['total'] is int ? response['total'] as int : total;
      total = backendTotal;
      final nextOffset = offset + rawItems.length;
      offset = nextOffset;
      hasMoreResults = rawItems.isNotEmpty && nextOffset < backendTotal;
    } catch (_) {
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

  void setActiveConversation(ConversationItem? item) {
    activeConversationKey = item?.key;
    notifyListeners();
  }

  /// 兼容旧调用：只传 id 时默认按 discover 类型生成 key
  void setActiveConversationId(Object? id, {String type = 'discover'}) {
    if (id == null) {
      activeConversationKey = null;
    } else {
      activeConversationKey = '$type-$id';
    }
    notifyListeners();
  }

  void setActiveConversationKey(String? key) {
    activeConversationKey = key;
    notifyListeners();
  }

  /// 兼容旧调用：按 id 删除（优先列表中已有项的真实 type）
  Future<bool> deleteConversationById(Object id, {String type = 'discover'}) async {
    ConversationItem? item;
    for (final c in conversations) {
      if (c.id == id) {
        item = c;
        break;
      }
    }

    final target = item ??
        ConversationItem(
      id: id,
      title: '',
      type: type,
      recordCount: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return deleteConversation(target);
  }

  Future<bool> deleteConversation(ConversationItem conversation) async {
    try {
      await _historyService.deleteConversation(
        conversation.type,
        conversation.id,
      );

      conversations =
          conversations.where((item) => item.key != conversation.key).toList();
      total = total > 0 ? total - 1 : 0;
      if (activeConversationKey == conversation.key) {
        activeConversationKey = null;
      }
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 目前仅 discover 支持重命名（沿用旧接口）
  Future<bool> renameConversation(Object id, String title, {String type = 'discover'}) async {
    if (type != 'discover') return false;
    final intId = int.tryParse(id.toString());
    if (intId == null) return false;

    try {
      await _searchService.updateConversation(intId, {'title': title});
      final index = conversations.indexWhere((item) => item.id == id);
      if (index >= 0) {
        final old = conversations[index];
        conversations[index] = ConversationItem(
          id: old.id,
          title: title,
          type: old.type,
          recordCount: old.recordCount,
          createdAt: old.createdAt,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 获取会话详情（含所有记录），供 SearchStore / AgenticChat 使用
  Future<Map<String, dynamic>?> fetchConversationDetail(
    Object id, [
    String type = 'discover',
  ]) async {
    try {
      return await _historyService.getConversationDetail(type, id);
    } catch (e) {
      return null;
    }
  }

  void addOptimisticConversation(int tempId, {String title = 'Untitled'}) {
    final now = DateTime.now();
    final optimisticConversation = ConversationItem(
      id: tempId,
      title: title,
      type: 'discover',
      recordCount: 0,
      createdAt: now,
      updatedAt: now,
    );
    conversations.insert(0, optimisticConversation);
    activeConversationKey = optimisticConversation.key;
    total += 1;
    notifyListeners();
  }

  void updateOptimisticConversation(int tempId, Object realId, String title) {
    final tempKey = 'discover-$tempId';
    final index = conversations.indexWhere((item) => item.key == tempKey);
    if (index >= 0) {
      final oldItem = conversations[index];
      final updated = ConversationItem(
        id: realId,
        title: title,
        type: oldItem.type,
        recordCount: oldItem.recordCount + 1,
        createdAt: oldItem.createdAt,
        updatedAt: DateTime.now(),
      );
      conversations[index] = updated;

      if (activeConversationKey == tempKey) {
        activeConversationKey = updated.key;
      }

      notifyListeners();
    }
  }

  void reset() {
    final wasCollapsed = isCollapsed;
    conversations.clear();
    total = 0;
    hasMoreResults = false;
    isLoading = false;
    offset = 0;
    searchQuery = '';
    isCollapsed = wasCollapsed;
    error = null;
    activeConversationKey = null;
    notifyListeners();
  }
}
