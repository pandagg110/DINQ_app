import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';

import 'payment_service.dart';

enum AppleRestoreResult { restored, noPurchases, unavailable, failed }

typedef AppleTransactionVerifier =
    Future<Map<String, dynamic>> Function(Map<String, dynamic> data);

class AppleIapService {
  AppleIapService._({
    InAppPurchasePlatform? platform,
    AppleTransactionVerifier? transactionVerifier,
    bool? isIOSOverride,
    Duration restoreTimeout = const Duration(seconds: 5),
  }) : _platformOverride = platform,
       _transactionVerifier =
           transactionVerifier ?? PaymentService().verifyAppleTransaction,
       _isIOSOverride = isIOSOverride,
       _restoreTimeout = restoreTimeout;

  @visibleForTesting
  factory AppleIapService.forTesting({
    required InAppPurchasePlatform platform,
    required AppleTransactionVerifier transactionVerifier,
    Duration restoreTimeout = const Duration(milliseconds: 20),
  }) => AppleIapService._(
    platform: platform,
    transactionVerifier: transactionVerifier,
    isIOSOverride: true,
    restoreTimeout: restoreTimeout,
  );

  static final AppleIapService instance = AppleIapService._();
  static const _productIdPrefix = 'me.dinq.app.';
  static const Set<String> _productIds = {
    'me.dinq.app.pro.monthly',
    'me.dinq.app.pro.yearly',
    'me.dinq.app.basic.monthly',
    'me.dinq.app.basic.yearly',
  };
  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );
  static const _bridge = MethodChannel('me.dinq.app/storekit');

  final InAppPurchasePlatform? _platformOverride;
  final AppleTransactionVerifier _transactionVerifier;
  final bool? _isIOSOverride;
  final Duration _restoreTimeout;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  Map<String, ProductDetails> _products = {};
  bool _ready = false;
  Future<void>? _initialization;
  String? Function()? _userIdProvider;
  Completer<AppleRestoreResult>? _restoreCompleter;
  Timer? _restoreTimer;

  Future<void> Function()? onSubscriptionChanged;
  void Function(bool success, String? message)? onPurchaseFinished;

  bool get _isIOS =>
      _isIOSOverride ??
      (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS);

  InAppPurchasePlatform get _platform =>
      _platformOverride ?? InAppPurchasePlatform.instance;

  void setUserIdProvider(String? Function() provider) {
    _userIdProvider = provider;
  }

  Future<void> init() {
    if (!_isIOS || _ready) return Future<void>.value();
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
        InAppPurchaseStoreKitPlatform.registerPlatform();
      }
      final iap = _platform;
      if (!await iap.isAvailable()) return;
      _purchaseSub = iap.purchaseStream.listen(
        _onPurchaseUpdates,
        onError: (Object error) {
          debugPrint('IAP stream error: $error');
          _completeRestore(AppleRestoreResult.failed);
        },
      );
      await _loadProducts();
      _ready = true;
    } catch (error) {
      debugPrint('IAP init failed: $error');
      await _purchaseSub?.cancel();
      _purchaseSub = null;
    }
  }

  Future<void> _loadProducts() async {
    final response = await _platform.queryProductDetails(_productIds);
    _products = {
      for (final product in response.productDetails) product.id: product,
    };
    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('IAP products not found: ${response.notFoundIDs}');
    }
  }

  static String productIdForPlan(String plan) =>
      '$_productIdPrefix${plan.replaceAll('_', '.')}';

  static bool isSupportedPlan(String plan) =>
      _productIds.contains(productIdForPlan(plan));

  static String? appAccountTokenForUser(String? userId) {
    if (userId == null || !_uuidPattern.hasMatch(userId)) return null;
    return userId;
  }

  static String? localizedPriceForPlan(
    String plan,
    Iterable<ProductDetails> products,
  ) {
    final productId = productIdForPlan(plan);
    for (final product in products) {
      if (product.id == productId) return product.price;
    }
    return null;
  }

  String? get _appAccountToken =>
      appAccountTokenForUser(_userIdProvider?.call());

  bool supportsPlan(String plan) => isSupportedPlan(plan);

  String? priceForPlan(String plan) =>
      localizedPriceForPlan(plan, _products.values);

  Future<bool> buy(String plan) async {
    final appAccountToken = _appAccountToken;
    if (appAccountToken == null) return false;
    if (!_ready) await init();
    if (!_ready) return false;

    var product = _products[productIdForPlan(plan)];
    if (product == null) {
      await _loadProducts();
      product = _products[productIdForPlan(plan)];
    }
    if (product == null) return false;

    return _platform.buyNonConsumable(
      purchaseParam: PurchaseParam(
        productDetails: product,
        applicationUserName: appAccountToken,
      ),
    );
  }

  Future<AppleRestoreResult> restorePurchases() async {
    if (_appAccountToken == null) return AppleRestoreResult.unavailable;
    if (!_ready) await init();
    if (!_ready) return AppleRestoreResult.unavailable;
    final activeRestore = _restoreCompleter;
    if (activeRestore != null && !activeRestore.isCompleted) {
      return activeRestore.future;
    }

    _restoreTimer?.cancel();
    _restoreCompleter = Completer<AppleRestoreResult>();
    try {
      await _platform.restorePurchases(applicationUserName: _appAccountToken);
      _restoreTimer = Timer(_restoreTimeout, () {
        _completeRestore(AppleRestoreResult.noPurchases);
      });
      return await _restoreCompleter!.future;
    } catch (error) {
      debugPrint('IAP restore failed: $error');
      _completeRestore(AppleRestoreResult.failed);
      return AppleRestoreResult.failed;
    }
  }

  Future<void> retryPendingTransactions() async {
    if (!_isIOS || _appAccountToken == null) return;
    await restorePurchases();
  }

  void _completeRestore(AppleRestoreResult result) {
    _restoreTimer?.cancel();
    final completer = _restoreCompleter;
    if (completer != null && !completer.isCompleted) completer.complete(result);
  }

  Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (purchase.status == PurchaseStatus.restored) {
            _restoreTimer?.cancel();
          }
          final verified = await _verifyAndFinish(
            purchase,
            notifyPurchaseFinished: purchase.status != PurchaseStatus.restored,
          );
          if (purchase.status == PurchaseStatus.restored) {
            _completeRestore(
              verified
                  ? AppleRestoreResult.restored
                  : AppleRestoreResult.failed,
            );
          }
        case PurchaseStatus.error:
          onPurchaseFinished?.call(
            false,
            purchase.error?.message ?? 'Purchase failed',
          );
          _completeRestore(AppleRestoreResult.failed);
          if (purchase.pendingCompletePurchase) {
            await _platform.completePurchase(purchase);
          }
        case PurchaseStatus.canceled:
          onPurchaseFinished?.call(false, null);
          if (purchase.pendingCompletePurchase) {
            await _platform.completePurchase(purchase);
          }
        case PurchaseStatus.pending:
          break;
      }
    }
  }

  Future<bool> _verifyAndFinish(
    PurchaseDetails purchase, {
    required bool notifyPurchaseFinished,
  }) async {
    if (_appAccountToken == null) {
      debugPrint('IAP verification deferred until a DINQ user is available');
      return false;
    }
    try {
      await _transactionVerifier({
        'jws': purchase.verificationData.serverVerificationData,
        'product_id': purchase.productID,
        if (purchase.purchaseID != null) 'transaction_id': purchase.purchaseID,
      });
      if (purchase.pendingCompletePurchase) {
        await _platform.completePurchase(purchase);
      }
      await onSubscriptionChanged?.call();
      if (notifyPurchaseFinished) onPurchaseFinished?.call(true, null);
      return true;
    } catch (error) {
      debugPrint('IAP server verify failed: $error');
      if (notifyPurchaseFinished) {
        onPurchaseFinished?.call(
          false,
          'Purchase completed but activation failed. It will be retried automatically.',
        );
      }
      return false;
    }
  }

  Future<void> showManageSubscriptions() =>
      _bridge.invokeMethod<void>('showManageSubscriptions');

  Future<String?> beginRefundRequest(String plan) =>
      _bridge.invokeMethod<String>('beginRefundRequest', {
        'productId': productIdForPlan(plan),
      });

  void dispose() {
    _restoreTimer?.cancel();
    _purchaseSub?.cancel();
    _ready = false;
  }
}
