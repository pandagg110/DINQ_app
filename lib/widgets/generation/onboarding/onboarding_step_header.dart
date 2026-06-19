import 'package:flutter/material.dart';

/// 对齐 Web `OnboardingStepHeader.tsx`。
class OnboardingStepHeader extends StatelessWidget {
  const OnboardingStepHeader({
    super.key,
    required this.step,
    this.totalSteps = 4,
    this.showLabel = false,
  });

  final int step;
  final int totalSteps;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: List.generate(totalSteps, (index) {
              return Expanded(
                child: Container(
                  height: 6,
                  margin: EdgeInsets.only(right: index < totalSteps - 1 ? 8 : 0),
                  decoration: BoxDecoration(
                    color: index < step
                        ? const Color(0xFF171717)
                        : const Color(0xFFEEEDE9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              );
            }),
          ),
        ),
        if (showLabel) ...[
          const SizedBox(width: 12),
          Text(
            'Step $step/$totalSteps',
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.8,
              color: Color(0xFF9E9B93),
            ),
          ),
        ],
      ],
    );
  }
}
