import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/discover_service.dart';
import '../../stores/search_store.dart';

/// 单条搜索消息组（与 TSX MessageGroup 对应）
class AgenticMessageGroup {
  AgenticMessageGroup({
    required this.id,
    required this.userQuery,
    this.loading = true,
    this.candidates = const [],
    this.dinqResults,
  });

  final int id;
  final String userQuery;
  bool loading;
  List<Map<String, dynamic>> candidates;
  List<Map<String, dynamic>>? dinqResults;
}

/// 与 TSX useAgenticSearch 对应：搜索状态与流式/会话逻辑集中在此文件
class AgenticSearchLogic extends ChangeNotifier {
  AgenticSearchLogic({
    required this.discoverService,
    required this.searchStore,
    this.onSearchComplete,
    this.onScrollToBottom,
  });

  final DiscoverService discoverService;
  final SearchStore searchStore;
  final void Function(List<Map<String, dynamic>> candidates, String query)? onSearchComplete;
  final VoidCallback? onScrollToBottom;

  List<AgenticMessageGroup> messageGroups = [];
  bool loading = false;
  bool advisorLoading = false;
  StreamSubscription? _streamSubscription;

  static List<Map<String, dynamic>> _mergeCandidates(
    List<Map<String, dynamic>> oldList,
    List<Map<String, dynamic>> newList,
  ) {
    return newList.asMap().entries.map((entry) {
      final newC = Map<String, dynamic>.from(entry.value);
      final newIndex = entry.key;
      Map<String, dynamic>? existing;
      if (newIndex < oldList.length) {
        final o = oldList[newIndex];
        if (o['name'] == newC['name']) existing = o;
      }
      if (existing == null) {
        for (final c in oldList) {
          if (c['name'] == newC['name']) {
            existing = c;
            break;
          }
        }
      }
      if (existing == null) return newC;
      final merged = Map<String, dynamic>.from(existing);
      for (final k in newC.keys) {
        final nv = newC[k];
        final ov = existing[k];
        if (_valueEquals(ov, nv)) continue;
        merged[k] = nv;
      }
      return merged;
    }).toList();
  }

  static bool _valueEquals(dynamic a, dynamic b) {
    if (a == b) return true;
    if (a is List && b is List) return a.length == b.length && a.toString() == b.toString();
    return false;
  }

  /// 与 TSX loadFromConversation 一致
  void loadFromConversation(Map<String, dynamic> conversation) {
    final records = conversation['records'];
    if (records is! List) return;
    final convId = conversation['id'];
    if (convId != null) {
      final id = convId is int ? convId : int.tryParse(convId.toString());
      if (id != null) searchStore.setCurrentConversationId(id);
    }
    final groups = <AgenticMessageGroup>[];
    for (final r in records) {
      if (r is! Map<String, dynamic>) continue;
      final id = r['id'];
      final query = r['query'] as String? ?? '';
      final searchType = r['search_type'] as String?;
      final result = r['result'];
      List<Map<String, dynamic>> candidates = [];
      List<Map<String, dynamic>>? dinqResults;
      if (result is List) {
        final list = result
            .map((e) => e is Map<String, dynamic> ? Map<String, dynamic>.from(e) : <String, dynamic>{})
            .where((m) => m.isNotEmpty)
            .toList();
        if (searchType == 'people_search') {
          dinqResults = list;
        } else {
          candidates = list;
        }
      }
      final groupId = id is int ? id : (id != null ? int.tryParse(id.toString()) : null) ?? 0;
      groups.add(AgenticMessageGroup(
        id: groupId,
        userQuery: query,
        loading: false,
        candidates: candidates,
        dinqResults: dinqResults,
      ));
    }
    messageGroups = groups;
    loading = false;
    searchStore.loadConversation(conversation);
    notifyListeners();
  }

  /// 与 TSX clearMessages / startNewConversation 一致
  void clearMessages() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    searchStore.setCurrentConversationId(null);
    messageGroups = [];
    loading = false;
    advisorLoading = false;
    notifyListeners();
  }

  /// 与 TSX handleSearch 一致
  void handleSearch({required String query, bool simple = false}) {
    if (query.trim().isEmpty) return;

    searchStore.setIsSearching(true);
    final groupId = DateTime.now().millisecondsSinceEpoch;
    final group = AgenticMessageGroup(
      id: groupId,
      userQuery: query.trim(),
      loading: true,
      candidates: [],
    );

    messageGroups = [...messageGroups, group];
    loading = true;
    notifyListeners();

    final stream = discoverService.chatStream(
      query: query.trim(),
      mode: simple ? 'fast' : 'research',
      conversationId: searchStore.currentConversationId,
    );

    _streamSubscription?.cancel();
    _streamSubscription = stream.listen(
      (event) {
        final type = event['type'] as String?;
        if (type == 'current_results') {
          final data = event['data'];
          final scholars = data is Map ? data['scholars'] : null;
          if (scholars is List) {
            final newCandidates = scholars
                .map((e) => Map<String, dynamic>.from(e as Map<String, dynamic>))
                .toList();
            final idx = messageGroups.indexWhere((g) => g.id == groupId);
            if (idx >= 0) {
              final merged = _mergeCandidates(messageGroups[idx].candidates, newCandidates);
              messageGroups[idx].candidates = merged;
              searchStore.setTabsFromCandidates(merged);
            } else {
              searchStore.setTabsFromCandidates(newCandidates);
            }
            notifyListeners();
          }
        } else if (type == 'search_completed') {
          final idx = messageGroups.indexWhere((g) => g.id == groupId);
          if (idx >= 0) messageGroups[idx].loading = false;
          notifyListeners();
        } else if (type == 'started') {
          final data = event['data'];
          if (data is Map) {
            final convId = data['conversation_id'] ?? data['session_id'];
            if (convId != null) {
              final id = convId is int ? convId : int.tryParse(convId.toString());
              if (id != null) searchStore.setCurrentConversationId(id);
            }
          }
        }
      },
      onDone: () {
        final idx = messageGroups.indexWhere((g) => g.id == groupId);
        final finalCandidates = idx >= 0 ? messageGroups[idx].candidates : <Map<String, dynamic>>[];
        loading = false;
        if (idx >= 0) messageGroups[idx].loading = false;
        onSearchComplete?.call(finalCandidates, query.trim());
        searchStore.setIsSearching(false);
        notifyListeners();
        Future.delayed(const Duration(milliseconds: 100), () => onScrollToBottom?.call());
      },
      onError: (_) {
        loading = false;
        final idx = messageGroups.indexWhere((g) => g.id == groupId);
        if (idx >= 0) messageGroups[idx].loading = false;
        searchStore.setIsSearching(false);
        notifyListeners();
      },
    );
  }

  /// 与 TSX handleDinqSearch 一致
  Future<void> handleDinqSearch(String query) async {
    if (query.trim().isEmpty) return;

    final groupId = DateTime.now().millisecondsSinceEpoch;
    final group = AgenticMessageGroup(
      id: groupId,
      userQuery: query.trim(),
      loading: true,
      candidates: [],
      dinqResults: [],
    );

    messageGroups = [...messageGroups, group];
    loading = true;
    notifyListeners();

    try {
      final response = await discoverService.searchUsers({
        'query': query.trim(),
        'limit': 15,
        if (searchStore.currentConversationId != null)
          'conversation_id': searchStore.currentConversationId,
      });
      final results = response['results'];
      final convId = response['conversation_id'];
      if (convId != null) {
        final id = convId is int ? convId : int.tryParse(convId.toString());
        if (id != null) searchStore.setCurrentConversationId(id);
      }
      final list = results is List
          ? results.map((e) => Map<String, dynamic>.from(e as Map<String, dynamic>)).toList()
          : <Map<String, dynamic>>[];
      final idx = messageGroups.indexWhere((g) => g.id == groupId);
      if (idx >= 0) {
        messageGroups[idx].loading = false;
        messageGroups[idx].dinqResults = list;
      }
    } catch (_) {
      final idx = messageGroups.indexWhere((g) => g.id == groupId);
      if (idx >= 0) messageGroups[idx].loading = false;
    } finally {
      loading = false;
      notifyListeners();
      onScrollToBottom?.call();
    }
  }

  /// 与 TSX handleAdvisorSearch 一致（占位，暂无 advisor 流式 API）
  void handleAdvisorSearch() {
    advisorLoading = true;
    notifyListeners();
    // TODO: 接入 advisor 流式 API
    Future.delayed(const Duration(milliseconds: 100), () {
      advisorLoading = false;
      notifyListeners();
      onScrollToBottom?.call();
    });
  }

  /// 与 TSX handleStop 一致
  void handleStop() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    searchStore.setIsSearching(false);
    loading = false;
    advisorLoading = false;
    for (final g in messageGroups) {
      if (g.loading) g.loading = false;
    }
    notifyListeners();
  }

  /// 仅清空消息列表与 loading（加载历史会话时先清空以显示骨架屏）
  void clearMessagesOnly() {
    messageGroups = [];
    loading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }
}
