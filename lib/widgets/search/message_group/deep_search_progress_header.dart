import 'package:flutter/material.dart';

/// 与 TSX SingleAgentTree 折叠态标题行对应（不展开工具树）
class DeepSearchProgressHeader extends StatelessWidget {
  const DeepSearchProgressHeader({
    super.key,
    required this.isLoading,
    required this.isDone,
    required this.toolCount,
    required this.foundCount,
    this.durationMs,
  });

  final bool isLoading;
  final bool isDone;
  final int toolCount;
  final int foundCount;
  final int? durationMs;

  @override
  Widget build(BuildContext context) {
    if (toolCount <= 0 && !isLoading) return const SizedBox.shrink();

    final title = isDone
        ? 'Search complete'
        : isLoading
            ? 'Searching'
            : 'Search';

    final stats = <String>[];
    if (toolCount > 0) stats.add('$toolCount tools');
    if (isDone && foundCount > 0) stats.add('$foundCount found');
    if (isDone && durationMs != null && durationMs! >= 2000) {
      stats.add('${(durationMs! / 1000).round()}s');
    }

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (isLoading && !isDone) ...[
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF9E9B93)),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: isDone ? const Color(0xFF171717) : const Color(0xFF6B6862),
            ),
          ),
          if (stats.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              stats.join(' · '),
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF8A8880),
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
