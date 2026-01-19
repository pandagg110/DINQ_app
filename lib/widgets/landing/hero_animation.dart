import 'package:flutter/material.dart';
import '../common/lottie_view.dart';

class HeroAnimation extends StatelessWidget {
  const HeroAnimation({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: LottieView(
        asset: 'animations/Hero.json',
        height: 500,
      ),
    );
  }
}

