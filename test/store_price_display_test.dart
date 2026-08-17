import 'package:dinq_app/services/store_price_display.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Apple subscription price presentation', () {
    test('keeps the exact localized StoreKit price for monthly plans', () {
      final display = buildStorePriceDisplay(
        billingPeriod: 'monthly',
        selectedPrice: const StoreProductPrice(
          localizedPrice: r'S$39.98',
          rawPrice: 39.98,
          currencyCode: 'SGD',
        ),
        monthlyPrice: null,
        localeName: 'en_SG',
      );

      expect(display.primaryPrice, r'S$39.98');
      expect(display.primaryPeriod, '/month');
      expect(display.yearlyTotal, isNull);
      expect(display.yearlySavings, isNull);
    });

    test('shows annual StoreKit pricing in the same structure as web', () {
      final display = buildStorePriceDisplay(
        billingPeriod: 'yearly',
        selectedPrice: const StoreProductPrice(
          localizedPrice: r'$290.00',
          rawPrice: 290,
          currencyCode: 'USD',
        ),
        monthlyPrice: const StoreProductPrice(
          localizedPrice: r'$29.00',
          rawPrice: 29,
          currencyCode: 'USD',
        ),
        localeName: 'en_US',
      );

      expect(display.primaryPrice, r'$290.00');
      expect(display.primaryPeriod, '/year');
      expect(display.yearlyTotal, r'$24.17 /month');
      expect(display.yearlySavings, r'$58.00/year');
    });

    test('does not calculate savings across different currencies', () {
      final display = buildStorePriceDisplay(
        billingPeriod: 'yearly',
        selectedPrice: const StoreProductPrice(
          localizedPrice: r'S$390.00',
          rawPrice: 390,
          currencyCode: 'SGD',
        ),
        monthlyPrice: const StoreProductPrice(
          localizedPrice: r'$29.00',
          rawPrice: 29,
          currencyCode: 'USD',
        ),
        localeName: 'en_SG',
      );

      expect(display.primaryPrice, r'S$390.00');
      expect(display.primaryPeriod, '/year');
      expect(display.yearlyTotal, r'S$32.50 /month');
      expect(display.yearlySavings, isNull);
    });
  });
}
