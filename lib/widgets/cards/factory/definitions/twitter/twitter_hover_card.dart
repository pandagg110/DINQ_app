import 'package:flutter/material.dart';
import 'package:flutter_portal/flutter_portal.dart';

class TwitterHoverCard extends StatefulWidget {
  const TwitterHoverCard({
    super.key,
    required this.follower,
    required this.child,
  });

  final Map<String, dynamic> follower;
  final Widget child;

  @override
  State<TwitterHoverCard> createState() => _TwitterHoverCardState();
}

class _TwitterHoverCardState extends State<TwitterHoverCard> {
  bool _isHovered = false;

  String _truncateName(String name, {int maxLength = 25}) {
    if (name.length <= maxLength) return name;
    return '${name.substring(0, maxLength - 1)}...';
  }

  @override
  Widget build(BuildContext context) {
    final fullName = widget.follower['full_name'] as String? ?? '';
    final username = widget.follower['username'] as String? ?? '';
    final displayName = fullName.isNotEmpty ? fullName : username;

    return PortalTarget(
      visible: _isHovered,
      portalFollower: Align(
        alignment: Alignment.bottomCenter,
        child: Transform.translate(
          offset: const Offset(0, -8),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Stack(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _truncateName(displayName),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@$username',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                  // Arrow at bottom
                  Positioned(
                    bottom: -4,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: CustomPaint(
                        size: const Size(8, 4),
                        painter: _ArrowPainter(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      child: MouseRegion(
        onEnter: (_) {
          if (mounted) {
            setState(() => _isHovered = true);
          }
        },
        onExit: (_) {
          if (mounted) {
            setState(() => _isHovered = false);
          }
        },
        child: widget.child,
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
    
    final borderPaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

