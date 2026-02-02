import 'package:dinq_app/utils/color_util.dart';
import 'package:dinq_app/widgets/common/base_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class VerificationSuccessPage extends StatelessWidget {
  const VerificationSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const Spacer(flex: 1),
              // Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDFEBC),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: AssetImageView("reset_send_success_icon", width: 32, height: 32),
                ),
              ),
              const SizedBox(height: 16),
              // Title
              Text(
                'Verification has been submitted!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: ColorUtil.textColor,
                  fontFamily: 'Geist',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // Description
              Text(
                'Your authentication will be reviewed in 1-2 business days. You can still browse your dinq card normally during this time.',
                style: TextStyle(
                  fontSize: 14,
                  color: ColorUtil.sub1TextColor,
                  fontFamily: 'Geist',
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              // My DINQ Button
              NormalButton(
                onTap: () => context.go('/'),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: ColorUtil.textColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      'My DINQ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontFamily: 'Geist',
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
