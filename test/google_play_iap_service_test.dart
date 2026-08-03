import 'dart:async';

import 'package:dinq_app/services/google_play_iap_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GooglePlayIapService product matrix', () {
    test('supports the three Google Play plans only', () {
      expect(GooglePlayIapService.isSupportedPlan('basic_monthly'), isTrue);
      expect(GooglePlayIapService.isSupportedPlan('basic_yearly'), isTrue);
      expect(GooglePlayIapService.isSupportedPlan('pro_monthly'), isTrue);
      expect(GooglePlayIapService.isSupportedPlan('pro_yearly'), isFalse);
      expect(
        GooglePlayIapService.productIdForPlan('basic_monthly'),
        'dinq_basic',
      );
      expect(
        GooglePlayIapService.productIdForPlan('basic_yearly'),
        'dinq_basic',
      );
      expect(GooglePlayIapService.productIdForPlan('pro_monthly'), 'dinq_pro');
      expect(
        GooglePlayIapService.basePlanIdForPlan('basic_monthly'),
        'monthly',
      );
      expect(GooglePlayIapService.basePlanIdForPlan('basic_yearly'), 'yearly');
      expect(GooglePlayIapService.basePlanIdForPlan('pro_monthly'), 'monthly');
    });
  });

  group('GooglePlayIapService purchase lifecycle', () {
    late _FakeGooglePlayPlatform platform;
    late List<Map<String, dynamic>> verifiedPayloads;
    late GooglePlayIapService service;

    setUp(() {
      platform = _FakeGooglePlayPlatform();
      verifiedPayloads = [];
      service = GooglePlayIapService.forTesting(
        platform: platform,
        transactionVerifier: (payload) async {
          verifiedPayloads.add(payload);
          return {'plan': 'pro_monthly'};
        },
        initializationTimeout: const Duration(milliseconds: 20),
        platformOperationTimeout: const Duration(milliseconds: 20),
      );
      service.setUserIdProvider(() => '4a476859-2929-43ef-9a38-2e80eb7e7bb0');
    });

    tearDown(() async {
      await service.dispose();
      await platform.dispose();
    });

    test('starts Google Play Billing with the DINQ account id', () async {
      await service.init();

      expect(await service.buy('pro_monthly'), isTrue);
      expect(
        platform.lastPurchaseParam?.applicationUserName,
        '4a476859-2929-43ef-9a38-2e80eb7e7bb0',
      );
      expect(platform.lastPurchaseParam?.productDetails.id, 'dinq_pro');
      expect(
        (platform.lastPurchaseParam as GooglePlayPurchaseParam).offerToken,
        'token-pro-monthly',
      );
      expect(platform.queriedProductIds, {'dinq_basic', 'dinq_pro'});
      expect(service.priceForPlan('basic_monthly'), r'$29');
      expect(service.priceForPlan('basic_yearly'), r'$290');
    });

    test(
      'returns false when Google Play Billing rejects purchase start',
      () async {
        platform.buyError = StateError('billing unavailable');
        await service.init();

        expect(await service.buy('pro_monthly'), isFalse);
      },
    );

    test(
      'stops initialization when Google Play product loading hangs',
      () async {
        platform.queryBlock = Completer<ProductDetailsResponse>();

        await service.init();

        expect(await service.buy('pro_monthly'), isFalse);
      },
    );

    test('stops waiting when Google Play purchase start hangs', () async {
      platform.buyBlock = Completer<bool>();
      await service.init();

      expect(await service.buy('pro_monthly'), isFalse);
    });

    test('stops waiting when Google Play restore hangs', () async {
      platform.restoreBlock = Completer<void>();
      await service.init();

      expect(await service.restorePurchases(), GooglePlayRestoreResult.failed);
    });

    test('acknowledges a purchase only after server verification', () async {
      await service.init();
      final purchase = _purchase(PurchaseStatus.purchased);

      platform.emit([purchase]);
      await Future<void>.delayed(Duration.zero);

      expect(verifiedPayloads, [
        {
          'purchase_token': 'purchase-token',
          'product_id': 'dinq_pro',
          'order_id': 'order-1',
        },
      ]);
      expect(platform.completedPurchases, [purchase]);
    });

    test('leaves a rejected purchase unacknowledged for retry', () async {
      service = GooglePlayIapService.forTesting(
        platform: platform,
        transactionVerifier: (_) async => throw StateError('invalid token'),
      )..setUserIdProvider(() => '4a476859-2929-43ef-9a38-2e80eb7e7bb0');
      await service.init();

      platform.emit([_purchase(PurchaseStatus.purchased)]);
      await Future<void>.delayed(Duration.zero);

      expect(platform.completedPurchases, isEmpty);
    });

    test(
      'does not replace a stale subscription after an empty restore',
      () async {
        await service.init();
        platform.emit([
          _googlePurchase(PurchaseStatus.restored, productID: 'dinq_basic'),
        ]);
        await Future<void>.delayed(Duration.zero);

        expect(
          await service.restorePurchases(),
          GooglePlayRestoreResult.noPurchases,
        );
        expect(await service.buy('pro_monthly'), isTrue);

        final purchaseParam =
            platform.lastPurchaseParam as GooglePlayPurchaseParam;
        expect(purchaseParam.changeSubscriptionParam, isNull);
      },
    );

    test('changes base plans within the same subscription product', () async {
      await service.init();
      platform.emit([
        _googlePurchase(PurchaseStatus.restored, productID: 'dinq_basic'),
      ]);
      await Future<void>.delayed(Duration.zero);

      expect(await service.buy('basic_yearly'), isTrue);

      final purchaseParam =
          platform.lastPurchaseParam as GooglePlayPurchaseParam;
      expect(purchaseParam.productDetails.id, 'dinq_basic');
      expect(purchaseParam.offerToken, 'token-basic-yearly');
      expect(purchaseParam.changeSubscriptionParam, isNotNull);
    });
  });
}

PurchaseDetails _purchase(PurchaseStatus status) {
  final purchase = PurchaseDetails(
    purchaseID: 'order-1',
    productID: 'dinq_pro',
    verificationData: PurchaseVerificationData(
      localVerificationData: '{}',
      serverVerificationData: 'purchase-token',
      source: 'google_play',
    ),
    transactionDate: '1700000000000',
    status: status,
  );
  purchase.pendingCompletePurchase = true;
  return purchase;
}

GooglePlayPurchaseDetails _googlePurchase(
  PurchaseStatus status, {
  required String productID,
}) {
  return GooglePlayPurchaseDetails(
    purchaseID: 'order-1',
    productID: productID,
    verificationData: PurchaseVerificationData(
      localVerificationData: '{}',
      serverVerificationData: 'purchase-token',
      source: 'google_play',
    ),
    transactionDate: '1700000000000',
    billingClientPurchase: PurchaseWrapper(
      orderId: 'order-1',
      packageName: 'me.dinq.app',
      purchaseTime: 1700000000000,
      purchaseToken: 'purchase-token',
      signature: 'signature',
      products: [productID],
      isAutoRenewing: true,
      originalJson: '{}',
      isAcknowledged: false,
      purchaseState: PurchaseStateWrapper.purchased,
    ),
    status: status,
  );
}

class _FakeGooglePlayPlatform extends InAppPurchasePlatform {
  final _updates = StreamController<List<PurchaseDetails>>.broadcast();
  final completedPurchases = <PurchaseDetails>[];
  PurchaseParam? lastPurchaseParam;
  Object? buyError;
  Completer<ProductDetailsResponse>? queryBlock;
  Completer<bool>? buyBlock;
  Completer<void>? restoreBlock;
  Set<String>? queriedProductIds;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _updates.stream;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<ProductDetailsResponse> queryProductDetails(
    Set<String> identifiers,
  ) async {
    queriedProductIds = identifiers;
    final block = queryBlock;
    if (block != null) return block.future;
    final products = <ProductDetails>[
      ...GooglePlayProductDetails.fromProductDetails(
        _subscriptionProduct(
          productId: 'dinq_basic',
          offers: [
            _basePlan(
              id: 'monthly',
              token: 'token-basic-monthly',
              price: r'$29',
              micros: 29000000,
              period: 'P1M',
            ),
            _basePlan(
              id: 'yearly',
              token: 'token-basic-yearly',
              price: r'$290',
              micros: 290000000,
              period: 'P1Y',
            ),
          ],
        ),
      ),
      ...GooglePlayProductDetails.fromProductDetails(
        _subscriptionProduct(
          productId: 'dinq_pro',
          offers: [
            _basePlan(
              id: 'monthly',
              token: 'token-pro-monthly',
              price: r'$99',
              micros: 99000000,
              period: 'P1M',
            ),
          ],
        ),
      ),
    ];
    return ProductDetailsResponse(
      productDetails: products,
      notFoundIDs: identifiers
          .where((id) => id != 'dinq_basic' && id != 'dinq_pro')
          .toList(),
    );
  }

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    final block = buyBlock;
    if (block != null) return block.future;
    final error = buyError;
    if (error != null) throw error;
    lastPurchaseParam = purchaseParam;
    return true;
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    completedPurchases.add(purchase);
  }

  @override
  Future<void> restorePurchases({String? applicationUserName}) async {
    final block = restoreBlock;
    if (block != null) return block.future;
  }

  void emit(List<PurchaseDetails> purchases) => _updates.add(purchases);

  Future<void> dispose() => _updates.close();
}

ProductDetailsWrapper _subscriptionProduct({
  required String productId,
  required List<SubscriptionOfferDetailsWrapper> offers,
}) => ProductDetailsWrapper(
  description: '$productId subscription',
  name: productId,
  productId: productId,
  productType: ProductType.subs,
  subscriptionOfferDetails: offers,
  title: productId,
);

SubscriptionOfferDetailsWrapper _basePlan({
  required String id,
  required String token,
  required String price,
  required int micros,
  required String period,
}) => SubscriptionOfferDetailsWrapper(
  basePlanId: id,
  offerId: null,
  offerTags: const [],
  offerIdToken: token,
  pricingPhases: [
    PricingPhaseWrapper(
      billingCycleCount: 0,
      billingPeriod: period,
      formattedPrice: price,
      priceAmountMicros: micros,
      priceCurrencyCode: 'USD',
      recurrenceMode: RecurrenceMode.infiniteRecurring,
    ),
  ],
);
