import 'package:flutter/material.dart';

import '../services/history_service.dart';
import '../utils/api_error.dart';

/// 与 Web `ConversationSearchState` 对齐
typedef ConversationSearchState = String; // running | completed | empty

class ConversationItem {
  ConversationItem({
    required this.id,
    required this.title,
    required this.type,
    required this.recordCount,
    required this.createdAt,
    required this.updatedAt,
    this.isRunning = false,
    this.searchState,
    this.searchStartedAt,
    this.searchFinishedAt,
    this.isLocalPending = false,
    this.isRead,
    this.hasUnseenCompletion = false,
    this.localStatusSettledAt,
  });

  final Object id;
  final String title;
  final String type;
  final int recordCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isRunning;
  final ConversationSearchState? searchState;
  final DateTime? searchStartedAt;
  final DateTime? searchFinishedAt;
  final bool isLocalPending;
  final bool? isRead;
  final bool hasUnseenCompletion;

  /// 客户端本地字段，对齐 Web `local_status_settled_at`
  final DateTime? localStatusSettledAt;

  String get key => '$type-$id';

  /// 与 Web `getConversationSearchState` 对齐
  ConversationSearchState? get effectiveSearchState {
    if (isLocalPending) return 'running';
    return serverSearchState;
  }

  /// 仅服务端状态；当前会话的后台 processing 判定不能使用 local pending。
  ConversationSearchState? get serverSearchState {
    if (searchState != null && searchState!.isNotEmpty) return searchState;
    if (isRunning) return 'running';
    return null;
  }

  ConversationItem copyWith({
    Object? id,
    String? title,
    String? type,
    int? recordCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isRunning,
    ConversationSearchState? searchState,
    bool clearSearchState = false,
    DateTime? searchStartedAt,
    bool clearSearchStartedAt = false,
    DateTime? searchFinishedAt,
    bool clearSearchFinishedAt = false,
    bool? isLocalPending,
    bool? isRead,
    bool? hasUnseenCompletion,
    DateTime? localStatusSettledAt,
    bool clearLocalStatusSettledAt = false,
  }) {
    return ConversationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      recordCount: recordCount ?? this.recordCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isRunning: isRunning ?? this.isRunning,
      searchState: clearSearchState ? null : (searchState ?? this.searchState),
      searchStartedAt: clearSearchStartedAt
          ? null
          : (searchStartedAt ?? this.searchStartedAt),
      searchFinishedAt: clearSearchFinishedAt
          ? null
          : (searchFinishedAt ?? this.searchFinishedAt),
      isLocalPending: isLocalPending ?? this.isLocalPending,
      isRead: isRead ?? this.isRead,
      hasUnseenCompletion: hasUnseenCompletion ?? this.hasUnseenCompletion,
      localStatusSettledAt: clearLocalStatusSettledAt
          ? null
          : (localStatusSettledAt ?? this.localStatusSettledAt),
    );
  }

  static DateTime _parseDate(dynamic value, [DateTime? fallback]) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value) ?? fallback ?? DateTime.now();
    }
    return fallback ?? DateTime.now();
  }

  static DateTime? _parseOptionalDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  static int _parseInt(dynamic value, [int fallback = 0]) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  factory ConversationItem.fromJson(Map<String, dynamic> json) {
    final createdAt = _parseDate(json['created_at']);
    final searchStateRaw = json['search_state']?.toString();
    final isReadRaw = json['is_read'];
    return ConversationItem(
      id: json['id'] ?? '',
      title: json['title'] as String? ?? 'Untitled',
      type: json['type'] as String? ?? 'discover',
      recordCount: _parseInt(json['record_count']),
      createdAt: createdAt,
      updatedAt: _parseDate(json['updated_at'], createdAt),
      isRunning: json['is_running'] == true,
      searchState: (searchStateRaw != null && searchStateRaw.isNotEmpty)
          ? searchStateRaw
          : null,
      searchStartedAt: _parseOptionalDate(json['search_started_at']),
      searchFinishedAt: _parseOptionalDate(json['search_finished_at']),
      isLocalPending: json['is_local_pending'] == true,
      isRead: isReadRaw is bool ? isReadRaw : null,
      hasUnseenCompletion: json['has_unseen_completion'] == true,
      localStatusSettledAt: _parseOptionalDate(json['local_status_settled_at']),
    );
  }
}

class ChatHistoryStore extends ChangeNotifier {
  ChatHistoryStore({HistoryService? historyService})
    : _historyService = historyService ?? HistoryService();

  static const int pageSize = 20;
  static const String searchConversationType = 'discover';

  final HistoryService _historyService;
  final Map<String, Future<bool>> _discoverReadRequests = {};
  final Map<String, ConversationItem?> _pendingDiscoverBaselines = {};
  final Map<String, ConversationItem> _pendingDiscoverItems = {};
  final Map<String, int> _pendingDiscoverRevisions = {};
  Future<List<ConversationItem>>? _topRefreshInFlight;
  List<ConversationItem>? _latestTopConversations;
  int _nextPendingDiscoverRevision = 0;
  int _loadRequestEpoch = 0;
  int _topRefreshRequestEpoch = 0;
  int _unfilteredMutationEpoch = 0;

  List<ConversationItem> conversations = [];

  /// 与 Web `backgroundDiscoverQueries` 对齐：切走后仍能拿回占位 query
  final Map<String, ({String query, DateTime updatedAt})>
  backgroundDiscoverQueries = {};

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

  ConversationItem? findDiscoverById(Object id) {
    final idStr = id.toString();
    for (final c in conversations) {
      if (c.type == searchConversationType && c.id.toString() == idStr) {
        return c;
      }
    }
    return null;
  }

  ConversationSearchState? discoverSearchState(Object id) {
    return findDiscoverById(id)?.effectiveSearchState;
  }

  ConversationSearchState? discoverServerSearchState(Object id) {
    return findDiscoverById(id)?.serverSearchState;
  }

  String? backgroundDiscoverQuery(Object id) {
    return backgroundDiscoverQueries[id.toString()]?.query;
  }

  int? pendingDiscoverRevision(Object id) {
    return _pendingDiscoverRevisions[id.toString()];
  }

  /// 不受 history 关键字过滤影响的本地 pending 集合，供全局状态 monitor
  /// 持续轮询尚未被服务端首屏确认的会话。
  List<ConversationItem> get pendingDiscoverConversations =>
      List<ConversationItem>.unmodifiable(_pendingDiscoverItems.values);

  ConversationItem? _latestTopDiscoverById(String id) {
    final latest = _latestTopConversations;
    if (latest == null) return null;
    for (final item in latest) {
      if (item.type == searchConversationType && item.id.toString() == id) {
        return item;
      }
    }
    return null;
  }

  /// 判断原始服务端行是否已经发生了足以代表“当前 pending 轮次”的变化。
  /// 同 session 新一轮开始时，旧 completed 行本来就存在，不能仅凭 key
  /// 出现在 `/history` 中就清除新 pending。
  bool serverItemConfirmsPendingDiscoverSession(
    ConversationItem serverItem, {
    int? expectedRevision,
  }) {
    if (serverItem.type != searchConversationType) return false;
    final id = serverItem.id.toString();
    if (expectedRevision != null &&
        _pendingDiscoverRevisions[id] != expectedRevision) {
      return false;
    }
    final hasPending =
        _pendingDiscoverItems.containsKey(id) ||
        _pendingDiscoverRevisions.containsKey(id) ||
        conversations.any(
          (item) =>
              item.type == searchConversationType &&
              item.id.toString() == id &&
              item.isLocalPending,
        );
    if (!hasPending) return false;

    final baseline = _pendingDiscoverBaselines[id];
    if (baseline == null) return true;
    if (serverItem.serverSearchState != baseline.serverSearchState) return true;
    if (serverItem.isRunning != baseline.isRunning) return true;
    if (serverItem.recordCount != baseline.recordCount) return true;
    return serverItem.updatedAt.isAfter(baseline.updatedAt);
  }

  /// 最近一次成功的、未经过本地 pending 合并的服务端首屏快照。
  ///
  /// history 列表会保留已经翻页加载的旧行，因此全局状态轮询不能直接把
  /// `conversations` 当作服务端 top 20。该快照用于严格对齐 Web monitor
  /// 对 `refreshTopConversations()` 原始返回值的处理，同时仍允许本地
  /// pending 作为额外覆盖层继续轮询。
  List<ConversationItem>? get latestTopConversations => _latestTopConversations;

  void _setLatestTopConversations(List<ConversationItem> items) {
    _latestTopConversations = List<ConversationItem>.unmodifiable(
      _filterSearchConversations(items),
    );
  }

  List<ConversationItem> _parseConversations(dynamic raw) {
    if (raw is! List) return const [];
    final items = <ConversationItem>[];
    for (final e in raw) {
      if (e is! Map) continue;
      try {
        items.add(ConversationItem.fromJson(Map<String, dynamic>.from(e)));
      } catch (_) {
        // skip malformed
      }
    }
    return items;
  }

  List<ConversationItem> _filterSearchConversations(
    List<ConversationItem> items,
  ) {
    return items
        .where((c) => c.type == searchConversationType)
        .toList(growable: false);
  }

  List<ConversationItem> _pendingConversations([
    List<ConversationItem>? source,
  ]) {
    final byKey = <String, ConversationItem>{
      for (final item in _pendingDiscoverItems.values) item.key: item,
    };
    for (final item in source ?? conversations) {
      if (item.isLocalPending && item.type == searchConversationType) {
        byKey.putIfAbsent(item.key, () => item);
      }
    }
    return byKey.values.toList(growable: false);
  }

  List<ConversationItem> _mergeWithPending(
    List<ConversationItem> incoming, {
    required List<ConversationItem> pending,
    List<ConversationItem> current = const [],
  }) {
    final visibleIncoming = _filterSearchConversations(incoming);
    final visiblePending = _filterSearchConversations(pending);
    final visibleCurrent = _filterSearchConversations(current);
    final incomingKeys = visibleIncoming.map((c) => c.key).toSet();
    final pendingKeys = visiblePending.map((c) => c.key).toSet();
    final pendingByKey = {for (final p in visiblePending) p.key: p};

    final mergedIncoming = visibleIncoming.map((item) {
      final pendingItem = pendingByKey[item.key];
      if (pendingItem == null) return item;
      return item.copyWith(isLocalPending: true);
    }).toList();

    return [
      ...visiblePending.where((p) => !incomingKeys.contains(p.key)),
      ...mergedIncoming,
      ...visibleCurrent.where(
        (c) => !incomingKeys.contains(c.key) && !pendingKeys.contains(c.key),
      ),
    ];
  }

  Future<void> loadConversations([String? query]) async {
    if (isLoading) return;

    final nextQuery = query ?? searchQuery;
    final requestEpoch = ++_loadRequestEpoch;
    final mutationEpoch = nextQuery.isEmpty ? ++_unfilteredMutationEpoch : null;
    isLoading = true;
    error = null;
    searchQuery = nextQuery;
    notifyListeners();

    try {
      final response = await _historyService.getConversations(
        keyword: nextQuery.isEmpty ? null : nextQuery,
        limit: pageSize,
        offset: 0,
        type: searchConversationType,
      );

      final rawIncoming = _parseConversations(response['conversations']);
      if (requestEpoch != _loadRequestEpoch) return;
      if (mutationEpoch != null && mutationEpoch != _unfilteredMutationEpoch) {
        return;
      }
      if (nextQuery.isEmpty) {
        _setLatestTopConversations(rawIncoming);
      }
      final newItems = nextQuery.isNotEmpty
          ? _filterSearchConversations(rawIncoming)
          : _mergeWithPending(
              rawIncoming,
              pending: _pendingConversations(conversations),
            );

      conversations = newItems;
      final backendTotal = ConversationItem._parseInt(
        response['total'],
        rawIncoming.length,
      );
      total = backendTotal;
      offset = rawIncoming.length;
      hasMoreResults = offset < backendTotal;
    } catch (e) {
      if (requestEpoch == _loadRequestEpoch) {
        error = apiErrorMessage(e, fallback: 'Failed to load history');
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// 与 Web `refreshTopConversations` 对齐：后台轮询时不打断 loading 态
  Future<List<ConversationItem>> refreshTopConversations({
    int limit = pageSize,
    bool rethrowErrors = false,
  }) async {
    final existing = _topRefreshInFlight;
    final request = existing ?? _refreshTopConversations(limit);
    if (existing == null) _topRefreshInFlight = request;

    try {
      return await request;
    } catch (_) {
      if (rethrowErrors) rethrow;
      return const [];
    } finally {
      if (identical(_topRefreshInFlight, request)) {
        _topRefreshInFlight = null;
      }
    }
  }

  Future<List<ConversationItem>> _refreshTopConversations(int limit) async {
    final requestEpoch = ++_topRefreshRequestEpoch;
    final mutationEpoch = ++_unfilteredMutationEpoch;
    final response = await _historyService.getConversations(
      limit: limit,
      offset: 0,
      type: searchConversationType,
    );
    final rawIncoming = _parseConversations(response['conversations']);
    if (requestEpoch != _topRefreshRequestEpoch) return const [];
    _setLatestTopConversations(rawIncoming);

    final backendTotal = ConversationItem._parseInt(
      response['total'],
      rawIncoming.length,
    );

    if (searchQuery.isNotEmpty) {
      return _filterSearchConversations(rawIncoming);
    }
    if (mutationEpoch != _unfilteredMutationEpoch) {
      return _filterSearchConversations(rawIncoming);
    }

    conversations = _mergeWithPending(
      rawIncoming,
      pending: _pendingConversations(conversations),
      current: conversations,
    );
    offset = offset < rawIncoming.length ? rawIncoming.length : offset;
    total = backendTotal;
    hasMoreResults = offset < backendTotal;
    error = null;
    notifyListeners();
    return _filterSearchConversations(rawIncoming);
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
        type: searchConversationType,
      );

      final existingKeys = conversations.map((c) => c.key).toSet();
      final rawItems = _parseConversations(response['conversations']);
      final incoming = _filterSearchConversations(
        rawItems,
      ).where((c) => !existingKeys.contains(c.key)).toList();

      conversations = [...conversations, ...incoming];
      final backendTotal = ConversationItem._parseInt(response['total'], total);
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

  /// 与 Web `upsertPendingDiscoverSession` 对齐
  int? upsertPendingDiscoverSession({
    required String sessionId,
    required String title,
  }) {
    final id = sessionId.trim();
    final nextTitle = title.trim();
    if (id.isEmpty || nextTitle.isEmpty) return null;

    final now = DateTime.now();
    final revision = ++_nextPendingDiscoverRevision;
    _pendingDiscoverRevisions[id] = revision;
    backgroundDiscoverQueries[id] = (query: nextTitle, updatedAt: now);

    final key = 'discover-$id';
    final index = conversations.indexWhere((c) => c.key == key);
    final visibleItem = index >= 0 ? conversations[index] : null;
    _pendingDiscoverBaselines[id] =
        _latestTopDiscoverById(id) ??
        (visibleItem != null && !visibleItem.isLocalPending
            ? visibleItem
            : _pendingDiscoverBaselines[id]);
    late final ConversationItem pendingItem;
    if (index >= 0) {
      pendingItem = conversations[index].copyWith(
        updatedAt: now,
        isLocalPending: true,
        clearLocalStatusSettledAt: true,
      );
      conversations[index] = pendingItem;
    } else {
      final existingPending = _pendingDiscoverItems[id];
      pendingItem = existingPending != null
          ? existingPending.copyWith(
              title: nextTitle,
              updatedAt: now,
              isLocalPending: true,
            )
          : ConversationItem(
              id: id,
              title: nextTitle,
              type: searchConversationType,
              recordCount: 0,
              createdAt: now,
              updatedAt: now,
              isLocalPending: true,
            );
      conversations.insert(0, pendingItem);
    }
    _pendingDiscoverItems[id] = pendingItem;
    notifyListeners();
    return revision;
  }

  /// 搜索流正常结束 / 用户 Stop 时清理本地 pending 标记
  void clearPendingDiscoverSession(String sessionId, {int? expectedRevision}) {
    final id = sessionId.trim();
    if (id.isEmpty) return;
    if (expectedRevision != null &&
        _pendingDiscoverRevisions[id] != expectedRevision) {
      return;
    }

    var changed = _pendingDiscoverItems.remove(id) != null;
    _pendingDiscoverBaselines.remove(id);
    conversations = conversations
        .map((conversation) {
          if (conversation.type != searchConversationType ||
              conversation.id.toString() != id ||
              !conversation.isLocalPending) {
            return conversation;
          }
          changed = true;
          if (conversation.recordCount == 0 &&
              conversation.searchState == null &&
              !conversation.isRunning) {
            return null;
          }
          return conversation.copyWith(isLocalPending: false);
        })
        .whereType<ConversationItem>()
        .toList();
    _pendingDiscoverRevisions.remove(id);
    if (changed) notifyListeners();
  }

  /// 后端列表已确认会话存在后，才把 detached 会话从本地 pending 交接给
  /// `search_state` / `is_running`。首轮 eventual-consistency 响应缺失时不会
  /// 删除占位，因此全局 monitor 仍能继续轮询。
  void clearServerConfirmedPendingDiscoverSessions(
    Iterable<ConversationItem> serverItems, {
    Set<String> excludedKeys = const <String>{},
  }) {
    final confirmedItems = serverItems
        .where((item) => item.type == searchConversationType)
        .where((item) => !excludedKeys.contains(item.key))
        .where(serverItemConfirmsPendingDiscoverSession)
        .toList(growable: false);
    if (confirmedItems.isEmpty) return;
    final confirmedKeys = confirmedItems.map((item) => item.key).toSet();
    final confirmedIds = confirmedItems
        .map((item) => item.id.toString())
        .toSet();

    var changed = false;
    final next = conversations.map((conversation) {
      if (!conversation.isLocalPending ||
          !confirmedKeys.contains(conversation.key)) {
        return conversation;
      }
      changed = true;
      return conversation.copyWith(isLocalPending: false);
    }).toList();

    for (final id in confirmedIds) {
      if (_pendingDiscoverItems.remove(id) != null) changed = true;
      _pendingDiscoverBaselines.remove(id);
      if (_pendingDiscoverRevisions.remove(id) != null) changed = true;
    }
    if (!changed) return;
    conversations = next;
    notifyListeners();
  }

  void clearBackgroundDiscoverQuery(Object sessionId) {
    final id = sessionId.toString().trim();
    if (id.isEmpty) return;
    if (backgroundDiscoverQueries.remove(id) != null) {
      notifyListeners();
    }
  }

  Future<bool> markDiscoverSessionRead(Object sessionId) {
    final id = sessionId.toString().trim();
    if (id.isEmpty) return Future.value(false);
    if (conversations.any(
      (conversation) =>
          conversation.type == searchConversationType &&
          conversation.id.toString() == id &&
          conversation.isRead == true,
    )) {
      return Future.value(true);
    }

    final inFlight = _discoverReadRequests[id];
    if (inFlight != null) return inFlight;

    final request = () async {
      try {
        await _historyService.markDiscoverSessionRead(id);
        conversations = conversations.map((conversation) {
          if (conversation.type != searchConversationType ||
              conversation.id.toString() != id) {
            return conversation;
          }
          return conversation.copyWith(
            isRead: true,
            hasUnseenCompletion: false,
            clearLocalStatusSettledAt: true,
          );
        }).toList();
        notifyListeners();
        return true;
      } catch (_) {
        return false;
      } finally {
        _discoverReadRequests.remove(id);
      }
    }();
    _discoverReadRequests[id] = request;
    return request;
  }

  /// 与 Web `markDiscoverSessionLocalSettled` 对齐：后台完成后本地标记未读
  void markDiscoverSessionLocalSettled(Object sessionId) {
    final id = sessionId.toString().trim();
    if (id.isEmpty) return;

    var changed = false;
    conversations = conversations.map((conversation) {
      if (conversation.type != searchConversationType ||
          conversation.id.toString() != id) {
        return conversation;
      }
      changed = true;
      return conversation.copyWith(
        isLocalPending: false,
        isRead: false,
        hasUnseenCompletion: true,
        localStatusSettledAt: conversation.updatedAt,
      );
    }).toList();
    if (changed) notifyListeners();
  }

  /// 兼容旧调用：按 id 删除（优先列表中已有项的真实 type）
  Future<bool> deleteConversationById(
    Object id, {
    String type = 'discover',
  }) async {
    ConversationItem? item;
    for (final c in conversations) {
      if (c.id == id) {
        item = c;
        break;
      }
    }

    final target =
        item ??
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

      conversations = conversations
          .where((item) => item.key != conversation.key)
          .toList();
      total = total > 0 ? total - 1 : 0;
      if (activeConversationKey == conversation.key) {
        activeConversationKey = null;
      }
      backgroundDiscoverQueries.remove(conversation.id.toString());
      _pendingDiscoverBaselines.remove(conversation.id.toString());
      _pendingDiscoverItems.remove(conversation.id.toString());
      _pendingDiscoverRevisions.remove(conversation.id.toString());
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 与 Web `renameConversation` 对齐：PUT /discover/sessions/:id
  Future<bool> renameConversation(
    Object id,
    String title, {
    String type = 'discover',
  }) async {
    final nextTitle = title.trim();
    if (nextTitle.isEmpty || type != searchConversationType) return false;

    try {
      await _historyService.renameConversation(type, id, nextTitle);
      final index = conversations.indexWhere(
        (item) => item.type == type && item.id.toString() == id.toString(),
      );
      if (index >= 0) {
        conversations[index] = conversations[index].copyWith(
          title: nextTitle,
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
      final detail = await _historyService.getConversationDetail(type, id);
      // Dio 可能返回 Map<dynamic, dynamic>，统一成 Map<String, dynamic>
      return Map<String, dynamic>.from(detail);
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
      isLocalPending: true,
    );
    conversations.insert(0, optimisticConversation);
    activeConversationKey = optimisticConversation.key;
    notifyListeners();
  }

  void updateOptimisticConversation(int tempId, Object realId, String title) {
    final tempKey = 'discover-$tempId';
    final index = conversations.indexWhere((item) => item.key == tempKey);
    if (index >= 0) {
      final oldItem = conversations[index];
      final updated = oldItem.copyWith(
        id: realId,
        title: title,
        recordCount: oldItem.recordCount + 1,
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
    _loadRequestEpoch += 1;
    _topRefreshRequestEpoch += 1;
    _unfilteredMutationEpoch += 1;
    final wasCollapsed = isCollapsed;
    conversations.clear();
    backgroundDiscoverQueries.clear();
    _pendingDiscoverBaselines.clear();
    _pendingDiscoverItems.clear();
    _pendingDiscoverRevisions.clear();
    _discoverReadRequests.clear();
    _latestTopConversations = null;
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
