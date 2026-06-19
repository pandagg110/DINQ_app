import 'package:flutter/material.dart';

/// 移动端底栏：仅 Continue（对齐 Profile Details / Upload）。
class OnboardingContinueButton extends StatelessWidget {
  const OnboardingContinueButton({
    super.key,
    required this.onPressed,
    this.label = 'Continue',
  });

  final VoidCallback? onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + bottomPad),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                enabled ? const Color(0xFF171717) : const Color(0xFFE5E5E5),
            foregroundColor: enabled
                ? Colors.white
                : const Color(0xFF303030).withValues(alpha: 0.4),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/// 对齐 Web `OnboardingFooter.tsx`：Back + Continue 双按钮底栏。
class OnboardingDualActionFooter extends StatelessWidget {
  const OnboardingDualActionFooter({
    super.key,
    required this.onBack,
    required this.onContinue,
    this.continueLabel = 'Continue →',
    this.continueEnabled = true,
    this.isLoading = false,
  });

  final VoidCallback onBack;
  final VoidCallback? onContinue;
  final String continueLabel;
  final bool continueEnabled;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + bottomPad),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: onBack,
            child: const Text(
              '← Back',
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 14,
                color: Color(0xFF6B6862),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ElevatedButton(
              onPressed: continueEnabled && !isLoading ? onContinue : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: continueEnabled && !isLoading
                    ? const Color(0xFF171717)
                    : const Color(0xFFE5E5E5),
                foregroundColor: continueEnabled && !isLoading
                    ? Colors.white
                    : const Color.fromRGBO(48, 48, 48, 0.4),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      continueLabel,
                      style: const TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

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
