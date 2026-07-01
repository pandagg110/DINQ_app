import 'package:flutter/material.dart';

/// Career Trajectory card, aligned with Web ShareCard/cards/CareerCard.tsx.
class CareerCard extends StatelessWidget {
  const CareerCard({super.key, this.segments = const []});

  final List<dynamic> segments;

  static const _baseTextStyle = TextStyle(fontFamily: 'Geist');

  @override
  Widget build(BuildContext context) {
    final topSegment = _topSegment;
    final representative = topSegment?['representative'];
    final hasContent = topSegment != null && representative is Map;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF323232).withValues(alpha: 0.07),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.trending_up,
                  size: 28,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Career',
                style: _baseTextStyle.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          if (hasContent)
            SizedBox(
              height: 48,
              child: Row(
                children: [
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2C6FF),
                      border: Border.all(color: Colors.black),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 32,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: Colors.black),
                          ),
                          child: Text(
                            '${((topSegment['percentage'] as num?) ?? 0).round()}%',
                            style: _baseTextStyle.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _capitalize(
                            (topSegment['category'] ?? 'Unknown').toString(),
                          ),
                          style: _baseTextStyle.copyWith(
                            fontSize: 24,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 48,
                      color: const Color(0xFFF8F1FF),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _RoundNetworkImage(
                            url:
                                (representative['avatarUrl'] ??
                                        representative['avatar_url'] ??
                                        '')
                                    .toString(),
                            size: 36,
                          ),
                          const SizedBox(width: 16),
                          Flexible(
                            child: Text(
                              (representative['name'] ?? '').toString(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _baseTextStyle.copyWith(
                                fontSize: 20,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 6,
                    height: 48,
                    color: const Color(0xFFE2C6FF),
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: Center(
                child: Text(
                  'No content yet.',
                  style: _baseTextStyle.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Map<String, dynamic>? get _topSegment {
    Map<String, dynamic>? top;
    for (final segment in segments) {
      if (segment is! Map) continue;
      final mapped = Map<String, dynamic>.from(segment);
      final percentage = mapped['percentage'] is num
          ? mapped['percentage'] as num
          : 0;
      final topPercentage = top?['percentage'] is num
          ? top!['percentage'] as num
          : 0;
      if (top == null || percentage > topPercentage) top = mapped;
    }
    return top;
  }

  static String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}

class _RoundNetworkImage extends StatelessWidget {
  const _RoundNetworkImage({required this.url, required this.size});

  final String url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final validUrl = url.startsWith('http');
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: validUrl
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _fallback(),
              )
            : _fallback(),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      color: const Color(0xFFF3F4F6),
      child: Icon(
        Icons.person,
        color: const Color(0xFF9CA3AF),
        size: size * 0.58,
      ),
    );
  }
}
