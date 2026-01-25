import 'package:flutter/material.dart';

class CareerFlowDiagram extends StatelessWidget {
  const CareerFlowDiagram({
    super.key,
    required this.careerA,
    required this.careerB,
    required this.careerC,
    required this.colors,
  });

  final double careerA;
  final double careerB;
  final double careerC;
  final List<String> colors;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: FlowDiagramPainter(
        careerA: careerA,
        careerB: careerB,
        careerC: careerC,
        colors: colors,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class FlowDiagramPainter extends CustomPainter {
  const FlowDiagramPainter({
    required this.careerA,
    required this.careerB,
    required this.careerC,
    required this.colors,
  });

  final double careerA;
  final double careerB;
  final double careerC;
  final List<String> colors;

  @override
  void paint(Canvas canvas, Size size) {
    // Simplified flow diagram - draw connecting lines between segments
    // This is a placeholder implementation
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.grey.withOpacity(0.3);

    // Draw simple connecting lines (simplified version of the TSX flow diagram)
    final centerY = size.height / 2;
    canvas.drawLine(
      Offset(0, centerY),
      Offset(size.width, centerY),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

