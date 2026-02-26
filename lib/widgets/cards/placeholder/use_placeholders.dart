import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../models/card_models.dart';
import '../../../../utils/card_layout_utils.dart';
import 'placeholder_config.dart';

const _storageKeyPrefix = 'dinq_placeholder_activated_';
const _hiddenKeyPrefix = 'dinq_placeholder_hidden_';
const _maxSearchRows = 100;

/// 单个占位卡片在网格中的位置
class PlaceholderPosition {
  const PlaceholderPosition({
    required this.config,
    required this.x,
    required this.y,
  });

  final PlaceholderCardConfig config;
  final int x;
  final int y;
}

/// 拖拽过程中的数据快照，供 PlaceholderGrid 等使用（如高亮落点、避免与拖拽项重叠等）
class GridDragSnapshot {
  const GridDragSnapshot({
    required this.itemId,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
  });
  final String itemId;
  final int x;
  final int y;
  final int w;
  final int h;
}

/// 占位符状态与持久化：隐藏列表、是否显示占位符
class PlaceholderNotifier extends ChangeNotifier {
  Set<String> _hiddenPlaceholders = {};
  bool _showPlaceholders = false;
  String? _userId;

  Set<String> get hiddenPlaceholders => Set.unmodifiable(_hiddenPlaceholders);
  bool get showPlaceholders => _showPlaceholders;

  Future<void> setUserId(String? userId) async {
    if (_userId == userId) return;
    _userId = userId;
    if (userId == null) {
      _hiddenPlaceholders = {};
      notifyListeners();
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _hiddenKeyPrefix + userId;
      final list = prefs.getStringList(key);
      _hiddenPlaceholders = list != null ? list.toSet() : {};
    } catch (_) {}
    notifyListeners();
  }

  /// 由外部在 build 时调用：根据 editable、isInitialized、cardsLength、userId 更新 showPlaceholders
  Future<void> updateActivation({
    required bool editable,
    required bool isInitialized,
    required int cardsLength,
    required String? userId,
  }) async {
    if (!isInitialized || !editable || userId == null) {
      if (_showPlaceholders) {
        _showPlaceholders = false;
        notifyListeners();
      }
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final storageKey = _storageKeyPrefix + userId;
      final hiddenKey = _hiddenKeyPrefix + userId;

      // 编辑态下首次进入时即激活占位符（不要求无卡片），保证编辑时能看到占位 card
      if (prefs.getString(storageKey) == null) {
        await prefs.setString(storageKey, 'true');
      }

      if (cardsLength == 0) {
        _hiddenPlaceholders = {};
        await prefs.remove(hiddenKey);
      }

      final isActivated = prefs.getString(storageKey) == 'true';
      if (_showPlaceholders != isActivated) {
        _showPlaceholders = isActivated;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> hidePlaceholder(String type) async {
    final userId = _userId;
    if (userId == null) return;
    _hiddenPlaceholders = Set.from(_hiddenPlaceholders)..add(type);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _hiddenKeyPrefix + userId,
        _hiddenPlaceholders.toList(),
      );
    } catch (_) {}
    notifyListeners();
  }
}

/// 根据当前卡片布局计算占位符位置列表。
/// [cards] 用于判断已有类型（不重复展示同类型占位）；[cardsForLayout] 用于占用格（与网格实际显示的卡片一致，改尺寸后会重排）。
/// [layoutOverride] 不为空时（如拖拽过程中的布局）用其作为占用格，替代由 cardsForLayout 推导的布局。
List<PlaceholderPosition> computePlaceholderPositions({
  required List<CardItem> cards,
  required List<CardItem> cardsForLayout,
  required int columns,
  required bool editable,
  required bool showPlaceholders,
  required Set<String> hiddenPlaceholders,
  List<({int x, int y, int w, int h})>? layoutOverride,
}) {
  if (!editable || !showPlaceholders) return [];

  final existingTypes = cards.map((c) => c.data.type.toUpperCase()).toSet();
  final filtered = placeholderCardsConfig.where((config) {
    return !existingTypes.contains(config.type.toUpperCase()) &&
        !hiddenPlaceholders.contains(config.type.toUpperCase());
  }).toList();

  if (filtered.isEmpty) return [];

  final List<({int x, int y, int w, int h})> layout;
  if (layoutOverride != null) {
    layout = layoutOverride;
  } else {
    layout = <({int x, int y, int w, int h})>[];
    for (final card in cardsForLayout) {
      final pos = card.layout.mobile.position;
      final dims = CardLayoutUtils.parseSizeString(card.layout.mobile.size);
      final w = dims.w.clamp(1, columns);
      final h = dims.h.clamp(1, 100);
      layout.add((x: pos.x, y: pos.y, w: w, h: h));
    }
  }

  final maxBottomY = layout.isEmpty
      ? 0
      : layout.map((e) => e.y + e.h).reduce((a, b) => a > b ? a : b);
  final grid = <int, Map<int, bool>>{};

  void markOccupied(int x, int y, int w, int h) {
    for (var dy = 0; dy < h; dy++) {
      grid.putIfAbsent(y + dy, () => {});
      for (var dx = 0; dx < w; dx++) {
        grid[y + dy]![x + dx] = true;
      }
    }
  }

  bool canPlace(int x, int y, int w, int h) {
    if (x + w > columns) return false;
    for (var dy = 0; dy < h; dy++) {
      final row = grid[y + dy];
      if (row == null) continue;
      for (var dx = 0; dx < w; dx++) {
        if (row[x + dx] == true) return false;
      }
    }
    return true;
  }

  for (final item in layout) {
    markOccupied(item.x, item.y, item.w, item.h);
  }

  final positions = <PlaceholderPosition>[];
  for (final config in filtered) {
    final w = config.size.w;
    final h = config.size.h;
    var placed = false;
    for (var y = 0; !placed && y < maxBottomY + _maxSearchRows; y++) {
      for (var x = 0; x <= columns - w; x++) {
        if (canPlace(x, y, w, h)) {
          positions.add(PlaceholderPosition(config: config, x: x, y: y));
          markOccupied(x, y, w, h);
          placed = true;
          break;
        }
      }
    }
  }
  return positions;
}
