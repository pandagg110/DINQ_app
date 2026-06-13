import 'package:flutter/material.dart';

const treeIndent = 20.0;
const treeIndentL2 = 28.0;
const treeL2LineLeft = 8.0;
const treeLineColor = Color(0xFFB5B3AE);
const treeLineColorL2 = Color(0xFFD5D3CE);

/// 与 TSX `leading-7` / `leading-6` / `leading-5` 对齐的行高
const treeLeading7 = 28.0;
const treeLeading6 = 24.0;
const treeLeading5 = 20.0;
const treeRowTopPad = 8.0; // TSX `pt-2`

/// L 形水平分支应对齐的首行垂直中心
const treeL1BranchCenter = treeRowTopPad + treeLeading7 / 2; // pt-2 + leading-7/2
const treeL1BranchCenterNoPad = treeLeading7 / 2;
const treeL2BranchCenter = treeLeading6 / 2;
const treeL2ActivityBranchCenter = 2 + treeLeading5 / 2; // mt-0.5 + leading-5/2

/// 静态 L 形连接线（与 TSX rounded-bl-lg border 一致）
class TreeSolidLConnector extends StatelessWidget {
  const TreeSolidLConnector({
    super.key,
    required this.width,
    required this.height,
    this.radius = 8,
    this.color = treeLineColor,
    this.showLeftBorder = true,
  });

  final double width;
  final double height;
  final double radius;
  final Color color;
  final bool showLeftBorder;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            left: showLeftBorder
                ? BorderSide(color: color, width: 1)
                : BorderSide.none,
            bottom: BorderSide(color: color, width: 1),
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(radius),
          ),
        ),
      ),
    );
  }
}

/// 动画虚线 L 形（与 TSX MarchingAntsL 一致）
class TreeMarchingAntsL extends StatefulWidget {
  const TreeMarchingAntsL({
    super.key,
    required this.width,
    required this.height,
    this.radius = 8,
    this.color = treeLineColor,
  });

  final double width;
  final double height;
  final double radius;
  final Color color;

  @override
  State<TreeMarchingAntsL> createState() => _TreeMarchingAntsLState();
}

class _TreeMarchingAntsLState extends State<TreeMarchingAntsL>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.width, widget.height + 1),
          painter: _MarchingAntsLPainter(
            width: widget.width,
            height: widget.height,
            radius: widget.radius,
            color: widget.color,
            dashOffset: _controller.value * 5,
          ),
        );
      },
    );
  }
}

class _MarchingAntsLPainter extends CustomPainter {
  _MarchingAntsLPainter({
    required this.width,
    required this.height,
    required this.radius,
    required this.color,
    required this.dashOffset,
  });

  final double width;
  final double height;
  final double radius;
  final Color color;
  final double dashOffset;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(0.5, 0)
      ..lineTo(0.5, height - radius)
      ..quadraticBezierTo(0.5, height, radius + 0.5, height)
      ..lineTo(width, height);

    for (final metric in path.computeMetrics()) {
      var distance = dashOffset % 5;
      while (distance < metric.length) {
        final next = (distance + 2).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += 5;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MarchingAntsLPainter oldDelegate) =>
      oldDelegate.dashOffset != dashOffset;
}

/// 纵向主干线
class TreeVerticalTrunk extends StatelessWidget {
  const TreeVerticalTrunk({
    super.key,
    required this.color,
    this.left = 0,
    this.top = 0,
    this.bottom = 0,
    this.animated = false,
  });

  final Color color;
  final double left;
  final double top;
  final double bottom;
  final bool animated;

  @override
  Widget build(BuildContext context) {
    if (animated) {
      return Positioned(
        left: left,
        top: top,
        bottom: bottom,
        child: TreeMarchingAntsVertical(color: color),
      );
    }
    return Positioned(
      left: left,
      top: top,
      bottom: bottom,
      child: Container(width: 1, color: color),
    );
  }
}

class TreeMarchingAntsVertical extends StatefulWidget {
  const TreeMarchingAntsVertical({super.key, this.color = treeLineColor});

  final Color color;

  @override
  State<TreeMarchingAntsVertical> createState() =>
      _TreeMarchingAntsVerticalState();
}

class _TreeMarchingAntsVerticalState extends State<TreeMarchingAntsVertical>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight.isFinite && constraints.maxHeight > 0
            ? constraints.maxHeight
            : 1.0;
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              size: Size(1, height),
              painter: _VerticalDashPainter(
                color: widget.color,
                dashOffset: _controller.value * 5,
              ),
            );
          },
        );
      },
    );
  }
}

class _VerticalDashPainter extends CustomPainter {
  _VerticalDashPainter({required this.color, required this.dashOffset});

  final Color color;
  final double dashOffset;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    var y = dashOffset % 5;
    while (y < size.height) {
      final end = (y + 2).clamp(0.0, size.height);
      canvas.drawLine(Offset(0, y), Offset(0, end), paint);
      y += 5;
    }
  }

  @override
  bool shouldRepaint(covariant _VerticalDashPainter oldDelegate) =>
      oldDelegate.dashOffset != dashOffset;
}

/// 顶部短虚线（ul 顶部 trunk，height: 8）
class TreeTopTrunk extends StatelessWidget {
  const TreeTopTrunk({super.key, this.animated = false});

  final bool animated;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 8,
      child: animated
          ? const TreeMarchingAntsVertical()
          : Container(width: 1, height: 8, color: treeLineColor),
    );
  }
}
