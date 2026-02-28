import 'package:flutter/material.dart';
import 'placeholder_card.dart';
import 'use_placeholders.dart';

/// 占位网格：与 GridLayoutWidget 对齐，按格点 + gap 定位。
/// left = x * (contentSlotWidth + gap)，top = y * mainRowHeight；
/// width/height = 格数 * contentSlotWidth + (格数 - 1) * gap。
/// [dragSnapshot] 为拖拽过程中的数据，可用于高亮落点或避免与拖拽项重叠等。
class PlaceholderGrid extends StatelessWidget {
  const PlaceholderGrid({
    super.key,
    required this.positions,
    required this.contentSlotWidth,
    required this.mainRowHeight,
    required this.onPlaceholderClick,
    required this.onPlaceholderDelete,
    required this.width,
    this.dragSnapshot,
  });

  final List<PlaceholderPosition> positions;
  final double contentSlotWidth;
  final double mainRowHeight;
  final void Function(PlaceholderPosition pos) onPlaceholderClick;
  final void Function(String type) onPlaceholderDelete;
  final double width;
  /// 拖拽过程中的数据（由外部从 GridLayoutState.dragState 转换后传入）
  final GridDragSnapshot? dragSnapshot;

  /// 与 GridLayoutWidget 一致：格宽 + 间隙 = 每格步长
  static double _slotStep(double contentSlotWidth, double mainRowHeight) {
    return mainRowHeight; // mainRowHeight == contentSlotWidth + gap
  }

  static double _cellSize(int count, double contentSlotWidth, double gap) {
    if (count <= 0) return 0;
    return count * contentSlotWidth + (count - 1) * gap;
  }

  @override
  Widget build(BuildContext context) {
    if (positions.isEmpty) return const SizedBox.shrink();
    final gap = mainRowHeight - contentSlotWidth;
    final step = _slotStep(contentSlotWidth, mainRowHeight);
    return IgnorePointer(
      ignoring: false,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final pos in positions) ...[
            AnimatedPositioned(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOut,
              key: ValueKey('placeholder_${pos.config.type}'),
              left: pos.x * step,
              top: pos.y * step,
              width: _cellSize(pos.config.size.w, contentSlotWidth, gap),
              height: _cellSize(pos.config.size.h, contentSlotWidth, gap),
              child: Container(
                padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                child: PlaceholderCard(
                  config: pos.config,
                  onTap: () => onPlaceholderClick(pos),
                  onDelete: () => onPlaceholderDelete(pos.config.type),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
