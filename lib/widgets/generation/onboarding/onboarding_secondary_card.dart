import 'package:flutter/material.dart';

import 'onboarding_icons.dart';

/// 对齐 Web `SecondaryCard` in `/onboarding/start/page.tsx`。
class OnboardingSecondaryCard extends StatelessWidget {
  const OnboardingSecondaryCard({
    super.key,
    required this.iconAsset,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final String iconAsset;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 640;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        hoverColor: const Color(0xFFFAF9F5),
        splashColor: const Color(0xFFFAF9F5),
        highlightColor: const Color(0xFFFAF9F5),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEEEDE9)),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 24,
              vertical: isMobile ? 16 : 32,
            ),
            child: isMobile ? _mobileLayout() : _desktopLayout(),
          ),
        ),
      ),
    );
  }

  Widget _iconBox() {
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEDE9)),
      ),
      child: OnboardingSvgIcon(iconAsset, size: 20),
    );
  }

  Widget _textColumn({required bool showDescription}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: showDescription ? 16 : 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF171717),
            height: 1.3,
          ),
        ),
        if (showDescription) ...[
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 12,
              color: Color(0xFF9E9B93),
              height: 1.3,
            ),
          ),
        ],
      ],
    );
  }

  Widget _mobileLayout() {
    return Row(
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEEEDE9)),
              ),
              child: OnboardingSvgIcon(iconAsset, size: 20),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: _textColumn(showDescription: false)),
      ],
    );
  }

  Widget _desktopLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _iconBox(),
        const SizedBox(height: 12),
        _textColumn(showDescription: true),
      ],
    );
  }
}
