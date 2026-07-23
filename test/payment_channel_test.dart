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
}
