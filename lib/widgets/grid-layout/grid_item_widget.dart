// ---------------------------------------------------------------------------
// 等价 RGL GridItem：单格项，按格点定位、拖拽回调（中心跟手）
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import '../../utils/grid_layout_core.dart';
import 'grid_layout_types.dart';

/// 单格项组件：根据 [item] 与 [params] 计算像素位置，包裹 [child] 并支持拖拽
/// 使用 [AnimatedPositioned] 在位置/尺寸变化时平滑过渡
class GridItemWidget extends StatelessWidget {
  const GridItemWidget({
    super.key,
    required this.item,
    required this.params,
    required this.child,
    this.isDraggable = true,
    this.animationDuration = const Duration(milliseconds: 200),
    this.animationCurve = Curves.easeInOut,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
  });

  final LayoutItem item;
  final GridLayoutParams params;
  final Widget child;
  final bool isDraggable;
  final Duration animationDuration;
  final Curve animationCurve;
  final void Function()? onDragStart;
  final void Function(int x, int y)? onDragUpdate;
  final void Function(int x, int y)? onDragEnd;

  @override
  Widget build(BuildContext context) {
    final rect = calcGridItemPosition(params, item.x, item.y, item.w, item.h);
    final canDrag = isDraggable && (item.isDraggable ?? true) && !item.static_;

    Widget content = SizedBox(
      width: rect.width,
      height: rect.height,
      child: child,
    );

    if (!canDrag || (onDragStart == null && onDragUpdate == null && onDragEnd == null)) {
      return AnimatedPositioned(
        duration: animationDuration,
        curve: animationCurve,
        left: rect.left,
        top: rect.top,
        width: rect.width,
        height: rect.height,
        child: content,
      );
    }

    // 中心跟手：feedback 中心在指针，落点用中心格点
    final halfW = rect.width / 2;
    final halfH = rect.height / 2;
    content = Draggable<LayoutItem>(
      data: item,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          width: rect.width,
          height: rect.height,
          child: child,
        ),
      ),
      feedbackOffset: Offset(-halfW, -halfH),
      onDragStarted: onDragStart,
      onDragUpdate: (details) {
        final stack = context.findAncestorRenderObjectOfType<RenderBox>();
        if (stack == null) return;
        final centerLocal = stack.globalToLocal(details.globalPosition);
        final leftPx = centerLocal.dx - halfW;
        final topPx = centerLocal.dy - halfH;
        final (x, y) = calcXY(params, leftPx, topPx, item.w, item.h);
        onDragUpdate?.call(x, y);
      },
      onDragEnd: (details) {
        final stack = context.findAncestorRenderObjectOfType<RenderBox>();
        if (stack == null) return;
        final centerLocal = stack.globalToLocal(details.offset);
        final leftPx = centerLocal.dx - halfW;
        final topPx = centerLocal.dy - halfH;
        final (x, y) = calcXY(params, leftPx, topPx, item.w, item.h,
            toleranceX: 8, toleranceY: 8);
        onDragEnd?.call(x, y);
      },
      childWhenDragging: Opacity(opacity: 0.5, child: content),
      child: content,
    );

    return AnimatedPositioned(
      duration: animationDuration,
      curve: animationCurve,
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: content,
    );
  }
}
