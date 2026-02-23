// ---------------------------------------------------------------------------
// 从 react-grid-layout/core (collision, layout, sort, compactor) 迁移的布局算法
// ---------------------------------------------------------------------------

import 'grid_layout_types.dart';
import '../../utils/card_layout_utils.dart';

/// 两格点项是否重叠
bool collides(LayoutItem l1, LayoutItem l2) {
  if (l1.i == l2.i) return false;
  if (l1.x + l1.w <= l2.x) return false;
  if (l1.x >= l2.x + l2.w) return false;
  if (l1.y + l1.h <= l2.y) return false;
  if (l1.y >= l2.y + l2.h) return false;
  return true;
}

LayoutItem? getFirstCollision(List<LayoutItem> layout, LayoutItem layoutItem) {
  for (final item in layout) {
    if (collides(item, layoutItem)) return item;
  }
  return null;
}

List<LayoutItem> getAllCollisions(List<LayoutItem> layout, LayoutItem layoutItem) {
  return layout.where((l) => collides(l, layoutItem)).toList();
}

List<LayoutItem> sortLayoutItemsByRowCol(List<LayoutItem> layout) {
  final out = List<LayoutItem>.from(layout);
  out.sort((a, b) {
    if (a.y != b.y) return a.y.compareTo(b.y);
    return a.x.compareTo(b.x);
  });
  return out;
}

List<LayoutItem> sortLayoutItemsByColRow(List<LayoutItem> layout) {
  final out = List<LayoutItem>.from(layout);
  out.sort((a, b) {
    if (a.x != b.x) return a.x.compareTo(b.x);
    return a.y.compareTo(b.y);
  });
  return out;
}

List<LayoutItem> sortLayoutItems(List<LayoutItem> layout, CompactType compactType) {
  switch (compactType) {
    case CompactType.horizontal:
      return sortLayoutItemsByColRow(layout);
    case CompactType.vertical:
    case CompactType.none:
      return sortLayoutItemsByRowCol(layout);
  }
}

LayoutItem cloneLayoutItem(LayoutItem layoutItem) {
  return layoutItem.copyWith(moved: false);
}

List<LayoutItem> cloneLayout(List<LayoutItem> layout) {
  return layout.map(cloneLayoutItem).toList();
}

int bottom(List<LayoutItem> layout) {
  int max = 0;
  for (final item in layout) {
    final b = item.y + item.h;
    if (b > max) max = b;
  }
  return max;
}

LayoutItem? getLayoutItem(List<LayoutItem> layout, String id) {
  for (final item in layout) {
    if (item.i == id) return item;
  }
  return null;
}

List<LayoutItem> getStatics(List<LayoutItem> layout) {
  return layout.where((l) => l.static_).toList();
}

/// 边界修正：溢出右/左的项钳位；静态项与其它静态项碰撞则下移（原地修改）
void correctBounds(List<LayoutItem> layout, int cols) {
  final collidesWith = List<LayoutItem>.from(getStatics(layout));

  for (final l in layout) {
    if (l.x + l.w > cols) {
      l.x = cols - l.w;
    }
    if (l.x < 0) {
      l.x = 0;
      l.w = cols;
    }
    if (!l.static_) {
      collidesWith.add(l);
    } else {
      while (getFirstCollision(collidesWith, l) != null) {
        l.y++;
      }
    }
  }
}

/// 垂直紧凑：对 layout 原地重排（按行再按列排序，逐项上移填缝）
List<LayoutItem> compactVertical(List<LayoutItem> layout, int cols) {
  if (layout.isEmpty) return layout;
  final items = layout.map((it) => (i: it.i, x: it.x, y: it.y, w: it.w, h: it.h)).toList();
  final result = CardLayoutUtils.compactGridLayout(items, cols);
  for (var i = 0; i < layout.length; i++) {
    layout[i].x = result[i].x;
    layout[i].y = result[i].y;
  }
  return layout;
}

/// 移动元素并解决碰撞（会修改 l 的 x/y/moved）
List<LayoutItem> moveElement(
  List<LayoutItem> layout,
  LayoutItem l,
  int? x,
  int? y,
  bool isUserAction,
  bool preventCollision,
  CompactType compactType,
  int cols, {
  bool allowOverlap = false,
}) {
  if (l.static_ && l.isDraggable != true) return List.from(layout);
  if (l.y == y && l.x == x) return List.from(layout);

  final oldX = l.x;
  final oldY = l.y;

  if (x != null) l.x = x;
  if (y != null) l.y = y;
  l.moved = true;

  List<LayoutItem> sorted = sortLayoutItems(layout, compactType);
  final movingUp = compactType == CompactType.vertical && y != null
      ? oldY >= y
      : compactType == CompactType.horizontal && x != null
          ? oldX >= x
          : false;
  if (movingUp) sorted = sorted.reversed.toList();

  final collisions = getAllCollisions(sorted, l);
  final hasCollisions = collisions.isNotEmpty;

  if (hasCollisions && allowOverlap) return cloneLayout(layout);
  if (hasCollisions && preventCollision) {
    l.x = oldX;
    l.y = oldY;
    l.moved = false;
    return layout;
  }

  List<LayoutItem> resultLayout = List.from(layout);
  for (final collision in collisions) {
    if (collision.moved) continue;
    if (collision.static_) {
      resultLayout = moveElementAwayFromCollision(
        resultLayout, collision, l, isUserAction, compactType, cols,
      );
    } else {
      resultLayout = moveElementAwayFromCollision(
        resultLayout, l, collision, isUserAction, compactType, cols,
      );
    }
  }
  return resultLayout;
}

List<LayoutItem> moveElementAwayFromCollision(
  List<LayoutItem> layout,
  LayoutItem collidesWith,
  LayoutItem itemToMove,
  bool isUserAction,
  CompactType compactType,
  int cols,
) {
  final compactH = compactType == CompactType.horizontal;
  final compactV = compactType == CompactType.vertical;
  final preventCollision = collidesWith.static_;

  if (isUserAction) {
    final fakeX = compactH ? (collidesWith.x - itemToMove.w).clamp(0, cols - itemToMove.w) : itemToMove.x;
    final fakeY = compactV ? (collidesWith.y - itemToMove.h).clamp(0, 999) : itemToMove.y;
    final fakeItem = LayoutItem(i: '-1', x: fakeX, y: fakeY, w: itemToMove.w, h: itemToMove.h);

    final firstCollision = getFirstCollision(layout, fakeItem);
    final collisionNorth = firstCollision != null &&
        firstCollision.y + firstCollision.h > collidesWith.y;
    final collisionWest = firstCollision != null &&
        collidesWith.x + collidesWith.w > firstCollision.x;

    if (firstCollision == null) {
      return moveElement(
        layout, itemToMove,
        compactH ? fakeX : null, compactV ? fakeY : null,
        false, preventCollision, compactType, cols,
      );
    }
    if (collisionNorth && compactV) {
      return moveElement(
        layout, itemToMove, null, itemToMove.y + 1,
        false, preventCollision, compactType, cols,
      );
    }
    if (collisionWest && compactH) {
      return moveElement(
        layout, collidesWith, itemToMove.x, null,
        false, preventCollision, compactType, cols,
      );
    }
  }

  final newX = compactH ? itemToMove.x + 1 : null;
  final newY = compactV ? itemToMove.y + 1 : null;
  if (newX == null && newY == null) return layout;
  return moveElement(
    layout, itemToMove, newX, newY,
    false, preventCollision, compactType, cols,
  );
}
