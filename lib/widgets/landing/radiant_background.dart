import 'dart:math' as math;
import 'package:flutter/material.dart';

class RadiantBackground extends StatelessWidget {
  const RadiantBackground({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RadiantPainter(),
      child: Container(
        width: double.infinity,
        padding: padding ?? const EdgeInsets.symmetric(vertical: 64),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFDFDFD), Color(0xFFEDEDED)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: child,
      ),
    );
  }
}

class _RadiantPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.04)
      ..strokeWidth = 1;

    const lineCount = 60;
    for (int i = 0; i < lineCount; i++) {
      final angle = (i / lineCount) * 3.14159 * 2;
      final dx = center.dx + (size.width * 0.7) * math.cos(angle);
      final dy = center.dy + (size.height * 0.7) * math.sin(angle);
      canvas.drawLine(center, Offset(dx, dy), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

