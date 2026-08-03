import 'dart:async';

import 'package:dinq_app/services/apple_iap_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';

void main() {
  group('AppleIapService product mapping', () {
    test('maps only supported DINQ plans to App Store product IDs', () {
      expect(
        AppleIapService.productIdForPlan('pro_monthly'),
        'me.dinq.app.pro.monthly',
      );
      expect(
        AppleIapService.productIdForPlan('basic_monthly'),
        'me.dinq.app.basic.monthly.v2',
      );
      expect(AppleIapService.isSupportedPlan('basic_yearly'), isTrue);
      expect(AppleIapService.isSupportedPlan('pro_yearly'), isFalse);
      expect(AppleIapService.isSupportedPlan('plus_monthly'), isFalse);
    });

    test('keeps the legacy Basic monthly product available for refunds', () {
      expect(AppleIapService.refundProductIdsForPlan('basic_monthly'), [
        'me.dinq.app.basic.monthly.v2',
        'me.dinq.app.basic.monthly',
      ]);
      expect(AppleIapService.refundProductIdsForPlan('pro_monthly'), [
        'me.dinq.app.pro.monthly',
      ]);
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

    testWidgets('refund falls back to the legacy Basic monthly product', (
      tester,
    ) async {
      const channel = MethodChannel('me.dinq.app/storekit');
      final requestedProductIds = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            final arguments = Map<String, dynamic>.from(call.arguments as Map);
            final productId = arguments['productId'] as String;
            requestedProductIds.add(productId);
            if (productId == 'me.dinq.app.basic.monthly.v2') {
              throw PlatformException(code: 'no_transaction');
            }
            return 'success';
          });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      });

      expect(await service.beginRefundRequest('basic_monthly'), 'success');
      expect(requestedProductIds, [
        'me.dinq.app.basic.monthly.v2',
        'me.dinq.app.basic.monthly',
      ]);
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
      expect(await service.buy('basic_monthly'), isTrue);
      expect(
        platform.lastPurchaseParam?.productDetails.id,
        'me.dinq.app.basic.monthly.v2',
      );
      expect(await service.buy('basic_yearly'), isFalse);
      expect(
        service.purchaseStartErrorMessage,
        'This subscription is not available in the App Store for this build. '
        'Please contact support.',
      );
    });

    test('returns false when StoreKit rejects the purchase request', () async {
      platform.purchaseError = StateError('store unavailable');
      await service.init();

      expect(await service.buy('pro_monthly'), isFalse);
      expect(
        service.purchaseStartErrorMessage,
        'The App Store could not start this purchase. '
        'Please check your App Store account and try again.',
      );
    });

    test('reports when the App Store is unavailable', () async {
      platform.available = false;

      expect(await service.buy('pro_monthly'), isFalse);
      expect(
        service.purchaseStartErrorMessage,
        'The App Store is unavailable. Please try again later.',
      );
    });

    test('treats product query errors as App Store unavailability', () async {
      platform.queryError = IAPError(
        source: 'app_store',
        code: 'storekit_query_failed',
        message: 'StoreKit query failed',
      );

      expect(await service.buy('pro_monthly'), isFalse);
      expect(
        service.purchaseStartErrorMessage,
        'The App Store is unavailable. Please try again later.',
      );
      expect(
        service.purchaseStartErrorMessage,
        isNot(contains('not available in the App Store for this build')),
      );
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

    test('stops waiting when StoreKit product loading hangs', () async {
      platform.queryBlock = Completer<void>();
      service = AppleIapService.forTesting(
        platform: platform,
        transactionVerifier: (_) async => {'success': true},
        initializationTimeout: const Duration(milliseconds: 20),
      );
      service.setUserIdProvider(() => '4a476859-2929-43ef-9a38-2e80eb7e7bb0');

      await service.init().timeout(const Duration(milliseconds: 200));

      expect(platform.queryCount, 1);
      expect(await service.buy('pro_monthly'), isFalse);
    });

    test(
      'clears the checkout path when a missing product reload hangs',
      () async {
        service = AppleIapService.forTesting(
          platform: platform,
          transactionVerifier: (_) async => {'success': true},
          initializationTimeout: const Duration(milliseconds: 20),
        );
        service.setUserIdProvider(() => '4a476859-2929-43ef-9a38-2e80eb7e7bb0');
        await service.init();
        platform.queryBlock = Completer<void>();

        expect(
          await service
              .buy('basic_yearly')
              .timeout(const Duration(milliseconds: 200)),
          isFalse,
        );
        expect(
          service.purchaseStartErrorMessage,
          'The App Store is unavailable. Please try again later.',
        );
      },
    );

    test('rejects purchase and restore without a valid DINQ user', () async {
      service.setUserIdProvider(() => null);

      expect(await service.buy('pro_monthly'), isFalse);
      expect(
        service.purchaseStartErrorMessage,
        'Please sign in again before purchasing.',
      );
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
      'does not verify or finish a StoreKit 2 transaction owned by another user',
      () async {
        String? failureMessage;
        service.onPurchaseFinished = (success, message) {
          if (!success) failureMessage = message;
        };
        await service.init();

        platform.emit(
          _sk2Purchase(
            PurchaseStatus.purchased,
            appAccountToken: '74475f70-0477-442f-8b8d-2d58943935f0',
          ),
        );
        await _flushEvents();

        expect(verifiedPayloads, isEmpty);
        expect(platform.completedPurchases, isEmpty);
        expect(
          failureMessage,
          'This purchase belongs to another DINQ account. '
          'Sign in with the account used for this purchase.',
        );
      },
    );

    test(
      'does not verify or finish a StoreKit 2 transaction without an account token',
      () async {
        String? failureMessage;
        service.onPurchaseFinished = (success, message) {
          if (!success) failureMessage = message;
        };
        await service.init();

        platform.emit(
          _sk2Purchase(PurchaseStatus.purchased, appAccountToken: null),
        );
        await _flushEvents();

        expect(verifiedPayloads, isEmpty);
        expect(platform.completedPurchases, isEmpty);
        expect(
          failureMessage,
          'This purchase is not linked to a DINQ account. '
          'Please contact support.',
        );
      },
    );

    test(
      'verifies a StoreKit 2 transaction owned by the current user',
      () async {
        await service.init();

        platform.emit(
          _sk2Purchase(
            PurchaseStatus.purchased,
            appAccountToken: '4A476859-2929-43EF-9A38-2E80EB7E7BB0',
          ),
        );
        await _flushEvents();

        expect(verifiedPayloads, hasLength(1));
        expect(platform.completedPurchases, hasLength(1));
      },
    );

    test(
      'silently rejects a restored transaction owned by another user',
      () async {
        var purchaseCallbackCount = 0;
        service.onPurchaseFinished = (_, _) => purchaseCallbackCount++;
        await service.init();

        final restoredFuture = service.restorePurchases();
        await _flushEvents();
        platform.emit(
          _sk2Purchase(
            PurchaseStatus.restored,
            appAccountToken: '74475f70-0477-442f-8b8d-2d58943935f0',
          ),
        );

        expect(await restoredFuture, AppleRestoreResult.noPurchases);
        expect(verifiedPayloads, isEmpty);
        expect(platform.completedPurchases, isEmpty);
        expect(purchaseCallbackCount, 0);
      },
    );

    test(
      'restores the current user when a foreign transaction appears first',
      () async {
        await service.init();

        final restoredFuture = service.restorePurchases();
        await _flushEvents();
        platform.emitMany([
          _sk2Purchase(
            PurchaseStatus.restored,
            appAccountToken: '74475f70-0477-442f-8b8d-2d58943935f0',
          ),
          _sk2Purchase(
            PurchaseStatus.restored,
            appAccountToken: '4a476859-2929-43ef-9a38-2e80eb7e7bb0',
          ),
        ]);

        expect(await restoredFuture, AppleRestoreResult.restored);
        await _flushEvents();
        expect(verifiedPayloads, hasLength(1));
        expect(platform.completedPurchases, isEmpty);
      },
    );

    test(
      'restores when a later StoreKit event succeeds after an earlier failure',
      () async {
        var verificationCount = 0;
        service = AppleIapService.forTesting(
          platform: platform,
          transactionVerifier: (payload) async {
            verificationCount++;
            if (verificationCount == 1) {
              throw StateError('temporary verification failure');
            }
            verifiedPayloads.add(payload);
            return {'success': true};
          },
          restoreTimeout: const Duration(milliseconds: 100),
        );
        service.setUserIdProvider(() => '4a476859-2929-43ef-9a38-2e80eb7e7bb0');
        await service.init();

        final restoredFuture = service.restorePurchases();
        await _flushEvents();
        platform.emit(
          _sk2Purchase(
            PurchaseStatus.restored,
            appAccountToken: '4a476859-2929-43ef-9a38-2e80eb7e7bb0',
          ),
        );
        await _flushEvents();
        platform.emit(
          _sk2Purchase(
            PurchaseStatus.restored,
            appAccountToken: '4a476859-2929-43ef-9a38-2e80eb7e7bb0',
          ),
        );

        expect(await restoredFuture, AppleRestoreResult.restored);
        expect(verificationCount, 2);
        expect(verifiedPayloads, hasLength(1));
      },
    );

    test(
      'restores when StoreKit reports a partial failure before a valid event',
      () async {
        service = AppleIapService.forTesting(
          platform: platform,
          transactionVerifier: (payload) async {
            verifiedPayloads.add(payload);
            return {'success': true};
          },
          restoreTimeout: const Duration(milliseconds: 100),
        );
        service.setUserIdProvider(() => '4a476859-2929-43ef-9a38-2e80eb7e7bb0');
        platform.restoreError = StateError('partial StoreKit restore failure');
        await service.init();

        final restoredFuture = service.restorePurchases();
        await _flushEvents();
        platform.emit(
          _sk2Purchase(
            PurchaseStatus.restored,
            appAccountToken: '4a476859-2929-43ef-9a38-2e80eb7e7bb0',
          ),
        );

        expect(await restoredFuture, AppleRestoreResult.restored);
        expect(verifiedPayloads, hasLength(1));
      },
    );

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

PurchaseDetails _sk2Purchase(
  PurchaseStatus status, {
  required String? appAccountToken,
}) => SK2PurchaseDetails(
  purchaseID: 'transaction-1',
  productID: 'me.dinq.app.pro.monthly',
  verificationData: PurchaseVerificationData(
    localVerificationData: '',
    serverVerificationData: 'signed-jws',
    source: 'app_store',
  ),
  transactionDate: '1',
  status: status,
  appAccountToken: appAccountToken,
);

Future<void> _flushEvents() =>
    Future<void>.delayed(const Duration(milliseconds: 10));

class _FakeIapPlatform extends InAppPurchasePlatform {
  final StreamController<List<PurchaseDetails>> _controller =
      StreamController<List<PurchaseDetails>>.broadcast();

  PurchaseParam? lastPurchaseParam;
  final List<PurchaseDetails> completedPurchases = [];
  Object? purchaseError;
  Object? restoreError;
  IAPError? queryError;
  Completer<void>? queryBlock;
  int queryCount = 0;
  bool available = true;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _controller.stream;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<ProductDetailsResponse> queryProductDetails(
    Set<String> identifiers,
  ) async {
    queryCount++;
    await queryBlock?.future;
    if (queryError case final error?) {
      return ProductDetailsResponse(
        productDetails: const [],
        notFoundIDs: identifiers.toList(),
        error: error,
      );
    }
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
        ProductDetails(
          id: 'me.dinq.app.basic.monthly.v2',
          title: 'DINQ Basic',
          description: 'Monthly subscription',
          price: 'US\$49',
          rawPrice: 49,
          currencyCode: 'USD',
        ),
      ],
      notFoundIDs: identifiers
          .where(
            (id) =>
                id != 'me.dinq.app.pro.monthly' &&
                id != 'me.dinq.app.basic.monthly.v2',
          )
          .toList(),
    );
  }

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    lastPurchaseParam = purchaseParam;
    if (purchaseError case final error?) throw error;
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

  void emitMany(List<PurchaseDetails> purchases) => _controller.add(purchases);

  Future<void> close() => _controller.close();
}
