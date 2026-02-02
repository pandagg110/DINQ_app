import 'package:flutter/material.dart';
import 'use_placeholders.dart';
import 'placeholder_card.dart';

/// 占位网格：与 ReorderableStaggeredScrollView 的布局对齐。
/// 用「内容格宽」contentSlotWidth = (总宽 - 列间gap) / 列数，使占位与真实卡片内容区一致，不偏宽。
/// left = x * (contentSlotWidth + gap) + halfGap，宽 = w * contentSlotWidth + (w-1) * gap。
class PlaceholderGrid extends StatelessWidget {
  const PlaceholderGrid({
    super.key,
    required this.positions,
    required this.contentSlotWidth,
    required this.mainRowHeight,
    required this.gap,
    required this.onPlaceholderClick,
    required this.onPlaceholderDelete,
  });

  final List<PlaceholderPosition> positions;
  /// 交叉轴每格「内容」宽度 = (总宽 - (列数-1)*gap) / 列数，与卡片内容区一致
  final double contentSlotWidth;
  /// 主轴每行高度（unitSize + gap），与包内行高一致
  final double mainRowHeight;
  final double gap;
  final void Function(PlaceholderPosition pos) onPlaceholderClick;
  final void Function(String type) onPlaceholderDelete;

  @override
  Widget build(BuildContext context) {
    if (positions.isEmpty) return const SizedBox.shrink();

    final halfGap = gap / 2;
    final heightHalfGap = 26 / 2;
    final cellStep = contentSlotWidth + gap;

    return IgnorePointer(
      ignoring: false,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final pos in positions) ...[
            Positioned(
              left: pos.x * cellStep + halfGap,
              top: pos.y * mainRowHeight + heightHalfGap,
              width: pos.config.size.w * contentSlotWidth + (pos.config.size.w - 1) * gap,
              height: pos.config.size.h * mainRowHeight - gap,
              child: PlaceholderCard(
                config: pos.config,
                onTap: () => onPlaceholderClick(pos),
                onDelete: () => onPlaceholderDelete(pos.config.type),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
