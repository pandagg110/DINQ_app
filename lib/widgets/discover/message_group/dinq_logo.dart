import 'package:flutter/material.dart';

/// 呼吸动画 Logo（与 TSX BreathingLogo 对应）
class BreathingLogo extends StatelessWidget {
  const BreathingLogo({
    super.key,
    this.size = 24,
    required this.animation,
  });

  final double size;
  final AnimationController animation;

  @override
  Widget build(BuildContext context) {
    final scale = Tween<double>(begin: 0.9, end: 1.15).animate(
      CurvedAnimation(parent: animation, curve: Curves.easeInOut),
    );
    return AnimatedBuilder(
      animation: scale,
      builder: (context, child) {
        return Transform.scale(
          scale: scale.value,
          child: child,
        );
      },
      child: Image.asset(
        'assets/logo/dinq-black.png',
        width: size,
        height: size,
        errorBuilder: (_, __, ___) => Icon(Icons.search, size: size),
      ),
    );
  }
}
