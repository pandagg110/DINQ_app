import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 对齐 Web `CreditsExhaustedModal` + `pricingModal.titles.outOfCredits.email`。
Future<void> showCreditsExhaustedDialog(
  BuildContext context, {
  required String reason,
}) {
  final isEmail = reason == 'email';
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (ctx) => Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 380,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '积分已用完',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2A2826),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isEmail
                    ? '升级套餐以获取更多积分，继续获取候选人邮箱。'
                    : '升级套餐以获取更多积分，继续搜索。',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B6862),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF2A2826),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      ctx.push('/pricing');
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2D2B2A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('升级'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
