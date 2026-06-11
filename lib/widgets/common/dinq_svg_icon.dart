import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 单色 SVG 图标，按 `color` 用 srcIn 着色。
/// 1:1 还原设计稿中的 `_SvgIcon`，供移动端各页面复用。
class DinqSvgIcon extends StatelessWidget {
  const DinqSvgIcon({
    required this.assetName,
    required this.size,
    required this.color,
    super.key,
  });

  final String assetName;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetName,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
