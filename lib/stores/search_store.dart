import 'package:flutter/material.dart';

class SearchTabData {
  SearchTabData({required this.id, required this.candidate});

  final int id;
  final Map<String, dynamic> candidate;
  Map<String, dynamic>? profile;
  List<dynamic>? network;
  bool isLoading = false;
  String? error;
}

class SearchStore extends ChangeNotifier {
  final List<SearchTabData> openTabs = [];
  int? activeTabId;
  bool isSearching = false;
  int _idCounter = 0;
  String? pendingQuery;
  String? pendingFill;

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
}


