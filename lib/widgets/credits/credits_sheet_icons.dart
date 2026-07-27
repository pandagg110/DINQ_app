import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 对齐 `.example/tanchuang_1` demo 内嵌 Heroicons SVG。
abstract final class CreditsSheetIcons {
  static const _base = 'assets/icons/credits';
  static const close = '$_base/close.svg';
  static const setup = '$_base/setup.svg';
  static const bolt = '$_base/bolt.svg';
  static const userPlus = '$_base/user-plus.svg';
  static const power = '$_base/power.svg';
  static const creditCard = '$_base/credit-card.svg';
  static const chatBubble = '$_base/chat-bubble.svg';
  static const adjustments = '$_base/adjustments.svg';
}

class CreditsSheetSvgIcon extends StatelessWidget {
  const CreditsSheetSvgIcon(
    this.asset, {
    super.key,
    this.size = 20,
    this.color = Colors.black,
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
