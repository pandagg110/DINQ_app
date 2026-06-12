import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Network 加载动画：直接渲染 SVG，仅保留旋转动画
class NetworkLoadingAnimation extends StatefulWidget {
  const NetworkLoadingAnimation({
    super.key,
    this.size = 400,
  });

  final double size;

  @override
  State<NetworkLoadingAnimation> createState() => _NetworkLoadingAnimationState();
}

class _NetworkLoadingAnimationState extends State<NetworkLoadingAnimation>
    with SingleTickerProviderStateMixin {
  static const _rotateDuration = Duration(seconds: 30);

  late AnimationController _rotateController;

  @override
  void initState() {
    super.initState();
    _rotateController = AnimationController(
      vsync: this,
      duration: _rotateDuration,
    )..repeat();
  }

  @override
  void dispose() {
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _rotateController,
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotateController.value * 2 * math.pi,
            child: SvgPicture.asset(
              'assets/images/network_loading.svg',
              width: widget.size,
              height: widget.size,
              fit: BoxFit.contain,
            ),
          );
        },
      ),
    );
  }
}
