import 'package:flutter/material.dart';

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
    builder: (dialogContext) => PopScope(
      canPop: false,
      child: AlertDialog(
        title: const Text('Subscription managed elsewhere'),
        content: Text(description),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    ),
  );
}
