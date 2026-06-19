import 'package:flutter/material.dart';

/// 对齐 Web `OnboardingFooter.tsx`：移动端 fixed 底栏，桌面 static。
class OnboardingFooter extends StatelessWidget {
  const OnboardingFooter({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

/// 移动端 fixed 底栏包裹。
class OnboardingFooterBar extends StatelessWidget {
  const OnboardingFooterBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 768;
    if (!isMobile) return child;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        SizedBox(height: 61 + MediaQuery.paddingOf(context).bottom),
      ],
    );
  }
}

/// 放在 Scaffold 底部 Stack 中，移动端 fixed。
class OnboardingFixedFooter extends StatelessWidget {
  const OnboardingFixedFooter({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 768;
    if (!isMobile) return const SizedBox.shrink();

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          border: const Border(top: BorderSide(color: Color(0xFFEEEDE9))),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 61,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
