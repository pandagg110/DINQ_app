import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../utils/asset_path.dart';

class LottieView extends StatelessWidget {
  const LottieView({
    super.key,
    required this.asset,
    this.loop = true,
    this.autoplay = true,
    this.height,
    this.width,
  });

  final String asset;
  final bool loop;
  final bool autoplay;
  final double? height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      assetPath(asset),
      repeat: loop,
      animate: autoplay,
      height: height,
      width: width,
      fit: BoxFit.contain,
    );
  }
}

