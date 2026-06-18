import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 对齐 Web `PdfPreviewSkeleton` / `PdfPageSkeleton`。
class PdfPreviewSkeleton extends StatelessWidget {
  const PdfPreviewSkeleton({
    super.key,
    this.showSidebar = true,
    this.maxHeight,
  });

  final bool showSidebar;
  final double? maxHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = maxHeight ?? constraints.maxHeight;
        final pageWidth = _fitPageWidth(context, height);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showSidebar)
              SizedBox(
                width: 140,
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    for (var i = 0; i < 4; i++) ...[
                      _thumbSkeleton(),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 80),
                child: Center(child: PdfPageSkeleton(width: pageWidth)),
              ),
            ),
          ],
        );
      },
    );
  }

  double _fitPageWidth(BuildContext context, double height) {
    final screenW = MediaQuery.sizeOf(context).width;
    final byWidth = math.max(240.0, math.min(screenW - 48, 794.0));
    if (!height.isFinite || height <= 0) return byWidth;
    final byHeight = height / math.sqrt2;
    return math.min(byWidth, byHeight).toDouble();
  }

  Widget _thumbSkeleton() {
    return Column(
      children: [
        Container(
          height: 126,
          decoration: BoxDecoration(
            color: const Color(0xFFEEEDE9),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 20,
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0xFFE4E2DC),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}

class PdfPageSkeleton extends StatelessWidget {
  const PdfPageSkeleton({super.key, required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    final normalized = math.max(240.0, width);
    return SizedBox(
      width: normalized,
      child: AspectRatio(
        aspectRatio: 1 / math.sqrt2,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ClipRect(
              child: Align(
                alignment: Alignment.topLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _bar(width: normalized * 0.5, height: 20, color: const Color(0xFFEEEDE9)),
                    const SizedBox(height: 10),
                    _bar(width: normalized * 0.75, color: const Color(0xFFF1F0EC)),
                    const SizedBox(height: 8),
                    _bar(width: normalized * 0.66, color: const Color(0xFFF1F0EC)),
                    const SizedBox(height: 16),
                    _bar(width: normalized * 0.33, height: 14, color: const Color(0xFFEEEDE9)),
                    const SizedBox(height: 12),
                    for (var i = 0; i < 4; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: _bar(
                          width: normalized * (0.9 - (i % 3) * 0.1),
                          color: const Color(0xFFF1F0EC),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _bar({
    required double width,
    double height = 12,
    required Color color,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

/// Shimmer pulse wrapper for skeleton blocks.
class ResumeSkeletonPulse extends StatefulWidget {
  const ResumeSkeletonPulse({super.key, required this.child});

  final Widget child;

  @override
  State<ResumeSkeletonPulse> createState() => _ResumeSkeletonPulseState();
}

class _ResumeSkeletonPulseState extends State<ResumeSkeletonPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.55, end: 1).animate(_controller),
      child: widget.child,
    );
  }
}
