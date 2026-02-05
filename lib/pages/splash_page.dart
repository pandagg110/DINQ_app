import 'package:flutter/material.dart';

import '../widgets/common/lottie_view.dart';

/// 启动页 - 在 UserStore 初始化完成前显示
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SizedBox(height: 50, child: const LottieView(asset: 'animations/splash_logo.json')),
      ),
      // body: Center(
      //   child: Row(
      //     mainAxisAlignment: MainAxisAlignment.center,
      //     children: [
      //       AssetImageView('logo_white', width: 48, height: 48),
      //       const SizedBox(width: 12),
      //       Text(
      //         'DINQ',
      //         style: TextStyle(
      //           fontSize: 36,
      //           color: ColorUtil.textColor,
      //           fontFamily: 'Geist',
      //           fontWeight: FontWeight.w600,
      //         ),
      //       ),
      //     ],
      //   ),
      // ),
    );
  }
}
