import 'package:flutter/material.dart';

enum PreviewEditToggleStyle { profile, myDinq }

/// Page / Resume 切换条。
/// [PreviewEditToggleStyle.myDinq] 对齐 Web `SegmentedControl` 移动端样式。
class PreviewEditToggle extends StatelessWidget {
  const PreviewEditToggle({
    super.key,
    required this.isPreviewMode,
    this.onPreviewModeChanged,
    this.style = PreviewEditToggleStyle.profile,
  });

  final bool isPreviewMode;
  final ValueChanged<bool>? onPreviewModeChanged;
  final PreviewEditToggleStyle style;

  static const _activeText = Color(0xFF2C2B2A);
  static const _inactiveText = Color(0xFF9E9B93);
  static const _myDinqHighlight = Color(0xFFF5F4F0);

  @override
  Widget build(BuildContext context) {
    if (style == PreviewEditToggleStyle.myDinq) {
      return _buildMyDinqStyle();
    }
    return _buildProfileStyle();
  }

  Widget _buildMyDinqStyle() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        const gap = 6.0;
        final segmentWidth = (w - gap) / 2;
        return SizedBox(
          height: 32,
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                left: isPreviewMode ? 0.0 : segmentWidth + gap,
                top: 0.0,
                bottom: 0.0,
                width: segmentWidth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _myDinqHighlight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(child: _myDinqSegment(true)),
                  const SizedBox(width: gap),
                  Expanded(child: _myDinqSegment(false)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _myDinqSegment(bool isPage) {
    final selected = isPage == isPreviewMode;
    return GestureDetector(
      onTap: () => onPreviewModeChanged?.call(isPage),
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Text(
          isPage ? 'Page' : 'Resume',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? _activeText : _inactiveText,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileStyle() {
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
                  Expanded(child: _profileSegment(true)),
                  Expanded(child: _profileSegment(false)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _profileSegment(bool isPage) {
    final selected = isPage == isPreviewMode;
    return GestureDetector(
      onTap: () => onPreviewModeChanged?.call(isPage),
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Text(
          isPage ? 'Page' : 'Resume',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: selected ? const Color(0xFF171717) : const Color(0xFF9CA3AF),
          ),
        ),
      ),
    );
  }
}
