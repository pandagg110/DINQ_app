import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';

import 'app_update_service.dart';
import 'payment_service.dart';

enum GooglePlayRestoreResult { restored, noPurchases, unavailable, failed }

typedef GooglePlayTransactionVerifier =
    Future<Map<String, dynamic>> Function(Map<String, dynamic> data);

class GooglePlayIapService {
  GooglePlayIapService._({
    InAppPurchasePlatform? platform,
    GooglePlayTransactionVerifier? transactionVerifier,
    bool? isGooglePlayOverride,
    Duration restoreTimeout = const Duration(seconds: 5),
    Duration initializationTimeout = const Duration(seconds: 10),
    Duration platformOperationTimeout = const Duration(seconds: 15),
  }) : _platformOverride = platform,
       _transactionVerifier =
           transactionVerifier ?? PaymentService().verifyGooglePlayPurchase,
       _isGooglePlayOverride = isGooglePlayOverride,
       _restoreTimeout = restoreTimeout,
       _initializationTimeout = initializationTimeout,
       _platformOperationTimeout = platformOperationTimeout;

  @visibleForTesting
  factory GooglePlayIapService.forTesting({
    required InAppPurchasePlatform platform,
    required GooglePlayTransactionVerifier transactionVerifier,
    Duration restoreTimeout = const Duration(milliseconds: 20),
    Duration initializationTimeout = const Duration(milliseconds: 200),
    Duration platformOperationTimeout = const Duration(milliseconds: 200),
  }) => GooglePlayIapService._(
    platform: platform,
    transactionVerifier: transactionVerifier,
    isGooglePlayOverride: true,
    restoreTimeout: restoreTimeout,
    initializationTimeout: initializationTimeout,
    platformOperationTimeout: platformOperationTimeout,
  );

  static final GooglePlayIapService instance = GooglePlayIapService._();
  static const _productIdPrefix = 'me.dinq.app.';
  static const Set<String> _productIds = {
    'me.dinq.app.basic.monthly',
    'me.dinq.app.basic.yearly',
    'me.dinq.app.pro.monthly',
  };
  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );

  final InAppPurchasePlatform? _platformOverride;
  final GooglePlayTransactionVerifier _transactionVerifier;
  final bool? _isGooglePlayOverride;
  final Duration _restoreTimeout;
  final Duration _initializationTimeout;
  final Duration _platformOperationTimeout;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  Map<String, ProductDetails> _products = {};
  GooglePlayPurchaseDetails? _activePurchase;
  bool _ready = false;
  Future<void>? _initialization;
  String? Function()? _userIdProvider;
  Completer<GooglePlayRestoreResult>? _restoreCompleter;
  Timer? _restoreTimer;

  Future<void> Function()? onSubscriptionChanged;
  void Function(bool success, String? message)? onPurchaseFinished;

  bool get _isGooglePlay =>
      _isGooglePlayOverride ??
      (!kIsWeb &&
          defaultTargetPlatform == TargetPlatform.android &&
          distributionChannel == 'google_play');

  InAppPurchasePlatform get _platform =>
      _platformOverride ?? InAppPurchasePlatform.instance;

  void setUserIdProvider(String? Function() provider) {
    _userIdProvider = provider;
  }

  Future<void> init() {
    if (!_isGooglePlay || _ready) return Future<void>.value();
    final activeInitialization = _initialization;
    if (activeInitialization != null) return activeInitialization;

    final initialization = _initialize();
    _initialization = initialization;
    return initialization.whenComplete(() {
      if (identical(_initialization, initialization)) {
        _initialization = null;
      }
    });
  }

  Future<void> _initialize() async {
    try {
      if (_platformOverride == null) {
        InAppPurchaseAndroidPlatform.registerPlatform();
      }
      if (!await _platform.isAvailable().timeout(_initializationTimeout)) {
        return;
      }
      _purchaseSub = _platform.purchaseStream.listen(
        _onPurchaseUpdates,
        onError: (Object error) {
          debugPrint('Google Play Billing stream error: $error');
          _completeRestore(GooglePlayRestoreResult.failed);
        },
      );
      await _loadProducts();
      _ready = true;
    } catch (error) {
      debugPrint('Google Play Billing init failed: $error');
      await _purchaseSub?.cancel();
      _purchaseSub = null;
    }
  }

  Future<void> _loadProducts() async {
    final response = await _platform
        .queryProductDetails(_productIds)
        .timeout(_initializationTimeout);
    _products = {
      for (final product in response.productDetails) product.id: product,
    };
    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('Google Play products not found: ${response.notFoundIDs}');
    }
  }

  static String productIdForPlan(String plan) =>
      '$_productIdPrefix${plan.replaceAll('_', '.')}';

  static bool isSupportedPlan(String plan) =>
      _productIds.contains(productIdForPlan(plan));

  static String? accountIdForUser(String? userId) {
    if (userId == null || !_uuidPattern.hasMatch(userId)) return null;
    return userId;
  }

  String? get _accountId => accountIdForUser(_userIdProvider?.call());

  bool supportsPlan(String plan) => isSupportedPlan(plan);

  String? priceForPlan(String plan) {
    final product = _products[productIdForPlan(plan)];
    return product?.price;
  }

  Future<bool> buy(String plan) async {
    final accountId = _accountId;
    if (accountId == null || !supportsPlan(plan)) return false;
    if (!_ready) await init();
    if (!_ready) return false;

    var product = _products[productIdForPlan(plan)];
    if (product == null) {
      try {
        await _loadProducts();
      } catch (error) {
        debugPrint('Google Play product reload failed: ${error.runtimeType}');
        return false;
      }
      product = _products[productIdForPlan(plan)];
    }
    if (product == null) return false;

    final activePurchase = _activePurchase;
    try {
      return await _platform.buyNonConsumable(
        purchaseParam: GooglePlayPurchaseParam(
          productDetails: product,
          applicationUserName: accountId,
          changeSubscriptionParam:
              activePurchase == null || activePurchase.productID == product.id
              ? null
              : ChangeSubscriptionParam(
                  oldPurchaseDetails: activePurchase,
                  replacementMode: ReplacementMode.withTimeProration,
                ),
        ),
      ).timeout(_platformOperationTimeout);
    } catch (error) {
      debugPrint('Google Play purchase start failed: ${error.runtimeType}');
      return false;
    }
  }

  Future<GooglePlayRestoreResult> restorePurchases() async {
    final accountId = _accountId;
    if (accountId == null) return GooglePlayRestoreResult.unavailable;
    if (!_ready) await init();
    if (!_ready) return GooglePlayRestoreResult.unavailable;
    final activeRestore = _restoreCompleter;
    if (activeRestore != null && !activeRestore.isCompleted) {
      return activeRestore.future;
    }

    _activePurchase = null;
    _restoreTimer?.cancel();
    _restoreCompleter = Completer<GooglePlayRestoreResult>();
    try {
      await _platform
          .restorePurchases(applicationUserName: accountId)
          .timeout(_platformOperationTimeout);
      _restoreTimer = Timer(
        _restoreTimeout,
        () => _completeRestore(GooglePlayRestoreResult.noPurchases),
      );
      return await _restoreCompleter!.future;
    } catch (error) {
      debugPrint('Google Play restore failed: $error');
      _completeRestore(GooglePlayRestoreResult.failed);
      return GooglePlayRestoreResult.failed;
    }
  }

  Future<void> retryPendingTransactions() async {
    if (!_isGooglePlay || _accountId == null) return;
    await restorePurchases();
  }

  void _completeRestore(GooglePlayRestoreResult result) {
    _restoreTimer?.cancel();
    final completer = _restoreCompleter;
    if (completer != null && !completer.isCompleted) completer.complete(result);
  }

  Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase is GooglePlayPurchaseDetails) {
        _activePurchase = purchase;
      }
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final restored = purchase.status == PurchaseStatus.restored;
          if (restored) _restoreTimer?.cancel();
          final verified = await _verifyAndFinish(
            purchase,
            notifyPurchaseFinished: !restored,
          );
          if (restored) {
            _completeRestore(
              verified
                  ? GooglePlayRestoreResult.restored
                  : GooglePlayRestoreResult.failed,
            );
          }
        case PurchaseStatus.error:
          onPurchaseFinished?.call(
            false,
            purchase.error?.message ?? 'Purchase failed',
          );
          _completeRestore(GooglePlayRestoreResult.failed);
        case PurchaseStatus.canceled:
          onPurchaseFinished?.call(false, null);
        case PurchaseStatus.pending:
          break;
      }
    }
  }

  Future<bool> _verifyAndFinish(
    PurchaseDetails purchase, {
    required bool notifyPurchaseFinished,
  }) async {
    if (_accountId == null) {
      debugPrint(
        'Google Play verification deferred until a DINQ user is available',
      );
      return false;
    }
    try {
      await _transactionVerifier({
        'purchase_token': purchase.verificationData.serverVerificationData,
        'product_id': purchase.productID,
        if (purchase.purchaseID != null) 'order_id': purchase.purchaseID,
      });
      if (purchase.pendingCompletePurchase) {
        await _platform.completePurchase(purchase);
      }
      await onSubscriptionChanged?.call();
      if (notifyPurchaseFinished) onPurchaseFinished?.call(true, null);
      return true;
    } catch (error) {
      debugPrint('Google Play server verification failed: $error');
      if (notifyPurchaseFinished) {
        onPurchaseFinished?.call(
          false,
          'Purchase completed but activation failed. It will be retried automatically.',
        );
      }
      return false;
    }
  }

  Future<void> dispose() async {
    _restoreTimer?.cancel();
    await _purchaseSub?.cancel();
    _purchaseSub = null;
    _ready = false;
  }
}
