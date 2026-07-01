import 'package:flutter/material.dart';

/// Network card, aligned with Web ShareCard/cards/NetworkCard.tsx.
class NetworkCard extends StatelessWidget {
  const NetworkCard({
    super.key,
    this.connections = const [],
    this.currentUserAvatar,
  });

  final List<dynamic> connections;
  final String? currentUserAvatar;

  static const _baseTextStyle = TextStyle(fontFamily: 'Geist');

  @override
  Widget build(BuildContext context) {
    final displayList = connections
        .take(6)
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final hasContent = displayList.isNotEmpty;
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
                  Icons.account_tree_outlined,
                  size: 28,
                  color: Color(0xFF323232),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Network',
                style: _baseTextStyle.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!hasContent)
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
            )
          else
            Row(
              children: [
                _Avatar(url: currentUserAvatar ?? '', size: 56, borderWidth: 4),
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: CustomPaint(painter: _NetworkLinePainter()),
                  ),
                ),
                SizedBox(
                  width: 52 + (displayList.length - 1) * 40,
                  height: 56,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      for (var i = 0; i < displayList.length; i++)
                        Positioned(
                          left: i * 40,
                          top: 2,
                          child: _Avatar(
                            url: _avatarUrl(displayList[i]),
                            size: 52,
                            borderWidth: 3,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  static String _avatarUrl(Map<String, dynamic> item) {
    return (item['avatarUrl'] ?? item['avatar_url'] ?? '').toString();
  }
}

class _NetworkLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFFBDBDBD)
      ..strokeWidth = 2;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, size.height / 2),
        Offset((x + 10).clamp(0, size.width), size.height / 2),
        linePaint,
      );
      x += 20;
    }

    final dotPaint = Paint()..color = Colors.white;
    final dotBorder = Paint()
      ..color = Colors.black
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    for (final dx in <double>[0, size.width]) {
      canvas.drawCircle(Offset(dx, size.height / 2), 6, dotPaint);
      canvas.drawCircle(Offset(dx, size.height / 2), 6, dotBorder);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.url,
    required this.size,
    required this.borderWidth,
  });

  final String url;
  final double size;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = _resolvedAvatarUrl(url);
    final validUrl = resolvedUrl.startsWith('http');
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: borderWidth),
        boxShadow: [
          if (size == 56)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: validUrl
          ? Image.network(
              resolvedUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _fallback(),
            )
          : _fallback(),
    );
  }

  static String _resolvedAvatarUrl(String value) {
    if (!value.startsWith('http')) return '';
    if (value.contains('scholar.google')) return '';
    return value;
  }

  Widget _fallback() {
    return Container(
      color: const Color(0xFFF3F4F6),
      child: Icon(
        Icons.person,
        color: const Color(0xFF9CA3AF),
        size: size * 0.48,
      ),
    );
  }
}
