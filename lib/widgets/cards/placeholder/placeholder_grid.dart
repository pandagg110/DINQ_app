import 'package:flutter/material.dart';
import 'placeholder_card.dart';
import 'use_placeholders.dart';

/// 占位网格：先不添加 gap，直接按格定位；宽高也不考虑 gap。
/// left = x * contentSlotWidth，top = y * mainRowHeight；
/// width = w * contentSlotWidth，height = h * mainRowHeight。
/// child 暂时用红色 Container 渲染，便于对齐调试。
class PlaceholderGrid extends StatelessWidget {
  const PlaceholderGrid({
    super.key,
    required this.positions,
    required this.contentSlotWidth,
    required this.mainRowHeight,
    required this.onPlaceholderClick,
    required this.onPlaceholderDelete,
    required this.width,
  });

  final List<PlaceholderPosition> positions;
  final double contentSlotWidth;
  final double mainRowHeight;
  final void Function(PlaceholderPosition pos) onPlaceholderClick;
  final void Function(String type) onPlaceholderDelete;
  final double width;
  @override
  Widget build(BuildContext context) {
    if (positions.isEmpty) return const SizedBox.shrink();
    final cellWidth = width / 4;
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
              left: pos.x * cellWidth,
              top: pos.y * cellWidth,
              width: pos.config.size.w * cellWidth,
              height: pos.config.size.h * cellWidth,
              child: Container(
                padding: EdgeInsets.fromLTRB(12, 0, 12, 24),
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
