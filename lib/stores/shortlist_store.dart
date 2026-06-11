import 'package:flutter/foundation.dart';

import '../models/shortlist_models.dart';
import '../services/shortlist_service.dart';

/// Shortlist 状态：文件夹、候选人、筛选与搜索。
class ShortlistStore extends ChangeNotifier {
  ShortlistStore({ShortlistService? service})
      : _service = service ?? ShortlistService();

  final ShortlistService _service;

  static const List<String> statusOptions = [
    'All',
    'Not obtained',
    'Email obtained',
    'Contacted',
  ];

  List<FavoriteProject> _projects = [];
  List<FavoriteItem> _items = [];
  String? _selectedProjectId;
  String _selectedStatus = 'All';
  String _query = '';
  bool _loading = false;
  String? _error;

  List<FavoriteProject> get projects => _projects;
  bool get loading => _loading;
  String? get error => _error;
  String get selectedStatus => _selectedStatus;

  FavoriteProject? get selectedProject {
    if (_projects.isEmpty) return null;
    return _projects.firstWhere(
      (p) => p.id == _selectedProjectId,
      orElse: () => _projects.first,
    );
  }

  String get selectedFolderName => selectedProject?.name ?? 'Default';

  /// 当前文件夹 + 状态 + 搜索过滤后的候选人。
  List<FavoriteItem> get visibleItems {
    final String? pid = selectedProject?.id;
    final String q = _query.trim().toLowerCase();
    return _items.where((item) {
      if (pid != null && item.projectId != pid) return false;
      if (_selectedStatus != 'All' && item.statusLabel != _selectedStatus) {
        return false;
      }
      if (q.isNotEmpty) {
        final haystack =
            '${item.name} ${item.roleLine} ${item.tags}'.toLowerCase();
        if (!haystack.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _service.listProjects(),
        _service.listFavorites(),
      ]);
      _projects = results[0] as List<FavoriteProject>;
      _items = results[1] as List<FavoriteItem>;
      // 默认选中 isDefault 项目，否则第一个。
      _selectedProjectId = _projects
          .firstWhere(
            (p) => p.isDefault,
            orElse: () =>
                _projects.isNotEmpty ? _projects.first : _emptyProject,
          )
          .id;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  static const FavoriteProject _emptyProject =
      FavoriteProject(id: '', name: 'Default', isDefault: true, talentCount: 0);

  void selectProject(String id) {
    _selectedProjectId = id;
    notifyListeners();
  }

  void selectStatus(String status) {
    _selectedStatus = status;
    notifyListeners();
  }

  void setQuery(String q) {
    _query = q;
    notifyListeners();
  }

  /// 批量移除收藏（接真实接口），成功后本地同步移除。
  Future<void> removeFavorites(Set<String> ids) async {
    if (ids.isEmpty) return;
    await Future.wait(ids.map(_service.removeFavorite));
    _items = _items.where((item) => !ids.contains(item.id)).toList();
    notifyListeners();
  }

  /// 批量移动收藏到指定项目（接真实接口），成功后本地同步更新 projectId。
  Future<void> moveFavorites(Set<String> ids, String projectId) async {
    if (ids.isEmpty || projectId.isEmpty) return;
    await Future.wait(ids.map((id) => _service.moveFavorite(id, projectId)));
    _items = _items.map((item) {
      if (ids.contains(item.id)) {
        return FavoriteItem(
          id: item.id,
          projectId: projectId,
          title: item.title,
          field: item.field,
          tags: item.tags,
          status: item.status,
        );
      }
      return item;
    }).toList();
    notifyListeners();
  }
}
