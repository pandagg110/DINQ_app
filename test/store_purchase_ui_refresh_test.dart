import 'package:dinq_app/pages/marketing/pricing_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'store purchase refreshes subscription before pricing actions',
    () async {
      final calls = <String>[];

      await refreshStorePurchaseUi(
        refreshSubscription: () async => calls.add('subscription'),
        refreshPricing: () async => calls.add('pricing'),
      );

      expect(calls, ['subscription', 'pricing']);
    },
  );
}
