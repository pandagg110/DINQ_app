import 'package:flutter/material.dart';

class SearchTabData {
  SearchTabData({required this.id, required this.candidate});

  final int id;
  final Map<String, dynamic> candidate;
  Map<String, dynamic>? profile;
  List<dynamic>? network;
  bool isLoading = false;
  bool networkLoading = false;
  bool enrichLoading = false;
  String? error;
}

/// 与 TSX MAX_TABS 一致
const int _maxTabs = 12;

class SearchStore extends ChangeNotifier {
  final List<SearchTabData> openTabs = [];
  int? activeTabId;
  bool isSearching = false;
  int _idCounter = 0;
  String? pendingQuery;
  String? pendingFill;
  int tabClickVersion = 0; // 用于触发面板展开
  /// 与 ChatHistoryStore.isMobileOpen 一致：tab 面板是否打开（底部滑入）
  bool isTabPanelOpen = false;
  bool isLoadingConversation = false;
  int? currentConversationId;
  /// 待加载的会话详情（从 Chat History 点入时设置，AgenticChat 会消费并清空）
  Map<String, dynamic>? pendingConversation;
  /// 重置版本：clearAll 时递增，AgenticChat 据此清空消息
  int resetVersion = 0;
  /// Extra type 字符串（默认 null）
  String? extraType;
  /// Active tool（'find-advisor' 或 null）
  String? activeTool;

  int _nextId() {
    _idCounter += 1;
    return _idCounter;
  }

  /// 与 TSX getCandidateCompleteness 简化版：有值的字段数 / 总字段数
  static double _getCandidateCompleteness(Map<String, dynamic> c) {
    const keys = ['name', 'image_url', 'company', 'position', 'university', 'one_liner', 'match_reason'];
    var filled = 0;
    for (final k in keys) {
      final v = c[k];
      if (v != null && v.toString().trim().isNotEmpty) filled++;
    }
    return filled / keys.length;
  }

  /// 与 TSX openTab 一致：支持 index/groupId/判重/MAX_TABS，返回标签页 id 或 null（不满足条件时）
  int? openTab(
    Map<String, dynamic> candidate, {
    int? index,
    int? groupId,
    bool matchByName = false,
    bool switchTab = true,
  }) {
    final hasAvatar = (candidate['image_url']?.toString() ?? '').trim().isNotEmpty;
    final completeness = _getCandidateCompleteness(candidate);
    if (!hasAvatar && completeness < 0.7) return null;

    final originalIndex = index ?? 0;
    final gId = groupId ?? 0;

    SearchTabData? existing;
    for (final t in openTabs) {
      if (matchByName) {
        if (t.candidate['groupId'] == -1 && t.candidate['name'] == candidate['name']) {
          existing = t;
          break;
        }
      } else {
        if (t.candidate['groupId'] == gId && t.candidate['originalIndex'] == originalIndex) {
          existing = t;
          break;
        }
      }
    }

    if (existing != null) {
      if (switchTab) {
        activeTabId = existing.id;
        tabClickVersion += 1;
      }
      notifyListeners();
      return existing.id;
    }

    final id = _nextId();
    final tabCandidate = Map<String, dynamic>.from(candidate);
    tabCandidate['originalIndex'] = originalIndex;
    tabCandidate['groupId'] = gId;

    if (openTabs.length >= _maxTabs) {
      openTabs.removeAt(0);
    }
    openTabs.add(SearchTabData(id: id, candidate: tabCandidate));
    if (switchTab) activeTabId = id;
    tabClickVersion += 1;
    notifyListeners();
    return id;
  }

  void closeTab(int id) {
    openTabs.removeWhere((tab) => tab.id == id);
    if (activeTabId == id) {
      activeTabId = openTabs.isEmpty ? null : openTabs.last.id;
    }
    notifyListeners();
  }

  void setActiveTab(int id) {
    activeTabId = id;
    notifyListeners();
  }

  void setTabPanelOpen(bool open) {
    if (isTabPanelOpen == open) return;
    isTabPanelOpen = open;
    notifyListeners();
  }

  SearchTabData? getActiveTab() {
    if (activeTabId == null) return null;
    for (final tab in openTabs) {
      if (tab.id == activeTabId) {
        return tab;
      }
    }
    return openTabs.isNotEmpty ? openTabs.first : null;
  }

  void setIsSearching(bool value) {
    isSearching = value;
    notifyListeners();
  }

  void clearAll() {
    openTabs.clear();
    activeTabId = null;
    isSearching = false;
    isLoadingConversation = false;
    pendingQuery = null;
    currentConversationId = null;
    pendingConversation = null;
    extraType = null;
    activeTool = null;
    resetVersion += 1;
    notifyListeners();
  }

  void setCurrentConversationId(int? id) {
    currentConversationId = id;
    notifyListeners();
  }

  void setPendingConversation(Map<String, dynamic>? detail) {
    pendingConversation = detail;
    notifyListeners();
  }

  void clearPendingConversation() {
    pendingConversation = null;
    notifyListeners();
  }

  void triggerSearch(String query) {
    pendingQuery = query;
    notifyListeners();
  }

  void clearPendingQuery() {
    pendingQuery = null;
    notifyListeners();
  }

  void fillSearchBox(String text) {
    pendingFill = text;
    notifyListeners();
  }

  void clearPendingFill() {
    pendingFill = null;
    notifyListeners();
  }

  /// 设置 extra type 字符串
  void setExtraType(String? value) {
    extraType = value;
    notifyListeners();
  }

  /// 清除 extra type 字符串
  void clearExtraType() {
    extraType = null;
    notifyListeners();
  }

  /// 设置 active tool
  void setActiveTool(String? tool) {
    activeTool = tool;
    notifyListeners();
  }

  /// 清除 active tool
  void clearActiveTool() {
    activeTool = null;
    notifyListeners();
  }

  /// 与 TSX 一致：点击候选人时打开标签页（带 index/groupId，会判重并受 MAX_TABS 限制）
  int? openTabWithClick(
    Map<String, dynamic> candidate, {
    int? index,
    int? groupId,
    bool matchByName = false,
    bool switchTab = true,
  }) {
    return openTab(candidate, index: index, groupId: groupId, matchByName: matchByName, switchTab: switchTab);
  }

  /// 用搜索结果候选人整体替换标签页（首次展示返回值时用；与 TSX 中“无已有 tab 时展示结果”对应）
  void setTabsFromCandidates(List<Map<String, dynamic>> candidates) {
    openTabs.clear();
    for (var i = 0; i < candidates.length; i++) {
      final c = Map<String, dynamic>.from(candidates[i]);
      c['originalIndex'] = i;
      c['groupId'] = 0;
      openTabs.add(SearchTabData(id: _nextId(), candidate: c));
    }
    if (openTabs.isNotEmpty) activeTabId = openTabs.first.id;
    tabClickVersion += 1;
    notifyListeners();
  }

  /// 与 TSX syncCandidatesToTabs 一致：只更新已打开标签页的 candidate（按 originalIndex + name 匹配），不增删 tab
  void syncCandidatesToTabs(List<Map<String, dynamic>> candidates) {
    for (final tab in openTabs) {
      final idx = tab.candidate['originalIndex'];
      if (idx == null || idx is! int || idx < 0 || idx >= candidates.length) continue;
      final updated = candidates[idx];
      if (updated['name'] != tab.candidate['name']) continue;
      tab.candidate.addAll(updated);
    }
    notifyListeners();
  }

  // 更新标签页的 profile 数据
  void updateTabProfile(int id, Map<String, dynamic> profile) {
    final tab = openTabs.firstWhere((t) => t.id == id, orElse: () => throw Exception('Tab not found'));
    tab.profile = profile;
    notifyListeners();
  }

  // 更新标签页的 network 数据
  void updateTabNetwork(int id, List<dynamic> network) {
    final tab = openTabs.firstWhere((t) => t.id == id, orElse: () => throw Exception('Tab not found'));
    tab.network = network;
    notifyListeners();
  }

  // 更新标签页的 candidate 数据
  void updateTabCandidate(int id, Map<String, dynamic> candidate) {
    final tab = openTabs.firstWhere((t) => t.id == id, orElse: () => throw Exception('Tab not found'));
    tab.candidate.clear();
    tab.candidate.addAll(candidate);
    notifyListeners();
  }

  // 设置标签页错误（与 TSX 一致：同时将 isLoading 置为 false）
  void setTabError(int id, String? error) {
    final tab = openTabs.firstWhere((t) => t.id == id, orElse: () => throw Exception('Tab not found'));
    tab.error = error;
    tab.isLoading = false;
    notifyListeners();
  }

  // 设置标签页加载状态
  void setTabLoading(int id, bool loading) {
    final tab = openTabs.firstWhere((t) => t.id == id, orElse: () => throw Exception('Tab not found'));
    tab.isLoading = loading;
    notifyListeners();
  }

  // 设置标签页网络加载状态
  void setTabNetworkLoading(int id, bool loading) {
    final tab = openTabs.firstWhere((t) => t.id == id, orElse: () => throw Exception('Tab not found'));
    tab.networkLoading = loading;
    notifyListeners();
  }

  // 设置标签页 enrich 加载状态
  void setTabEnrichLoading(int id, bool loading) {
    final tab = openTabs.firstWhere((t) => t.id == id, orElse: () => throw Exception('Tab not found'));
    tab.enrichLoading = loading;
    notifyListeners();
  }

  // 设置会话加载状态
  void setLoadingConversation(bool value) {
    isLoadingConversation = value;
    notifyListeners();
  }

  /// 加载会话详情：用会话的 records 还原为消息组并填充 openTabs（与 TSX 一致）
  void loadConversation(Map<String, dynamic> conversation) {
    final records = conversation['records'];
    if (records is! List || records.isEmpty) {
      notifyListeners();
      return;
    }
    openTabs.clear();
    activeTabId = null;
    _idCounter = 0;
    for (var i = 0; i < records.length; i++) {
      final record = records[i] as Map<String, dynamic>;
      final result = record['result'];
      if (result is List) {
        for (var j = 0; j < result.length; j++) {
          final c = Map<String, dynamic>.from(result[j] as Map<String, dynamic>);
          c['originalIndex'] = j;
          openTab(c);
        }
      }
    }
    if (openTabs.isNotEmpty) activeTabId = openTabs.first.id;
    tabClickVersion += 1;
    notifyListeners();
  }
}


