// ---------------------------------------------------------------------------
// 等价 useGridLayout：管理 layout、拖拽/缩放/放置状态及回调
// ---------------------------------------------------------------------------

import 'package:flutter/foundation.dart';
import 'grid_layout_types.dart';
import 'grid_layout_core.dart' as core;

/// 拖拽状态（RGL DragState）
class DragState {
  DragState({
    this.activeDrag,
    this.oldDragItem,
    this.oldLayout,
  });
  final LayoutItem? activeDrag;
  final LayoutItem? oldDragItem;
  final List<LayoutItem>? oldLayout;
}

/// 缩放状态（RGL ResizeState）
class ResizeState {
  ResizeState({
    this.resizing = false,
    this.oldResizeItem,
    this.oldLayout,
  });
  final bool resizing;
  final LayoutItem? oldResizeItem;
  final List<LayoutItem>? oldLayout;
}

/// 放置状态（RGL DropState）- Flutter 侧可简化为占位位置
class DropState {
  DropState({this.droppingPosition});
  final ({double left, double top})? droppingPosition;
}

/// 垂直紧凑器（默认）
class VerticalCompactor extends Compactor {
  @override
  CompactType get type => CompactType.vertical;
  @override
  bool get allowOverlap => false;
  @override
  List<LayoutItem> compact(List<LayoutItem> layout, int cols) =>
      core.compactVertical(core.cloneLayout(layout), cols);
}

/// 网格布局状态：等价 useGridLayout
class GridLayoutState extends ChangeNotifier {
  GridLayoutState({
    required List<LayoutItem> layout,
    required this.cols,
    this.preventCollision = false,
    /// 松手时是否执行紧凑重排；为 false 时仅更新落点位置，不重排，与拖拽终点一致
    this.compactOnDragEnd = false,
    this.onLayoutChange,
    Compactor? compactor,
  })  : _layout = core.cloneLayout(layout),
        compactor = compactor ?? VerticalCompactor() {
    _applyCorrectAndCompact();
  }

  final int cols;
  final bool preventCollision;
  final bool compactOnDragEnd;
  final void Function(List<LayoutItem> layout)? onLayoutChange;
  final Compactor compactor;

  List<LayoutItem> get layout => _layout;
  List<LayoutItem> _layout;

  DragState _dragState = DragState();
  DragState get dragState => _dragState;

  ResizeState _resizeState = ResizeState();
  ResizeState get resizeState => _resizeState;

  DropState _dropState = DropState();
  DropState get dropState => _dropState;

  bool _isDragging = false;

  int get containerHeight => core.bottom(_layout);
  bool get isInteracting =>
      _dragState.activeDrag != null ||
      _resizeState.resizing ||
      _dropState.droppingPosition != null;

  void _applyCorrectAndCompact() {
    core.correctBounds(_layout, cols);
    _layout = compactor.compact(_layout, cols);
  }

  void setLayoutFromProps(List<LayoutItem> propsLayout) {
    if (_isDragging) return;
    _layout = core.cloneLayout(propsLayout);
    _applyCorrectAndCompact();
    notifyListeners();
  }

  void setLayout(List<LayoutItem> newLayout) {
    _layout = core.cloneLayout(newLayout);
    core.correctBounds(_layout, cols);
    _layout = compactor.compact(_layout, cols);
    onLayoutChange?.call(_layout);
    notifyListeners();
  }

  LayoutItem? onDragStart(String itemId, int x, int y) {
    final item = core.getLayoutItem(_layout, itemId);
    if (item == null) return null;
    _isDragging = true;
    final placeholder = core.cloneLayoutItem(item);
    placeholder.x = x;
    placeholder.y = y;
    placeholder.moved = false;
    _dragState = DragState(
      activeDrag: placeholder,
      oldDragItem: core.cloneLayoutItem(item),
      oldLayout: core.cloneLayout(_layout),
    );
    notifyListeners();
    return placeholder;
  }

  void onDrag(String itemId, int x, int y) {
    final item = core.getLayoutItem(_layout, itemId);
    if (item == null) return;
    _dragState = DragState(
      activeDrag: _dragState.activeDrag != null
          ? (core.cloneLayoutItem(_dragState.activeDrag!)..x = x..y = y)
          : null,
      oldDragItem: _dragState.oldDragItem,
      oldLayout: _dragState.oldLayout,
    );
    final newLayout = core.moveElement(
      _layout,
      item,
      x,
      y,
      true,
      preventCollision,
      compactor.type,
      cols,
      allowOverlap: compactor.allowOverlap,
    );
    _layout = compactor.compact(newLayout, cols);
    notifyListeners();
  }

  void onDragStop(String itemId, int x, int y) {
    final item = core.getLayoutItem(_layout, itemId);
    if (item == null) return;
    if (compactOnDragEnd) {
      final newLayout = core.moveElement(
        _layout,
        item,
        x,
        y,
        true,
        preventCollision,
        compactor.type,
        cols,
        allowOverlap: compactor.allowOverlap,
      );
      _layout = compactor.compact(newLayout, cols);
    } else {
      // 仅更新落点，不重排，位置与松手时一致
      item.x = x.clamp(0, cols - item.w);
      item.y = y.clamp(0, 999 - item.h);
    }
    _isDragging = false;
    _dragState = DragState();
    onLayoutChange?.call(_layout);
    notifyListeners();
  }

  LayoutItem? onResizeStart(String itemId) {
    final item = core.getLayoutItem(_layout, itemId);
    if (item == null) return null;
    _resizeState = ResizeState(
      resizing: true,
      oldResizeItem: core.cloneLayoutItem(item),
      oldLayout: core.cloneLayout(_layout),
    );
    notifyListeners();
    return item;
  }

  void onResize(String itemId, int w, int h, {int? x, int? y}) {
    final newLayout = _layout.map((item) {
      if (item.i == itemId) {
        final updated = item.copyWith(w: w, h: h);
        if (x != null) updated.x = x;
        if (y != null) updated.y = y;
        return updated;
      }
      return item;
    }).toList();
    core.correctBounds(newLayout, cols);
    _layout = compactor.compact(newLayout, cols);
    notifyListeners();
  }

  void onResizeStop(String itemId, int w, int h) {
    onResize(itemId, w, h);
    _resizeState = ResizeState();
    onLayoutChange?.call(_layout);
    notifyListeners();
  }

  void onDropDragOver(LayoutItem droppingItem, double left, double top) {
    if (core.getLayoutItem(_layout, droppingItem.i) == null) {
      final newLayout = List<LayoutItem>.from(_layout)..add(droppingItem);
      core.correctBounds(newLayout, cols);
      _layout = compactor.compact(newLayout, cols);
    }
    _dropState = DropState(droppingPosition: (left: left, top: top));
    notifyListeners();
  }

  void onDropDragLeave() {
    _layout = _layout.where((item) => item.i != '__dropping-elem__').toList();
    _dropState = DropState();
    notifyListeners();
  }

  void onDrop(LayoutItem droppingItem) {
    _layout = _layout.map((item) {
      if (item.i == '__dropping-elem__') {
        return item.copyWith(i: droppingItem.i);
      }
      return item;
    }).toList();
    core.correctBounds(_layout, cols);
    _layout = compactor.compact(_layout, cols);
    _dropState = DropState();
    onLayoutChange?.call(_layout);
    notifyListeners();
  }
}
