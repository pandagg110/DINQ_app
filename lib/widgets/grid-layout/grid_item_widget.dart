// ---------------------------------------------------------------------------
// 等价 RGL GridItem：单格项，按格点定位、拖拽回调（中心跟手）
// ---------------------------------------------------------------------------

import 'package:dinq_app/widgets/grid-layout/custom_draggable.dart';
import 'package:flutter/material.dart';
import '../../utils/grid_layout_core.dart';
import 'grid_layout_types.dart';

/// 单格项组件：根据 [item] 与 [params] 计算像素位置，包裹 [child] 并支持拖拽
/// 使用 [AnimatedPositioned] 在位置/尺寸变化时平滑过渡
/// 松手时使用最后一次 [onDragUpdate] 的格点，保证落点与阴影一致
class GridItemWidget extends StatefulWidget {
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
  State<GridItemWidget> createState() => _GridItemWidgetState();
}

class _GridItemWidgetState extends State<GridItemWidget> {
  /// 最后一次 onDragUpdate 的格点，松手时用此作为落点，与阴影位置一致
  int? _lastDragX;
  int? _lastDragY;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final params = widget.params;
    final rect = calcGridItemPosition(params, item.x, item.y, item.w, item.h);
    final canDrag =
        widget.isDraggable && (item.isDraggable ?? true) && !item.static_;

    Widget content = SizedBox(
      width: rect.width,
      height: rect.height,
      child: widget.child,
    );

    if (!canDrag ||
        (widget.onDragStart == null &&
            widget.onDragUpdate == null &&
            widget.onDragEnd == null)) {
      return AnimatedPositioned(
        duration: widget.animationDuration,
        curve: widget.animationCurve,
        left: rect.left,
        top: rect.top,
        width: rect.width,
        height: rect.height,
        child: content,
      );
    }

    final halfW = rect.width / 2;
    final halfH = rect.height / 2;
    content = CustomGridHandleDraggable(
      item: item,
      params: params,
      rectWidth: rect.width,
      rectHeight: rect.height,
      child: widget.child,
      isDraggable: canDrag,
      onDragStart: widget.onDragStart,
      onDragUpdate: widget.onDragUpdate,
      onDragEnd: widget.onDragEnd,
    );
    // content = Draggable<LayoutItem>(
    //   data: item,
    //   feedback: Material(
    //     type: MaterialType.transparency,
    //     elevation: 8,
    //     borderRadius: BorderRadius.circular(4),
    //     color: Colors.transparent,
    //     child: SizedBox(
    //       width: rect.width,
    //       height: rect.height,
    //       child: widget.child,
    //     ),
    //   ),
    //   feedbackOffset: Offset(-halfW, -halfH),
    //   onDragStarted: widget.onDragStart,
    //   onDragUpdate: (details) {
    //     final stack = context.findAncestorRenderObjectOfType<RenderBox>();
    //     if (stack == null) return;
    //     final centerLocal = stack.globalToLocal(details.globalPosition);
    //     final leftPx = centerLocal.dx - halfW;
    //     final topPx = centerLocal.dy - halfH;
    //     final (x, y) = calcXY(params, leftPx, topPx, item.w, item.h);
    //     _lastDragX = x;
    //     _lastDragY = y;
    //     // debugPrint('onDragUpdate: $x, $y');
    //     widget.onDragUpdate?.call(x, y);
    //   },
    //   onDragEnd: (_) {
    //     // 使用最后一次 onDragUpdate 的格点，保证松手后位置与阴影一致
    //     final x = _lastDragX ?? item.x;
    //     final y = _lastDragY ?? item.y;
    //     widget.onDragEnd?.call(x, y);
    //   },
    //   childWhenDragging: Opacity(opacity: 0.5, child: content),
    //   child: content,
    // );
    
    return AnimatedPositioned(
      duration: widget.animationDuration,
      curve: widget.animationCurve,
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: content,
    );
  }
}
