import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

/// 启动页 - 在 UserStore 初始化完成前显示
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            SvgPicture.asset('assets/logo/dinq-black.svg', width: 60, height: 60),
            const SizedBox(height: 24),
            // Loading 指示器
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF303030)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
