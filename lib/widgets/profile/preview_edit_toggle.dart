import 'package:flutter/material.dart';

/// Preview / Edit 切换条：仅滑块滑动动画，key 固定便于保留 State。
class PreviewEditToggle extends StatelessWidget {
  const PreviewEditToggle({
    super.key,
    required this.isPreviewMode,
    this.onPreviewModeChanged,
  });

  final bool isPreviewMode;
  final ValueChanged<bool>? onPreviewModeChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        const inset = 4.0;
        final segmentWidth = (w - inset * 2) / 2;
        final sliderWidth = segmentWidth - inset;
        return Container(
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                left: isPreviewMode ? inset : segmentWidth + inset,
                top: inset,
                bottom: inset,
                width: sliderWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => onPreviewModeChanged?.call(true),
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: Text(
                          'Preview',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: isPreviewMode
                                ? const Color(0xFF171717)
                                : const Color(0xFF9CA3AF),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => onPreviewModeChanged?.call(false),
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: Text(
                          'Edit',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: !isPreviewMode
                                ? const Color(0xFF171717)
                                : const Color(0xFF9CA3AF),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
