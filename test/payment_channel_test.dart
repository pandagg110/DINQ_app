import 'package:dinq_app/services/payment_channel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('routes each app distribution to its required payment channel', () {
    expect(
      resolveSubscriptionPaymentChannel(
        isWeb: false,
        platform: TargetPlatform.iOS,
        distributionChannel: 'official_apk',
      ),
      SubscriptionPaymentChannel.apple,
    );
    expect(
      resolveSubscriptionPaymentChannel(
        isWeb: false,
        platform: TargetPlatform.android,
        distributionChannel: 'google_play',
      ),
      SubscriptionPaymentChannel.googlePlay,
    );
    expect(
      resolveSubscriptionPaymentChannel(
        isWeb: false,
        platform: TargetPlatform.android,
        distributionChannel: 'official_apk',
      ),
      SubscriptionPaymentChannel.webCheckout,
    );
    expect(
      resolveSubscriptionPaymentChannel(
        isWeb: true,
        platform: TargetPlatform.android,
        distributionChannel: 'google_play',
      ),
      SubscriptionPaymentChannel.webCheckout,
    );
  });

  test('detects subscriptions managed by another payment channel', () {
    expect(
      isSubscriptionManagedElsewhere(
        isFree: true,
        subscriptionChannel: null,
        paymentChannel: SubscriptionPaymentChannel.apple,
      ),
      isFalse,
    );
    expect(
      isSubscriptionManagedElsewhere(
        isFree: false,
        subscriptionChannel: 'apple',
        paymentChannel: SubscriptionPaymentChannel.apple,
      ),
      isFalse,
    );
    expect(
      isSubscriptionManagedElsewhere(
        isFree: false,
        subscriptionChannel: 'google_play',
        paymentChannel: SubscriptionPaymentChannel.apple,
      ),
      isTrue,
    );
    expect(
      isSubscriptionManagedElsewhere(
        isFree: false,
        subscriptionChannel: 'google_play',
        paymentChannel: SubscriptionPaymentChannel.googlePlay,
      ),
      isFalse,
    );
    expect(
      isSubscriptionManagedElsewhere(
        isFree: false,
        subscriptionChannel: 'apple',
        paymentChannel: SubscriptionPaymentChannel.webCheckout,
      ),
      isTrue,
    );
    expect(
      isSubscriptionManagedElsewhere(
        isFree: false,
        subscriptionChannel: 'stripe',
        paymentChannel: SubscriptionPaymentChannel.webCheckout,
      ),
      isFalse,
    );
    expect(
      isSubscriptionManagedElsewhere(
        isFree: false,
        subscriptionChannel: null,
        paymentChannel: SubscriptionPaymentChannel.webCheckout,
      ),
      isFalse,
    );
  });
}
