import 'package:flutter/material.dart';

/// 骨架屏组件（与 TSX ChatHistorySkeleton 一致）
class ChatHistorySkeletonWidget extends StatelessWidget {
  const ChatHistorySkeletonWidget({super.key});

  static const List<double> _widths = [0.8, 0.6, 2 / 3];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          _widths.length,
          (i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth * _widths[i];
                return Container(
                  height: 16,
                  width: w,
                  decoration: BoxDecoration(
                    color: const Color(0xFF636363).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
