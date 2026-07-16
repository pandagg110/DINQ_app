import 'package:flutter/foundation.dart';

import '../constants/shortlist_constants.dart';
import '../models/shortlist_models.dart';
import '../pages/shortlist/shortlist_strings.dart';
import '../services/shortlist_service.dart';
import 'user_store.dart';

/// Shortlist 状态，对齐 Web `favoriteStore` + `favoriteProjectStore`。
class ShortlistStore extends ChangeNotifier {
  ShortlistStore({ShortlistService? service})
      : _service = service ?? ShortlistService() {
    // 登出/删号/401 过期时清空，避免新账号看到上一账号的文件夹与收藏
    //（对齐 ResumeStore 登出清理；本 store 是 app 级单例，不清即跨账号残留）。
    UserStore.registerLogoutCleanup(clear);
  }

  final ShortlistService _service;
  int _loadRequestId = 0;
  int _projectsEpoch = 0;

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

  /// [force] 为 true 时忽略已加载缓存、强制重新拉取。
  /// 收藏弹窗（shortlist_folder_modal）直接走 ShortlistService 新建文件夹/收藏，
  /// 不经过本 store；且 ShortlistPage 被 KeepAlive 缓存只 init 一次 —— 若一直
  /// 使用缓存，shortlist 页会永远停留在首次快照（只看到旧文件夹、看不到新收藏）。
  Future<void> loadProjects({bool force = false}) async {
    if (_projectsLoading) return;
    if (_projectsLoaded && !force) return;
    _projectsLoading = true;
    _projectsLoadError = null;
    notifyListeners();
    // clear()（登出）后作废在途请求，防止老账号响应回填新账号视图
    final epoch = _projectsEpoch;
    try {
      final list = await _service.listProjects();
      if (epoch != _projectsEpoch) return;
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
      if (epoch != _projectsEpoch) return;
      _projectsLoaded = false;
      _projectsLoadError = e.toString();
    } finally {
      if (epoch == _projectsEpoch) {
        _projectsLoading = false;
        notifyListeners();
      }
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
    // 与当前列表同代：clear()/新的 loadFavorites 之后丢弃在途分页结果
    final requestId = _loadRequestId;
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
      if (requestId != _loadRequestId) return;
      _favorites = [..._favorites, ...items];
      _hasMore = items.length == shortlistPageSize;
    } catch (_) {
      // keep current list
    } finally {
      if (requestId == _loadRequestId) {
        _isLoading = false;
        notifyListeners();
      }
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

  /// 每次进入 Shortlist tab 时调用：强制重取文件夹 + 当前文件夹收藏。
  /// 对齐 web：shortlist 页每次进入路由都会重新挂载并重新拉取 favorites
  ///（page.tsx:719 `loadFavorites({ clear: projectChanged })`），
  /// 且 web 的收藏弹窗与页面共用同一 favoriteProjectStore（新建文件夹立即可见）；
  /// App 侧收藏弹窗独立请求接口，因此进入 tab 时统一强刷来收敛数据。
  Future<void> refreshAll() async {
    final previousProjectId = _activeProjectId;
    await loadProjects(force: true);
    if (_activeProjectId != null) {
      await loadFavorites(clear: _activeProjectId != previousProjectId);
    }
  }

  /// 登出/切换账号时清空全部用户态，避免跨账号残留（由 UserStore.logout 经
  /// registerLogoutCleanup 触发，对齐 ResumeStore.clear 的登出清理语义）。
  /// 同时递增请求代号，作废在途的 loadProjects/loadFavorites/loadMore，
  /// 防止老账号的响应把数据回填进新账号视图。
  void clear() {
    _loadRequestId++;
    _projectsEpoch++;
    _projects = [];
    _projectsLoading = false;
    _projectsLoaded = false;
    _projectsLoadError = null;
    _activeProjectId = null;
    _favorites = [];
    _isLoading = false;
    _hasMore = false;
    _nameQuery = '';
    _statusFilter = null;
    _selectedIds.clear();
    _selectionMode = false;
    notifyListeners();
  }

  @override
  void dispose() {
    UserStore.unregisterLogoutCleanup(clear);
    super.dispose();
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
