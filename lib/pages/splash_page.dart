import 'package:flutter/material.dart';

import '../widgets/common/lottie_view.dart';

/// 启动页 - 在 UserStore 初始化完成前显示
class SplashPage extends StatefulWidget {
  const SplashPage({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) widget.onComplete();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SizedBox(
          height: 50,
          child: const LottieView(asset: 'animations/splash_logo.json'),
        ),
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
