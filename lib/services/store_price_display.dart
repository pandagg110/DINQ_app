import 'package:intl/intl.dart';

class StoreProductPrice {
  const StoreProductPrice({
    required this.localizedPrice,
    required this.rawPrice,
    required this.currencyCode,
  });

  final String localizedPrice;
  final double rawPrice;
  final String currencyCode;
}

class StorePriceDisplay {
  const StorePriceDisplay({
    required this.primaryPrice,
    required this.primaryPeriod,
    this.strikethroughPrice,
    this.yearlyTotal,
    this.yearlySavings,
  });

  final String primaryPrice;
  final String primaryPeriod;
  final String? strikethroughPrice;
  final String? yearlyTotal;
  final String? yearlySavings;
}

StorePriceDisplay buildStorePriceDisplay({
  required String billingPeriod,
  required StoreProductPrice selectedPrice,
  required StoreProductPrice? monthlyPrice,
  required String localeName,
}) {
  if (billingPeriod != 'yearly') {
    return StorePriceDisplay(
      primaryPrice: selectedPrice.localizedPrice,
      primaryPeriod: '/month',
    );
  }

  final format = _currencyFormatter(
    localeName: localeName,
    currencyCode: selectedPrice.currencyCode,
    localizedPrice: selectedPrice.localizedPrice,
  );
  final sameCurrency = monthlyPrice?.currencyCode == selectedPrice.currencyCode;
  final savings = sameCurrency
      ? monthlyPrice!.rawPrice * 12 - selectedPrice.rawPrice
      : 0.0;

  return StorePriceDisplay(
    primaryPrice: selectedPrice.localizedPrice,
    primaryPeriod: '/year',
    strikethroughPrice: sameCurrency ? monthlyPrice!.localizedPrice : null,
    yearlyTotal: '${format.format(selectedPrice.rawPrice / 12)} /month',
    yearlySavings: savings > 0 ? '${format.format(savings)}/year' : null,
  );
}

NumberFormat _currencyFormatter({
  required String localeName,
  required String currencyCode,
  required String localizedPrice,
}) {
  final symbol = localizedPrice.replaceAll(
    RegExp(r'[\d\s.,\u00a0\u202f\-]'),
    '',
  );
  return NumberFormat.currency(
    locale: localeName,
    name: currencyCode,
    symbol: symbol.isEmpty ? currencyCode : symbol,
  );
}
