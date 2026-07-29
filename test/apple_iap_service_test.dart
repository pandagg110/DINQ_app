import 'dart:async';

import 'package:dinq_app/services/apple_iap_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';

void main() {
  group('AppleIapService product mapping', () {
    test('maps only supported DINQ plans to App Store product IDs', () {
      expect(
        AppleIapService.productIdForPlan('pro_monthly'),
        'me.dinq.app.pro.monthly',
      );
      expect(AppleIapService.isSupportedPlan('basic_yearly'), isTrue);
      expect(AppleIapService.isSupportedPlan('pro_yearly'), isFalse);
      expect(AppleIapService.isSupportedPlan('plus_monthly'), isFalse);
    });

    test('returns the localized App Store price for a plan', () {
      final products = [
        ProductDetails(
          id: 'me.dinq.app.pro.monthly',
          title: 'DINQ Pro',
          description: 'Monthly subscription',
          price: '¥988',
          rawPrice: 988,
          currencyCode: 'CNY',
        ),
      ];

      expect(
        AppleIapService.localizedPriceForPlan('pro_monthly', products),
        '¥988',
      );
      expect(
        AppleIapService.localizedPriceForPlan('basic_yearly', products),
        isNull,
      );
    });
  });

  group('AppleIapService app account token', () {
    test('accepts a UUID user ID for StoreKit appAccountToken', () {
      expect(
        AppleIapService.appAccountTokenForUser(
          '4a476859-2929-43ef-9a38-2e80eb7e7bb0',
        ),
        '4a476859-2929-43ef-9a38-2e80eb7e7bb0',
      );
    });

    test('rejects empty and non-UUID user IDs', () {
      expect(AppleIapService.appAccountTokenForUser(''), isNull);
      expect(AppleIapService.appAccountTokenForUser('not-a-uuid'), isNull);
    });
  });

  group('AppleIapService transaction lifecycle', () {
    late _FakeIapPlatform platform;
    late List<Map<String, dynamic>> verifiedPayloads;
    late AppleIapService service;

    setUp(() {
      platform = _FakeIapPlatform();
      verifiedPayloads = [];
      service = AppleIapService.forTesting(
        platform: platform,
        transactionVerifier: (payload) async {
          verifiedPayloads.add(payload);
          return {'success': true};
        },
      );
      service.setUserIdProvider(() => '4a476859-2929-43ef-9a38-2e80eb7e7bb0');
    });

    tearDown(() async {
      service.dispose();
      await platform.close();
    });

    test('starts a purchase with the DINQ user UUID', () async {
      await service.init();

      expect(service.supportsPlan('pro_monthly'), isTrue);
      expect(await service.buy('pro_monthly'), isTrue);
      expect(
        platform.lastPurchaseParam?.applicationUserName,
        '4a476859-2929-43ef-9a38-2e80eb7e7bb0',
      );
      expect(
        platform.lastPurchaseParam?.productDetails.id,
        'me.dinq.app.pro.monthly',
      );
      expect(service.priceForPlan('pro_monthly'), '¥988');
      expect(await service.buy('basic_monthly'), isFalse);
    });

    test('shares product loading across concurrent initialization', () async {
      platform.queryBlock = Completer<void>();

      final first = service.init();
      final second = service.init();
      await _flushEvents();
      expect(platform.queryCount, 1);

      platform.queryBlock!.complete();
      await Future.wait([first, second]);
      expect(service.priceForPlan('pro_monthly'), '¥988');
      expect(platform.queryCount, 1);
    });

    test('rejects purchase and restore without a valid DINQ user', () async {
      service.setUserIdProvider(() => null);

      expect(await service.buy('pro_monthly'), isFalse);
      expect(await service.restorePurchases(), AppleRestoreResult.unavailable);
      await service.retryPendingTransactions();
    });

    test('finishes a transaction only after server verification', () async {
      var refreshCount = 0;
      bool? purchaseSucceeded;
      service.onSubscriptionChanged = () async => refreshCount++;
      service.onPurchaseFinished = (success, _) => purchaseSucceeded = success;
      await service.init();

      platform.emit(_purchase(PurchaseStatus.purchased));
      await _flushEvents();

      expect(verifiedPayloads, [
        {
          'jws': 'signed-jws',
          'product_id': 'me.dinq.app.pro.monthly',
          'transaction_id': 'transaction-1',
        },
      ]);
      expect(platform.completedPurchases, hasLength(1));
      expect(refreshCount, 1);
      expect(purchaseSucceeded, isTrue);
    });

    test(
      'keeps a transaction unfinished when server verification fails',
      () async {
        service = AppleIapService.forTesting(
          platform: platform,
          transactionVerifier: (_) async => throw StateError('invalid JWS'),
        );
        service.setUserIdProvider(() => '4a476859-2929-43ef-9a38-2e80eb7e7bb0');
        String? failureMessage;
        service.onPurchaseFinished = (success, message) {
          if (!success) failureMessage = message;
        };
        await service.init();

        platform.emit(_purchase(PurchaseStatus.purchased));
        await _flushEvents();

        expect(platform.completedPurchases, isEmpty);
        expect(failureMessage, contains('retried automatically'));
      },
    );

    test('shows a safe backend reason when activation fails', () async {
      service = AppleIapService.forTesting(
        platform: platform,
        transactionVerifier: (_) async => throw DioException(
          requestOptions: RequestOptions(path: '/payment/apple/verify'),
          error: 'This App Store product is not configured.',
        ),
      );
      service.setUserIdProvider(() => '4a476859-2929-43ef-9a38-2e80eb7e7bb0');
      String? failureMessage;
      service.onPurchaseFinished = (success, message) {
        if (!success) failureMessage = message;
      };
      await service.init();

      platform.emit(_purchase(PurchaseStatus.purchased));
      await _flushEvents();

      expect(
        failureMessage,
        'This App Store product is not configured. Please contact support.',
      );
      expect(platform.completedPurchases, isEmpty);
    });

    test('reports restore failure when the server rejects its JWS', () async {
      service = AppleIapService.forTesting(
        platform: platform,
        transactionVerifier: (_) async => throw StateError('invalid JWS'),
      );
      service.setUserIdProvider(() => '4a476859-2929-43ef-9a38-2e80eb7e7bb0');
      await service.init();

      final result = service.restorePurchases();
      await _flushEvents();
      platform.emit(_purchase(PurchaseStatus.restored));

      expect(await result, AppleRestoreResult.failed);
      expect(platform.completedPurchases, isEmpty);
    });

    test('reports restored and no-purchase outcomes', () async {
      var purchaseCallbackCount = 0;
      service.onPurchaseFinished = (_, _) => purchaseCallbackCount++;
      await service.init();

      final restoredFuture = service.restorePurchases();
      await _flushEvents();
      platform.emit(_purchase(PurchaseStatus.restored));
      expect(await restoredFuture, AppleRestoreResult.restored);
      expect(purchaseCallbackCount, 0);

      expect(await service.restorePurchases(), AppleRestoreResult.noPurchases);
    });

    test('shares an active restore and reports platform failures', () async {
      await service.init();

      final first = service.restorePurchases();
      final second = service.restorePurchases();
      platform.emit(_purchase(PurchaseStatus.restored));
      expect(await first, AppleRestoreResult.restored);
      expect(await second, AppleRestoreResult.restored);

      platform.restoreError = StateError('restore failed');
      expect(await service.restorePurchases(), AppleRestoreResult.failed);
    });

    test('completes canceled and failed StoreKit transactions', () async {
      final failures = <String?>[];
      service.onPurchaseFinished = (success, message) {
        if (!success) failures.add(message);
      };
      await service.init();

      final failed = _purchase(PurchaseStatus.error)
        ..error = IAPError(
          source: 'app_store',
          code: 'declined',
          message: 'Payment declined',
        );
      platform.emit(failed);
      platform.emit(_purchase(PurchaseStatus.canceled));
      await _flushEvents();

      expect(platform.completedPurchases, hasLength(2));
      expect(failures, ['Payment declined', null]);
    });

    test('defers an incoming transaction until login is available', () async {
      await service.init();
      service.setUserIdProvider(() => null);

      platform.emit(_purchase(PurchaseStatus.purchased));
      await _flushEvents();

      expect(verifiedPayloads, isEmpty);
      expect(platform.completedPurchases, isEmpty);
    });
  });
}

PurchaseDetails _purchase(PurchaseStatus status) {
  final purchase = PurchaseDetails(
    purchaseID: 'transaction-1',
    productID: 'me.dinq.app.pro.monthly',
    verificationData: PurchaseVerificationData(
      localVerificationData: '',
      serverVerificationData: 'signed-jws',
      source: 'app_store',
    ),
    transactionDate: '1',
    status: status,
  );
  purchase.pendingCompletePurchase = true;
  return purchase;
}

Future<void> _flushEvents() =>
    Future<void>.delayed(const Duration(milliseconds: 10));

class _FakeIapPlatform extends InAppPurchasePlatform {
  final StreamController<List<PurchaseDetails>> _controller =
      StreamController<List<PurchaseDetails>>.broadcast();

  PurchaseParam? lastPurchaseParam;
  final List<PurchaseDetails> completedPurchases = [];
  Object? restoreError;
  Completer<void>? queryBlock;
  int queryCount = 0;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _controller.stream;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<ProductDetailsResponse> queryProductDetails(
    Set<String> identifiers,
  ) async {
    queryCount++;
    await queryBlock?.future;
    return ProductDetailsResponse(
      productDetails: [
        ProductDetails(
          id: 'me.dinq.app.pro.monthly',
          title: 'DINQ Pro',
          description: 'Monthly subscription',
          price: '¥988',
          rawPrice: 988,
          currencyCode: 'CNY',
        ),
      ],
      notFoundIDs: identifiers
          .where((id) => id != 'me.dinq.app.pro.monthly')
          .toList(),
    );
  }

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    lastPurchaseParam = purchaseParam;
    return true;
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    completedPurchases.add(purchase);
  }

  @override
  Future<void> restorePurchases({String? applicationUserName}) async {
    if (restoreError case final error?) throw error;
  }

  void emit(PurchaseDetails purchase) => _controller.add([purchase]);

  Future<void> close() => _controller.close();
}
