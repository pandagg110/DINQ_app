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
      expect(
        platform.lastPurchaseParam?.productDetails.id,
        'me.dinq.app.pro.monthly',
      );
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

      expect(
        await service.restorePurchases(),
        GooglePlayRestoreResult.failed,
      );
    });

    test('acknowledges a purchase only after server verification', () async {
      await service.init();
      final purchase = _purchase(PurchaseStatus.purchased);

      platform.emit([purchase]);
      await Future<void>.delayed(Duration.zero);

      expect(verifiedPayloads, [
        {
          'purchase_token': 'purchase-token',
          'product_id': 'me.dinq.app.pro.monthly',
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
          _googlePurchase(
            PurchaseStatus.restored,
            productID: 'me.dinq.app.basic.monthly',
          ),
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
  });
}

PurchaseDetails _purchase(PurchaseStatus status) {
  final purchase = PurchaseDetails(
    purchaseID: 'order-1',
    productID: 'me.dinq.app.pro.monthly',
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

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _updates.stream;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<ProductDetailsResponse> queryProductDetails(
    Set<String> identifiers,
  ) async {
    final block = queryBlock;
    if (block != null) return block.future;
    return ProductDetailsResponse(
      productDetails: [
        ProductDetails(
          id: 'me.dinq.app.basic.monthly',
          title: 'DINQ Basic',
          description: 'Monthly subscription',
          price: r'$29',
          rawPrice: 29,
          currencyCode: 'USD',
        ),
        ProductDetails(
          id: 'me.dinq.app.pro.monthly',
          title: 'DINQ Pro',
          description: 'Monthly subscription',
          price: r'$99',
          rawPrice: 99,
          currencyCode: 'USD',
        ),
      ],
      notFoundIDs: identifiers
          .where(
            (id) =>
                id != 'me.dinq.app.basic.monthly' &&
                id != 'me.dinq.app.pro.monthly',
          )
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
