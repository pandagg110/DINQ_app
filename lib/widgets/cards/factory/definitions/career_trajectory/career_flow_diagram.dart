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

  Color _parseColor(String colorStr) {
    try {
      if (colorStr.startsWith('#')) {
        return Color(int.parse(colorStr.substring(1), radix: 16) + 0xFF000000);
      }
      return const Color(0xFF1487FA);
    } catch (e) {
      return const Color(0xFF1487FA);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Use percentage-based coordinates (0-100)
    const width = 100.0;
    const height = 100.0;
    const nodeWidth = 0.0; // No node thickness (just flow paths)
    const leftX = 0.0; // Left edge (target side with vertical bar)
    const rightX = 100.0; // Right edge (source side)

    // Source nodes (right side, three equal parts)
    const equalPart = 100.0 / 3.0;
    final sources = [
      {
        'id': 'A',
        'x': rightX,
        'y': 0.0,
        'width': nodeWidth,
        'height': equalPart,
        'color': colors[0],
      },
      {
        'id': 'B',
        'x': rightX,
        'y': equalPart,
        'width': nodeWidth,
        'height': equalPart,
        'color': colors[1],
      },
      {
        'id': 'C',
        'x': rightX,
        'y': equalPart * 2,
        'width': nodeWidth,
        'height': equalPart,
        'color': colors[2],
      },
    ];

    // Calculate target positions based on percentages
    // Stack them vertically with proportional heights
    final targets = [
      {
        'id': 'A',
        'x': rightX,
        'y': 0.0,
        'width': nodeWidth,
        'height': careerA,
        'color': colors[0],
      },
      {
        'id': 'B',
        'x': rightX,
        'y': careerA,
        'width': nodeWidth,
        'height': careerB,
        'color': colors[1],
      },
      {
        'id': 'C',
        'x': rightX,
        'y': careerA + careerB,
        'width': nodeWidth,
        'height': careerC,
        'color': colors[2],
      },
    ];

    // Generate flow paths (straight lines on right, curves on left)
    // Right side has straight vertical edges, curves start at curveStartX
    const curveStartX = 15.0; // Where the curve begins
    const controlOffset = 12.0; // Control point offset for the curve

    // Scale factor to convert percentage coordinates to actual pixels
    final scaleX = size.width / width;
    final scaleY = size.height / height;

    // Draw flows in reverse order so first flow is on top
    for (int i = targets.length - 1; i >= 0; i--) {
      final target = targets[i];
      final source = sources[i];
      
      final sourceYStart = (source['y'] as double) * scaleY;
      final sourceYEnd = ((source['y'] as double) + (source['height'] as double)) * scaleY;
      final targetYStart = (target['y'] as double) * scaleY;
      final targetYEnd = ((target['y'] as double) + (target['height'] as double)) * scaleY;

      final sourceX = (source['x'] as double) * scaleX;
      final curveStartXPx = curveStartX * scaleX;
      final leftXPx = leftX * scaleX;
      final controlOffsetXPx = controlOffset * scaleX;

      // Create path for the flow band
      // Right side: straight vertical edges from rightX to curveStartX
      // Left side: curves from curveStartX to leftX (vertical bar)
      final path = Path()
        ..moveTo(sourceX, sourceYStart) // M rightX sourceYStart
        ..lineTo(curveStartXPx, sourceYStart) // L curveStartX sourceYStart
        ..cubicTo(
          curveStartXPx - controlOffsetXPx, sourceYStart, // C curveStartX - controlOffset, sourceYStart
          leftXPx + controlOffsetXPx, targetYStart, // leftX + controlOffset, targetYStart
          leftXPx, targetYStart, // leftX, targetYStart
        )
        ..lineTo(leftXPx, targetYEnd) // L leftX targetYEnd
        ..cubicTo(
          leftXPx + controlOffsetXPx, targetYEnd, // C leftX + controlOffset, targetYEnd
          curveStartXPx - controlOffsetXPx, sourceYEnd, // curveStartX - controlOffset, sourceYEnd
          curveStartXPx, sourceYEnd, // curveStartX, sourceYEnd
        )
        ..lineTo(sourceX, sourceYEnd) // L rightX sourceYEnd
        ..close(); // Z

      // Fill with color at 30% opacity (normal state)
      final color = _parseColor(target['color'] as String);
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = color.withOpacity(0.3);

      canvas.drawPath(path, paint);
    }

    // Draw right edge bars - solid 3px width
    final barWidth = 3.0 * scaleX;
    for (int i = 0; i < sources.length; i++) {
      final source = sources[i];
      final sourceY = (source['y'] as double) * scaleY;
      final sourceHeight = (source['height'] as double) * scaleY;
      final sourceX = (source['x'] as double) * scaleX;

      final barPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = _parseColor(source['color'] as String);

      canvas.drawRect(
        Rect.fromLTWH(
          sourceX - barWidth,
          sourceY,
          barWidth,
          sourceHeight,
        ),
        barPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant FlowDiagramPainter oldDelegate) {
    return oldDelegate.careerA != careerA ||
        oldDelegate.careerB != careerB ||
        oldDelegate.careerC != careerC ||
        oldDelegate.colors != colors;
  }
}
