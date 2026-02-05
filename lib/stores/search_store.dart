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

class SearchStore extends ChangeNotifier {
  final List<SearchTabData> openTabs = [];
  int? activeTabId;
  bool isSearching = false;
  int _idCounter = 0;
  String? pendingQuery;
  String? pendingFill;
  int tabClickVersion = 0; // 用于触发面板展开
  bool isLoadingConversation = false;

  int _nextId() {
    _idCounter += 1;
    return _idCounter;
  }

  int? openTab(Map<String, dynamic> candidate) {
    final id = _nextId();
    openTabs.add(SearchTabData(id: id, candidate: candidate));
    activeTabId = id;
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
    pendingQuery = null;
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

  // 打开标签页并触发点击版本更新
  int? openTabWithClick(Map<String, dynamic> candidate, {int? index, int? groupId}) {
    final id = openTab(candidate);
    tabClickVersion += 1;
    notifyListeners();
    return id;
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

  // 设置标签页错误
  void setTabError(int id, String? error) {
    final tab = openTabs.firstWhere((t) => t.id == id, orElse: () => throw Exception('Tab not found'));
    tab.error = error;
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

  // 加载会话（占位方法，需要根据实际 API 实现）
  void loadConversation(Map<String, dynamic> conversation) {
    // TODO: 实现加载会话逻辑
    notifyListeners();
  }
}


