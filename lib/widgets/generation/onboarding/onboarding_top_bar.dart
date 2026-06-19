import 'package:flutter/material.dart';

import '../../../widgets/common/base_page.dart';
import 'onboarding_step_header.dart';

/// 移动端 onboarding 顶栏：圆形返回 + 进度条（无 Step 文案）。
class OnboardingTopBar extends StatelessWidget {
  const OnboardingTopBar({
    super.key,
    required this.step,
    required this.onBack,
    this.totalSteps = 4,
  });

  final int step;
  final VoidCallback onBack;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        children: [
          OnboardingCircleBackButton(onTap: onBack),
          const SizedBox(width: 12),
          Expanded(
            child: OnboardingStepHeader(step: step, totalSteps: totalSteps),
          ),
        ],
      ),
    );
  }
}

class OnboardingCircleBackButton extends StatelessWidget {
  const OnboardingCircleBackButton({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Center(
            child: AssetImageView('nav_back', width: 20, height: 20),
          ),
        ),
      ),
    );
  }
}
