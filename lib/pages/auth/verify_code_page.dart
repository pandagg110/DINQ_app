import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:go_router/go_router.dart';

import '../../utils/color_util.dart';
import '../../widgets/common/default_app_bar.dart';

class VerifyCodePage extends StatefulWidget {
  const VerifyCodePage({super.key});

  @override
  State<VerifyCodePage> createState() => _VerifyCodePageState();
}

class _VerifyCodePageState extends State<VerifyCodePage> {
  String _email = "";

  @override
  void initState() {
    // 获取参数
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    _email = extra?['email'];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardDismissOnTap(
      child: Scaffold(
        appBar: DefaultAppBar(context),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 18),
              Text(
                'Check your email for a code',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: ColorUtil.textColor,
                  fontFamily: 'Editor Note',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "We've emailed a code to ",
                      style: TextStyle(fontSize: 14, color: ColorUtil.sub1TextColor),
                    ),
                    TextSpan(
                      text: _email,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ColorUtil.textColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Not in your inbox? Check promotions or spam, and move it to your main inbox to receive future notifications.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'Tomato Grotesk',
                  height: 1.6,
                  color: ColorUtil.sub1TextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
