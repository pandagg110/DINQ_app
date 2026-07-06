import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../common/asset_icon.dart';
import '../../../utils/asset_path.dart';

/// LinkedIn timeline card, aligned with Web ShareCard/cards/LinkedInCard.tsx.
class LinkedInCard extends StatelessWidget {
  const LinkedInCard({super.key, this.careerJourney = const []});

  final List<dynamic> careerJourney;

  @override
  Widget build(BuildContext context) {
    final items = careerJourney
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final hasData = items.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AssetIcon(asset: 'icons/social-icons/LinkedIn.svg', size: 48),
          const SizedBox(height: 30),
          if (!hasData)
            const Expanded(child: _EmptyState())
          else
            Expanded(child: _Timeline(items: items)),
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.items});

  final List<Map<String, dynamic>> items;

  static const double _svgHeight = 160;
  static const double _startX = 25;
  static const double _endX = 575;

  @override
  Widget build(BuildContext context) {
    final scores = items.map((e) => _scoreOf(e)).toList();
    final maxScore = scores.reduce(math.max);
    final minScore = scores.reduce(math.min);
    final range = maxScore - minScore == 0 ? 1.0 : maxScore - minScore;

    double getY(double score) {
      final normalized = (score - minScore) / range;
      return _svgHeight - 40 - normalized * 80;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final scale = width / 600;
        final spacing = items.length > 1
            ? (_endX - _startX) / (items.length - 1)
            : 0.0;
        final points = <Offset>[
          for (var i = 0; i < items.length; i++)
            Offset(_startX + i * spacing, getY(scores[i])),
        ];
        final visibleYearLabels = _visibleYearLabelIndices(points, scale);

        return Column(
          children: [
            SizedBox(
              height: _svgHeight,
              width: double.infinity,
              child: CustomPaint(painter: _TimelinePainter(points: points)),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: math.max(0, constraints.maxHeight - _svgHeight - 8),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (var i = 0; i < items.length; i++)
                    Positioned(
                      left: points[i].dx * scale - 30,
                      width: 60,
                      top: 0,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Transform.translate(
                            offset: Offset(
                              0,
                              -(_svgHeight - points[i].dy + 18),
                            ),
                            child: _CompanyLogo(
                              url: (items[i]['logo'] ?? '').toString(),
                            ),
                          ),
                          if (visibleYearLabels.contains(i))
                            Text(
                              (items[i]['year'] ?? '').toString(),
                              maxLines: 1,
                              overflow: TextOverflow.clip,
                              style: const TextStyle(
                                fontFamily: 'Geist',
                                fontSize: 18,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  static Set<int> _visibleYearLabelIndices(List<Offset> points, double scale) {
    if (points.length <= 2) {
      return {for (var i = 0; i < points.length; i++) i};
    }

    const minLabelGap = 72.0;
    final selected = <int>[0];

    for (var i = 1; i < points.length - 1; i++) {
      final x = points[i].dx * scale;
      final previousX = points[selected.last].dx * scale;
      if (x - previousX >= minLabelGap) {
        selected.add(i);
      }
    }

    final lastIndex = points.length - 1;
    final lastX = points[lastIndex].dx * scale;
    while (selected.length > 1 &&
        lastX - points[selected.last].dx * scale < minLabelGap) {
      selected.removeLast();
    }
    if (lastX - points[selected.last].dx * scale >= minLabelGap) {
      selected.add(lastIndex);
    }

    return selected.toSet();
  }

  static double _scoreOf(Map<String, dynamic> item) {
    final value = item['score'];
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class _TimelinePainter extends CustomPainter {
  const _TimelinePainter({required this.points});

  final List<Offset> points;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 600;
    final sy = size.height / 160;
    Offset scalePoint(Offset point) => Offset(point.dx * sx, point.dy * sy);

    final dashedPaint = Paint()
      ..color = const Color(0xFFD1D5DB)
      ..strokeWidth = 2;
    for (final point in points) {
      _drawDashedLine(
        canvas,
        Offset(point.dx * sx, 0),
        Offset(point.dx * sx, size.height),
        dashedPaint,
      );
    }

    if (points.isEmpty) return;
    final scaledPoints = points.map(scalePoint).toList();
    final areaPath = Path()
      ..moveTo(scaledPoints.first.dx, scaledPoints.first.dy);
    for (final point in scaledPoints.skip(1)) {
      areaPath.lineTo(point.dx, point.dy);
    }
    areaPath
      ..lineTo(575 * sx, size.height)
      ..lineTo(25 * sx, size.height)
      ..close();
    canvas.drawPath(
      areaPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x6693C5FD), Color(0x0D93C5FD)],
        ).createShader(Offset.zero & size),
    );

    final linePath = Path()
      ..moveTo(scaledPoints.first.dx, scaledPoints.first.dy);
    for (final point in scaledPoints.skip(1)) {
      linePath.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = const Color(0xFF171717)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashHeight = 5.0;
    const dashSpace = 5.0;
    var y = start.dy;
    while (y < end.dy) {
      canvas.drawLine(
        Offset(start.dx, y),
        Offset(start.dx, math.min(y + dashHeight, end.dy)),
        paint,
      );
      y += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(_TimelinePainter oldDelegate) =>
      oldDelegate.points != points;
}

class _CompanyLogo extends StatelessWidget {
  const _CompanyLogo({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final validUrl = url.startsWith('http');
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF171717)),
      ),
      clipBehavior: Clip.antiAlias,
      child: validUrl
          ? Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _fallback(),
            )
          : _fallback(),
    );
  }

  Widget _fallback() =>
      Image.asset(assetPath('images/defaultCompany.png'), fit: BoxFit.cover);
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Transform.translate(
        offset: const Offset(0, -20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: SvgPicture.asset(
                assetPath('icons/error.svg'),
                width: 32,
                height: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No content yet.',
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 24,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
