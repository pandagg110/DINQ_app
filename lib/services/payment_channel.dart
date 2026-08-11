import 'package:flutter/foundation.dart';

enum SubscriptionPaymentChannel { apple, googlePlay, webCheckout }

SubscriptionPaymentChannel resolveSubscriptionPaymentChannel({
  required bool isWeb,
  required TargetPlatform platform,
  required String distributionChannel,
}) {
  if (isWeb) return SubscriptionPaymentChannel.webCheckout;
  if (platform == TargetPlatform.iOS) {
    return SubscriptionPaymentChannel.apple;
  }
  if (platform == TargetPlatform.android &&
      distributionChannel == 'google_play') {
    return SubscriptionPaymentChannel.googlePlay;
  }
  return SubscriptionPaymentChannel.webCheckout;
}

bool isSubscriptionManagedElsewhere({
  required bool isFree,
  required String? subscriptionChannel,
  required SubscriptionPaymentChannel paymentChannel,
}) {
  if (isFree) return false;

  final channel = subscriptionChannel?.trim().toLowerCase();
  return switch (paymentChannel) {
    SubscriptionPaymentChannel.apple => channel != 'apple',
    SubscriptionPaymentChannel.googlePlay => channel != 'google_play',
    SubscriptionPaymentChannel.webCheckout =>
      channel == 'apple' || channel == 'google_play',
  };
}
