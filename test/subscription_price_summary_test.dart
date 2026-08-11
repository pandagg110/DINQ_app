import 'package:dinq_app/pages/marketing/pricing_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('localized yearly prices use three rows without overflowing', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              key: Key('price-width'),
              width: 280,
              child: SubscriptionPriceSummary(
                displayedPrice: r'US$41.67',
                displayedPeriod: '/month',
                strikethroughPrice: r'US$49.00',
                yearlyTotalLabel: r'US$499.99 /year',
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);

    final originalPrice = tester.getRect(find.text(r'US$49.00'));
    final mainPrice = tester.getRect(find.text(r'US$41.67'));
    final period = tester.getRect(find.text('/month'));
    final yearlyTotal = tester.getRect(find.text(r'US$499.99 /year'));
    final availableWidth = tester.getRect(find.byKey(const Key('price-width')));

    expect(originalPrice.bottom, lessThanOrEqualTo(mainPrice.top));
    expect(yearlyTotal.top, greaterThanOrEqualTo(mainPrice.bottom));
    expect(period.right, lessThanOrEqualTo(availableWidth.right));
  });
}
