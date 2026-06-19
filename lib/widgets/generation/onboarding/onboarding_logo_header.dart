import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

/// 对齐 Web `OnboardingLayout` header + `Logo.tsx` (md)。
class OnboardingLogoHeader extends StatelessWidget {
  const OnboardingLogoHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: InkWell(
          onTap: () => context.go('/'),
          borderRadius: BorderRadius.circular(4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/logo/dinq-black.svg',
                width: 24,
                height: 25,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 8),
              const Text(
                'DINQ',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF171717),
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
