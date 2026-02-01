import 'package:flutter/material.dart';

/// Career Trajectory 卡片，对应 Web ShareCard/cards/CareerCard.tsx（简化版）
class CareerCard extends StatelessWidget {
  const CareerCard({super.key, this.segments = const []});

  final List<dynamic> segments;

  @override
  Widget build(BuildContext context) {
    dynamic topSegment;
    if (segments.isNotEmpty) {
      topSegment = segments.reduce((a, b) {
        final ap = a is Map ? (a['percentage'] ?? 0) : 0;
        final bp = b is Map ? (b['percentage'] ?? 0) : 0;
        return (ap as num) >= (bp as num) ? a : b;
      });
    }
    final hasContent = topSegment != null &&
        (topSegment is Map && topSegment['representative'] != null);
    final representative = hasContent && topSegment is Map
        ? (topSegment['representative'] ?? '').toString()
        : '';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF323232).withOpacity(0.07), width: 2),
                ),
                child: const Icon(Icons.trending_up, size: 28, color: Color(0xFF000000)),
              ),
              const SizedBox(width: 16),
              const Text(
                'Career',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF000000),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          if (hasContent && representative.isNotEmpty)
            Text(
              representative,
              style: const TextStyle(
                fontFamily: 'Geist',
                fontSize: 24,
                color: Color(0xFF171717),
                height: 1.35,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            )
          else
            const Expanded(
              child: Center(
                child: Text(
                  'No content yet.',
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 24,
                    color: Color(0xFF000000),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
