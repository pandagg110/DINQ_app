import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/dinq_tokens.dart';

/// 对齐 Web `ResumePreview.tsx` 内联 `PdfPreviewSkeleton`。
class PdfPreviewSkeleton extends StatelessWidget {
  const PdfPreviewSkeleton({
    super.key,
    this.showSidebar = true,
    this.maxHeight,
  });

  final bool showSidebar;
  final double? maxHeight;

  static bool _isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 768;

  @override
  Widget build(BuildContext context) {
    final isMobile = _isMobile(context);
    final showThumbSidebar = showSidebar && !isMobile;
    final hPad = isMobile ? 12.0 : 32.0;
    final vPadTop = isMobile ? 16.0 : 32.0;
    // Loading 态无底部 zoom 控件，移动端少留空白避免骨架被压矮后溢出。
    final vPadBottom = isMobile ? 16.0 : 80.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = maxHeight ?? constraints.maxHeight;
        final mainH = height.isFinite
            ? math.max(0.0, height - vPadTop - vPadBottom)
            : height;

        return ColoredBox(
          color: DinqTokens.bgPage,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showThumbSidebar) _ThumbSidebar(),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(hPad, vPadTop, hPad, vPadBottom),
                  child: Center(
                    child: PdfPageSkeleton(
                      maxWidth: 794,
                      maxHeight: mainH,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 侧栏缩略图占位（Web: w-[140px] space-y-3 p-3）。
class _ThumbSidebar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          for (var i = 0; i < 4; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _ThumbSkeletonItem(),
          ],
        ],
      ),
    );
  }
}

class _ThumbSkeletonItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SkeletonPulse(
          child: Container(
            height: 126,
            decoration: BoxDecoration(
              color: const Color(0xFFEEEDE9),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SkeletonPulse(
          child: Container(
            width: 20,
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFFE4E2DC),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ],
    );
  }
}

/// 主文档占位（Web: max-w-[794px] animate-pulse bg-white + 两段正文）。
class PdfPageSkeleton extends StatelessWidget {
  const PdfPageSkeleton({
    super.key,
    this.maxWidth = 794,
    this.maxHeight,
  });

  final double maxWidth;
  final double? maxHeight;

  static bool _isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 768;

  @override
  Widget build(BuildContext context) {
    final isMobile = _isMobile(context);
    final innerPad = isMobile ? 32.0 : 40.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.min(maxWidth, constraints.maxWidth);
        // Prefer the parent budget; fall back to A4 aspect only when unbounded.
        final availableH = constraints.maxHeight;
        final height = maxHeight != null && maxHeight!.isFinite && maxHeight! > 0
            ? math.min(
                maxHeight!,
                availableH.isFinite ? availableH : maxHeight!,
              )
            : (availableH.isFinite && availableH > 0
                ? availableH
                : width / math.sqrt2);

        return SizedBox(
          width: width,
          height: height.isFinite ? height : null,
          child: SkeletonPulse(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                // Fixed page height + fixed bars used to overflow (~42px on
                // mobile). Scroll+clip keeps layout valid; excess is hidden.
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.all(innerPad),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _bar(
                          width: width * 0.5,
                          height: 28,
                          color: const Color(0xFFEEEDE9),
                        ),
                        const SizedBox(height: 12),
                        _bar(
                          width: width * 0.75,
                          height: 12,
                          color: const Color(0xFFF1F0EC),
                        ),
                        const SizedBox(height: 8),
                        _bar(
                          width: width * 0.66,
                          height: 12,
                          color: const Color(0xFFF1F0EC),
                        ),
                        const SizedBox(height: 20),
                        _section(
                          contentWidth: width - innerPad * 2,
                          titleFraction: 1 / 3,
                          titleHeight: 16,
                          lineCount: 9,
                          lineWidthFactor: (i) => (92 - (i % 4) * 9) / 100,
                        ),
                        const SizedBox(height: 20),
                        _section(
                          contentWidth: width - innerPad * 2,
                          titleFraction: 2 / 5,
                          titleHeight: 16,
                          lineCount: 7,
                          lineWidthFactor: (i) => (88 - (i % 3) * 12) / 100,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _section({
    required double contentWidth,
    required double titleFraction,
    required double titleHeight,
    required int lineCount,
    required double Function(int index) lineWidthFactor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _bar(
          width: contentWidth * titleFraction,
          height: titleHeight,
          color: const Color(0xFFEEEDE9),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < lineCount; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _bar(
              width: contentWidth * lineWidthFactor(i),
              height: 12,
              color: const Color(0xFFF1F0EC),
            ),
          ),
      ],
    );
  }

  Widget _bar({
    required double width,
    required double height,
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

/// 对齐 Web Tailwind `animate-pulse`（opacity 1 ↔ 0.5）。
class SkeletonPulse extends StatefulWidget {
  const SkeletonPulse({super.key, required this.child});

  final Widget child;

  @override
  State<SkeletonPulse> createState() => _SkeletonPulseState();
}

class _SkeletonPulseState extends State<SkeletonPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
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
      opacity: Tween<double>(begin: 0.5, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: widget.child,
    );
  }
}
