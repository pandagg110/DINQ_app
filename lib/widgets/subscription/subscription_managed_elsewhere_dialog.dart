import 'package:flutter/material.dart';

import '../../utils/color_util.dart';

Future<void> showSubscriptionManagedElsewhereDialog(
  BuildContext context, {
  required String? subscriptionChannel,
}) {
  final channel = subscriptionChannel?.trim().toLowerCase();
  final description = switch (channel) {
    'apple' =>
      'This subscription was purchased through the App Store. Please manage it in your Apple subscriptions.',
    'google_play' =>
      'This subscription was purchased through Google Play. Please manage it in your Google Play subscriptions.',
    _ =>
      'This subscription was purchased on another platform. Please visit dinq.me to manage it.',
  };

  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.52),
    builder: (dialogContext) => PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Container(
            key: const Key('subscription-managed-elsewhere-dialog'),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Subscription managed elsewhere',
                  style: TextStyle(
                    color: ColorUtil.textColor,
                    fontFamily: 'Geist',
                    fontSize: 22,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFF575757),
                    fontFamily: 'Geist',
                    fontSize: 15,
                    height: 1.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  key: const Key('subscription-managed-elsewhere-ok'),
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: ColorUtil.mainColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      textStyle: const TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('OK'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
