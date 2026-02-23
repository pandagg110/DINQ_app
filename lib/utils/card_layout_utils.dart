import '../models/card_models.dart';

// ---------------------------------------------------------------------------
// 参考 react-grid-layout 的 core：collision / compactors / sort / layout
// https://github.com/react-grid-layout/react-grid-layout
// ---------------------------------------------------------------------------

/// 内部布局项，对应 RGL LayoutItem（仅用 i,x,y,w,h 参与紧凑）
class _LayoutItem {
  _LayoutItem(this.i, this.x, this.y, this.w, this.h);
  final String i;
  int x, y, w, h;
  _LayoutItem clone() => _LayoutItem(i, x, y, w, h);
}

/// 两矩形是否重叠（RGL collides）
bool _collides(_LayoutItem a, _LayoutItem b) {
  if (a.i == b.i) return false;
  if (a.x + a.w <= b.x) return false;
  if (a.x >= b.x + b.w) return false;
  if (a.y + a.h <= b.y) return false;
  if (a.y >= b.y + b.h) return false;
  return true;
}

_LayoutItem? _getFirstCollision(List<_LayoutItem> layout, _LayoutItem item) {
  for (final other in layout) {
    if (_collides(other, item)) return other;
  }
  return null;
}

int _bottom(List<_LayoutItem> layout) {
  int max = 0;
  for (final item in layout) {
    final b = item.y + item.h;
    if (b > max) max = b;
  }
  return max;
}

/// 按行再按列排序（RGL sortLayoutItemsByRowCol）
List<_LayoutItem> _sortByRowCol(List<_LayoutItem> layout) {
  final out = List<_LayoutItem>.from(layout);
  out.sort((a, b) {
    if (a.y != b.y) return a.y.compareTo(b.y);
    return a.x.compareTo(b.x);
  });
  return out;
}

/// 解决紧凑时的碰撞：把被挡住的项沿 axis 方向推到 moveToCoord 之外（RGL resolveCompactionCollision）
void _resolveCompactionCollision(
  List<_LayoutItem> layout,
  _LayoutItem item,
  int moveToCoord,
  bool isY,
) {
  final sizeProp = isY ? item.h : item.w;
  if (isY) {
    item.y = moveToCoord + 1;
  } else {
    item.x = moveToCoord + 1;
  }
  final itemIndex = layout.indexWhere((l) => l.i == item.i);
  for (var i = itemIndex + 1; i < layout.length; i++) {
    final other = layout[i];
    if (_collides(item, other)) {
      _resolveCompactionCollision(layout, other, moveToCoord + sizeProp, isY);
    }
  }
  if (isY) {
    item.y = moveToCoord;
  } else {
    item.x = moveToCoord;
  }
}

/// 单元素垂直紧凑：尽量上移且不重叠，有碰撞则下推（RGL compactItemVertical）
_LayoutItem _compactItemVertical(
  List<_LayoutItem> compareWith,
  _LayoutItem l,
  List<_LayoutItem> fullLayout,
  int maxY,
) {
  l.x = l.x > 0 ? l.x : 0;
  l.y = l.y < maxY ? l.y : maxY;
  if (l.y < 0) l.y = 0;

  while (l.y > 0 && _getFirstCollision(compareWith, l) == null) {
    l.y--;
  }

  _LayoutItem? collision;
  while ((collision = _getFirstCollision(compareWith, l)) != null) {
    final c = collision!;
    _resolveCompactionCollision(fullLayout, l, c.y + c.h, true);
  }

  if (l.y < 0) l.y = 0;
  return l;
}

/// 对整个 layout 做垂直紧凑（RGL verticalCompactor.compact）
List<_LayoutItem> _verticalCompact(List<_LayoutItem> layout, int cols) {
  final compareWith = <_LayoutItem>[];
  int maxY = _bottom(compareWith);
  final sorted = _sortByRowCol(layout);
  final out = List<_LayoutItem?>.filled(layout.length, null);

  for (var i = 0; i < sorted.length; i++) {
    final sortedItem = sorted[i];
    var l = sortedItem.clone();
    l = _compactItemVertical(compareWith, l, sorted, maxY);
    maxY = (l.y + l.h) > maxY ? (l.y + l.h) : maxY;
    compareWith.add(l);
    final originalIndex = layout.indexWhere((o) => o.i == sortedItem.i);
    out[originalIndex] = l;
  }

  return out.whereType<_LayoutItem>().toList();
}

/// 卡片布局工具类
class CardLayoutUtils {
  /// 与 image_edit_form 的 Preview 一致：根据屏幕宽度与 grid 配置计算预览/编辑用卡片宽高
  static ({double width, double height}) getPreviewCardSize(
    double screenWidth,
    double mobileGap,
    String sizeStr,
  ) {
    final cellSize = (screenWidth - 12 * 2 - mobileGap) / 2;
    final dims = parseSizeString(sizeStr);
    final width = cellSize * dims.w / 2;
    final height = cellSize * dims.h / 2;
    return (width: width, height: height);
  }

  /// 从 "2x2", "4x4" 等字符串解析宽高
  static ({int w, int h}) parseSizeString(String size) {
    final parts = size.toLowerCase().split('x');
    if (parts.length != 2) return (w: 2, h: 2);
    final w = int.tryParse(parts[0].trim()) ?? 2;
    final h = int.tryParse(parts[1].trim()) ?? 2;
    return (w: w, h: h);
  }

  /// 按当前顺序与现有 (x,y) 做垂直紧凑重排，得到每个卡片的 (x,y,w,h)。
  /// 逻辑参考 react-grid-layout 的 verticalCompactor：按行再按列排序，逐项上移填缝，碰撞则下推。
  static List<CardPosition> compactPositions(
    List<CardItem> ordered,
    int columns,
  ) {
    if (ordered.isEmpty) return [];

    final layout = <_LayoutItem>[];
    for (var i = 0; i < ordered.length; i++) {
      final card = ordered[i];
      final dims = parseSizeString(card.layout.mobile.size);
      final w = dims.w.clamp(1, columns);
      final h = dims.h.clamp(1, 100);
      final pos = card.layout.mobile.position;
      int x = pos.x;
      int y = pos.y;
      if (x + w > columns) x = columns - w;
      if (x < 0) x = 0;
      if (y < 0) y = 0;
      layout.add(_LayoutItem('$i', x, y, w, h));
    }

    final compacted = _verticalCompact(layout, columns);
    // compacted 与 layout 顺序一致（按 originalIndex 写回），故与 ordered 一一对应
    final positions = <CardPosition>[];
    for (var i = 0; i < compacted.length; i++) {
      final item = compacted[i];
      positions.add(CardPosition(x: item.x, y: item.y, w: item.w, h: item.h));
    }
    return positions;
  }

  /// 对一组格点 (i, x, y, w, h) 做垂直紧凑重排，返回与输入同序的 (x, y) 列表。
  /// 供 admin 网格等不依赖 CardItem 的场景使用。
  static List<({int x, int y})> compactGridLayout(
    List<({String i, int x, int y, int w, int h})> items,
    int columns,
  ) {
    if (items.isEmpty) return [];
    final layout = <_LayoutItem>[];
    for (final it in items) {
      int x = it.x;
      int y = it.y;
      final w = it.w.clamp(1, columns);
      final h = it.h.clamp(1, 100);
      if (x + w > columns) x = columns - w;
      if (x < 0) x = 0;
      if (y < 0) y = 0;
      layout.add(_LayoutItem(it.i, x, y, w, h));
    }
    final compacted = _verticalCompact(layout, columns);
    return [for (final item in compacted) (x: item.x, y: item.y)];
  }
}
