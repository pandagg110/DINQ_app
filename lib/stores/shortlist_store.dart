import 'package:flutter/foundation.dart';

import '../constants/shortlist_constants.dart';
import '../models/shortlist_models.dart';
import '../pages/shortlist/shortlist_strings.dart';
import '../services/shortlist_service.dart';

/// Shortlist 状态，对齐 Web `favoriteStore` + `favoriteProjectStore`。
class ShortlistStore extends ChangeNotifier {
  ShortlistStore({ShortlistService? service})
      : _service = service ?? ShortlistService();

  final ShortlistService _service;
  int _loadRequestId = 0;

  List<FavoriteProject> _projects = [];
  bool _projectsLoading = false;
  bool _projectsLoaded = false;
  String? _projectsLoadError;
  String? _activeProjectId;

  List<FavoriteItem> _favorites = [];
  bool _isLoading = false;
  bool _hasMore = false;
  String _nameQuery = '';
  String? _statusFilter;
  final Set<String> _selectedIds = <String>{};
  bool _selectionMode = false;

  List<FavoriteProject> get projects => _projects;
  bool get projectsLoading => _projectsLoading;
  bool get projectsLoaded => _projectsLoaded;
  String? get projectsLoadError => _projectsLoadError;
  String? get activeProjectId => _activeProjectId;

  List<FavoriteItem> get favorites => _favorites;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String get nameQuery => _nameQuery;
  String? get statusFilter => _statusFilter;
  Set<String> get selectedIds => Set.unmodifiable(_selectedIds);
  bool get selectionMode => _selectionMode;
  bool get selectionActive => _selectionMode || _selectedIds.isNotEmpty;

  FavoriteProject? get activeProject {
    if (_activeProjectId == null) return null;
    for (final p in _projects) {
      if (p.id == _activeProjectId) return p;
    }
    return null;
  }

  String get activeProjectName {
    final p = activeProject;
    if (p == null) return ShortlistStrings.foldersUnknown;
    return p.isDefault ? ShortlistStrings.foldersDefaultName : p.name;
  }

  List<FavoriteProject> get sortedProjects {
    final list = List<FavoriteProject>.from(_projects);
    list.sort((a, b) {
      if (a.isDefault != b.isDefault) return a.isDefault ? -1 : 1;
      final aAt = a.createdAt ?? '';
      final bAt = b.createdAt ?? '';
      if (aAt.isNotEmpty && bAt.isNotEmpty) return bAt.compareTo(aAt);
      return a.name.compareTo(b.name);
    });
    return list;
  }

  List<FavoriteProject> get moveTargetProjects =>
      sortedProjects.where((p) => p.id != _activeProjectId).toList();

  Future<void> loadProjects() async {
    if (_projectsLoading) return;
    if (_projectsLoaded) return;
    _projectsLoading = true;
    _projectsLoadError = null;
    notifyListeners();
    try {
      final list = await _service.listProjects();
      final activeExists =
          _activeProjectId != null && list.any((p) => p.id == _activeProjectId);
      final fallback =
          list.where((p) => p.isDefault).firstOrNull ?? list.firstOrNull;
      _projects = list;
      _activeProjectId =
          activeExists ? _activeProjectId : fallback?.id;
      _projectsLoaded = true;
      _projectsLoadError = null;
    } catch (e) {
      _projectsLoaded = false;
      _projectsLoadError = e.toString();
    } finally {
      _projectsLoading = false;
      notifyListeners();
    }
  }

  Future<FavoriteProject?> createProject(String name) async {
    if (!_projectsLoaded) await loadProjects();
    try {
      final created = await _service.createProject(name);
      _projects = [..._projects, created];
      _activeProjectId = created.id;
      notifyListeners();
      return created;
    } catch (_) {
      return null;
    }
  }

  Future<bool> renameProject(String id, String name) async {
    try {
      final updated = await _service.renameProject(id, name);
      _projects = _projects.map((p) => p.id == id ? updated : p).toList();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteProject(String id) async {
    try {
      await _service.deleteProject(id);
      _projects = _projects.where((p) => p.id != id).toList();
      if (_activeProjectId == id) {
        final fallback = _projects.where((p) => p.isDefault).firstOrNull ??
            _projects.firstOrNull;
        _activeProjectId = fallback?.id;
      }
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  void setActiveProjectId(String? id) {
    _activeProjectId = id;
    notifyListeners();
  }

  void setNameQuery(String query) {
    _nameQuery = query;
    notifyListeners();
  }

  void setStatusFilter(String? status) {
    _statusFilter = status;
    notifyListeners();
  }

  void clearFilters() {
    _nameQuery = '';
    _statusFilter = null;
    notifyListeners();
  }

  void enterSelectionMode() {
    if (_selectionMode) return;
    _selectionMode = true;
    notifyListeners();
  }

  void exitSelectionMode() {
    _selectionMode = false;
    _selectedIds.clear();
    notifyListeners();
  }

  void toggleSelected(String id) {
    _selectionMode = true;
    if (!_selectedIds.add(id)) _selectedIds.remove(id);
    notifyListeners();
  }

  void clearSelected() => exitSelectionMode();

  void toggleSelectAllVisible(Iterable<String> ids) {
    final visible = ids.toSet();
    if (visible.isEmpty) return;
    final allSelected = visible.every(_selectedIds.contains);
    _selectionMode = true;
    if (allSelected) {
      _selectedIds.removeAll(visible);
    } else {
      _selectedIds.addAll(visible);
    }
    notifyListeners();
  }

  Future<void> loadFavorites({bool clear = false}) async {
    if (_activeProjectId == null) return;
    final requestId = ++_loadRequestId;
    if (clear) {
      _favorites = [];
      _hasMore = false;
      _selectedIds.clear();
      _selectionMode = false;
    }
    _isLoading = true;
    notifyListeners();
    try {
      final items = await _service.listFavorites(
        projectId: _activeProjectId,
        name: _nameQuery,
        status: _statusFilter,
        limit: shortlistPageSize,
        offset: 0,
      );
      if (requestId != _loadRequestId) return;
      _favorites = items;
      _hasMore = items.length == shortlistPageSize;
    } catch (_) {
      if (requestId != _loadRequestId) return;
    } finally {
      if (requestId == _loadRequestId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMore() async {
    if (_isLoading || !_hasMore || _activeProjectId == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      final items = await _service.listFavorites(
        projectId: _activeProjectId,
        name: _nameQuery,
        status: _statusFilter,
        limit: shortlistPageSize,
        offset: _favorites.length,
      );
      _favorites = [..._favorites, ...items];
      _hasMore = items.length == shortlistPageSize;
    } catch (_) {
      // keep current list
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> removeFavorite(String id) async {
    final previous = _favorites.where((f) => f.id == id).firstOrNull;
    try {
      await _service.removeFavorite(id);
      _favorites = _favorites.where((f) => f.id != id).toList();
      _selectedIds.remove(id);
      if (previous != null) {
        _adjustTalentCount(previous.projectId, -1);
      }
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<ShortlistBulkResult> bulkRemove(List<String> ids) async {
    var ok = 0;
    var fail = 0;
    for (final id in ids) {
      if (await removeFavorite(id)) {
        ok++;
      } else {
        fail++;
      }
    }
    return ShortlistBulkResult(ok: ok, fail: fail);
  }

  Future<bool> updateTags(String id, String tags) async {
    final index = _favorites.indexWhere((f) => f.id == id);
    if (index < 0) return false;
    final previous = _favorites[index];
    _favorites[index] = previous.copyWith(tags: tags);
    notifyListeners();
    try {
      final updated = await _service.updateFavorite(id, tags: tags);
      _favorites[index] = updated;
      notifyListeners();
      return true;
    } catch (_) {
      _favorites[index] = previous;
      notifyListeners();
      return false;
    }
  }

  Future<ShortlistBulkResult> bulkMove(
    List<String> ids,
    String projectId,
  ) async {
    var ok = 0;
    var fail = 0;
    for (final id in ids) {
      try {
        await _service.moveFavorite(id, projectId);
        final item = _favorites.where((f) => f.id == id).firstOrNull;
        if (item != null) {
          _adjustTalentCount(item.projectId, -1);
          _adjustTalentCount(projectId, 1);
        }
        ok++;
      } catch (_) {
        fail++;
      }
    }
    _favorites =
        _favorites.where((f) => !ids.contains(f.id)).toList();
    _selectedIds.removeAll(ids);
    notifyListeners();
    return ShortlistBulkResult(ok: ok, fail: fail);
  }

  void _adjustTalentCount(String projectId, int delta) {
    _projects = _projects.map((p) {
      if (p.id != projectId) return p;
      return p.copyWith(talentCount: (p.talentCount + delta).clamp(0, 999999));
    }).toList();
  }

  /// 启动时加载项目并拉取收藏列表。
  Future<void> initialize() async {
    await loadProjects();
    if (_activeProjectId != null) {
      await loadFavorites(clear: true);
    }
  }

  @Deprecated('Use initialize()')
  Future<void> load() => initialize();
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    if (it.moveNext()) return it.current;
    return null;
  }
}
