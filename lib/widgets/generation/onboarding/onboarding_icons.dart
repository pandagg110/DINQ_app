import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 对齐 Web `/onboarding/start` lucide / social 图标。
abstract final class OnboardingIcons {
  static const _base = 'assets/icons/generation/onboarding';
  static const linkedin = 'assets/icons/social-icons/LinkedIn.svg';
  static const fileUp = '$_base/file-up.svg';
  static const pencilLine = '$_base/pencil-line.svg';
  static const alertCircle = '$_base/alert-circle.svg';
  static const users = '$_base/users.svg';
  static const chevronRight = '$_base/chevron-right.svg';
  static const userPlus = '$_base/user-plus.svg';
  static const upload = '$_base/upload.svg';
  static const fileText = '$_base/file-text.svg';
}

class OnboardingSvgIcon extends StatelessWidget {
  const OnboardingSvgIcon(
    this.asset, {
    super.key,
    this.size = 20,
    this.color = const Color(0xFF6B6862),
  });

  final String asset;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.asset(
        asset,
        width: size,
        height: size,
        fit: BoxFit.contain,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      ),
    );
  }
}
