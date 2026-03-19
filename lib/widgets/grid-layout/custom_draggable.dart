import 'package:flutter/material.dart';

import '../../utils/grid_layout_core.dart';
import 'grid_layout_types.dart';

class CustomGridHandleDraggable extends StatefulWidget {
  const CustomGridHandleDraggable({
    super.key,
    required this.item,
    required this.params,
    required this.rectWidth,
    required this.rectHeight,
    required this.child,

    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    this.isDraggable = true,
  });

  final LayoutItem item;
  final GridLayoutParams params;

  /// 渲染出来的像素宽高（由 calcGridItemPosition 得到的 rect）
  final double rectWidth;
  final double rectHeight;

  /// card 原始内容
  final Widget child;

  final void Function()? onDragStart;
  final void Function(int x, int y)? onDragUpdate;
  final void Function(int x, int y)? onDragEnd;

  final bool isDraggable;

  @override
  State<CustomGridHandleDraggable> createState() =>
      _CustomGridHandleDraggableState();
}

class _CustomGridHandleDraggableState extends State<CustomGridHandleDraggable> {
  int? _lastDragX;
  int? _lastDragY;
  bool _dragging = false;

  static const double handleSize = 40.0;
  static const double handleBottom = -16.0; // 严格对齐 move icon

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    if (!widget.isDraggable || item.static_) {
      return SizedBox(
        width: widget.rectWidth,
        height: widget.rectHeight,
        child: widget.child,
      );
    }

    final halfW = widget.rectWidth / 2-20;
    final halfH = widget.rectHeight / 2;

    final base = SizedBox(
      width: widget.rectWidth,
      height: widget.rectHeight,
      child: Opacity(opacity: _dragging ? 0.5 : 1.0, child: widget.child),
    );
    final handleCenterY = widget.rectHeight - handleBottom - handleSize / 2 -20;
    return SizedBox(
      width: widget.rectWidth,
      height: widget.rectHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          base,

          // 只有这个句柄区域会触发拖拽
          Positioned(
            left: (widget.rectWidth - handleSize) / 2,
            bottom: handleBottom,
            width: handleSize,
            height: handleSize,
            child: Draggable<LayoutItem>(
              data: item,
              feedback: Transform.translate(
                offset: Offset(-halfW, -handleCenterY),
                child: Material(
                  type: MaterialType.transparency,
                  elevation: 8,
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.transparent,
                  child: SizedBox(
                    width: widget.rectWidth,
                    height: widget.rectHeight,
                    child: widget.child,
                  ),
                ),
              ),
              feedbackOffset: Offset(0, 0),
              // feedbackOffset: Offset(10, 0),
              onDragStarted: () {
                setState(() => _dragging = true);
                widget.onDragStart?.call();
              },
              onDragUpdate: (details) {
                final stack = context
                    .findAncestorRenderObjectOfType<RenderBox>();
                if (stack == null) return;

                final centerLocal = stack.globalToLocal(details.globalPosition);
                final leftPx = centerLocal.dx - halfW;
                final topPx = centerLocal.dy - halfH;

                final (x, y) = calcXY(
                  widget.params,
                  leftPx,
                  topPx,
                  item.w,
                  item.h,
                );

                _lastDragX = x;
                _lastDragY = y;
                widget.onDragUpdate?.call(x, y);
              },
              onDragEnd: (_) {
                setState(() => _dragging = false);
                final x = _lastDragX ?? item.x;
                final y = _lastDragY ?? item.y;
                widget.onDragEnd?.call(x, y);
              },
              childWhenDragging: const SizedBox.shrink(),

              // 句柄本身不需要可视内容，命中靠 Positioned 的 40x40
              // child:const SizedBox.expand(),
              child: ColoredBox(
                color: Colors.transparent,
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
