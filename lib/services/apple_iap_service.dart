import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';

import 'payment_service.dart';

enum AppleRestoreResult { restored, noPurchases, unavailable, failed }

enum _AppleVerificationResult {
  verified,
  foreignAccount,
  unlinkedAccount,
  failed,
  deferred,
}

typedef AppleTransactionVerifier =
    Future<Map<String, dynamic>> Function(Map<String, dynamic> data);

class AppleIapService {
  AppleIapService._({
    InAppPurchasePlatform? platform,
    AppleTransactionVerifier? transactionVerifier,
    bool? isIOSOverride,
    Duration restoreTimeout = const Duration(seconds: 5),
    Duration initializationTimeout = const Duration(seconds: 10),
  }) : _platformOverride = platform,
       _transactionVerifier =
           transactionVerifier ?? PaymentService().verifyAppleTransaction,
       _isIOSOverride = isIOSOverride,
       _restoreTimeout = restoreTimeout,
       _initializationTimeout = initializationTimeout;

  @visibleForTesting
  factory AppleIapService.forTesting({
    required InAppPurchasePlatform platform,
    required AppleTransactionVerifier transactionVerifier,
    Duration restoreTimeout = const Duration(milliseconds: 20),
    Duration initializationTimeout = const Duration(milliseconds: 200),
  }) => AppleIapService._(
    platform: platform,
    transactionVerifier: transactionVerifier,
    isIOSOverride: true,
    restoreTimeout: restoreTimeout,
    initializationTimeout: initializationTimeout,
  );

  static final AppleIapService instance = AppleIapService._();
  static const _productIdPrefix = 'me.dinq.app.';
  static const Map<String, String> _productIdByPlan = {
    'pro_monthly': 'me.dinq.app.pro.monthly',
    'basic_monthly': 'me.dinq.app.basic.monthly.v2',
    'basic_yearly': 'me.dinq.app.basic.yearly',
  };
  static final Set<String> _productIds = _productIdByPlan.values.toSet();
  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );
  static const _bridge = MethodChannel('me.dinq.app/storekit');

  final InAppPurchasePlatform? _platformOverride;
  final AppleTransactionVerifier _transactionVerifier;
  final bool? _isIOSOverride;
  final Duration _restoreTimeout;
  final Duration _initializationTimeout;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  Map<String, ProductDetails> _products = {};
  bool _ready = false;
  Future<void>? _initialization;
  String? Function()? _userIdProvider;
  Completer<AppleRestoreResult>? _restoreCompleter;
  Timer? _restoreTimer;
  bool _restoreHadVerificationFailure = false;
  String? _purchaseStartErrorMessage;

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
      if (!await iap.isAvailable().timeout(_initializationTimeout)) return;
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
      final platformCode = switch (error) {
        IAPError(:final code) => ' ($code)',
        PlatformException(:final code) => ' ($code)',
        _ => '',
      };
      debugPrint('IAP init failed: ${error.runtimeType}$platformCode');
      await _purchaseSub?.cancel();
      _purchaseSub = null;
    }
  }

  Future<void> _loadProducts() async {
    final requestedProductIds = _productIds.toList()..sort();
    debugPrint('IAP requested product IDs: $requestedProductIds');
    final response = await _platform
        .queryProductDetails(_productIds)
        .timeout(_initializationTimeout);
    final returnedProductIds =
        response.productDetails.map((product) => product.id).toList()..sort();
    debugPrint('IAP returned product IDs: $returnedProductIds');
    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('IAP products not found: ${response.notFoundIDs}');
    }
    if (response.error case final error?) {
      debugPrint('IAP product query failed: ${error.code}');
      _products = {};
      throw error;
    }
    _products = {
      for (final product in response.productDetails) product.id: product,
    };
  }

  static String productIdForPlan(String plan) =>
      _productIdByPlan[plan] ?? '$_productIdPrefix${plan.replaceAll('_', '.')}';

  static bool isSupportedPlan(String plan) =>
      _productIdByPlan.containsKey(plan);

  static List<String> refundProductIdsForPlan(String plan) {
    final currentProductId = productIdForPlan(plan);
    if (plan == 'basic_monthly') {
      return [currentProductId, 'me.dinq.app.basic.monthly'];
    }
    return [currentProductId];
  }

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

  String? get purchaseStartErrorMessage => _purchaseStartErrorMessage;

  Future<bool> buy(String plan) async {
    _purchaseStartErrorMessage = null;
    final appAccountToken = _appAccountToken;
    if (appAccountToken == null) {
      _purchaseStartErrorMessage = 'Please sign in again before purchasing.';
      return false;
    }
    if (!_ready) await init();
    if (!_ready) {
      _purchaseStartErrorMessage =
          'The App Store is unavailable. Please try again later.';
      return false;
    }

    var product = _products[productIdForPlan(plan)];
    if (product == null) {
      try {
        await _loadProducts();
      } catch (error) {
        debugPrint('IAP product reload failed: ${error.runtimeType}');
        _purchaseStartErrorMessage =
            'The App Store is unavailable. Please try again later.';
        return false;
      }
      product = _products[productIdForPlan(plan)];
    }
    if (product == null) {
      _purchaseStartErrorMessage =
          'This subscription is not available in the App Store for this build. '
          'Please contact support.';
      return false;
    }

    try {
      final started = await _platform.buyNonConsumable(
        purchaseParam: PurchaseParam(
          productDetails: product,
          applicationUserName: appAccountToken,
        ),
      );
      if (!started) {
        _purchaseStartErrorMessage =
            'The App Store could not start this purchase. '
            'Please check your App Store account and try again.';
      }
      return started;
    } catch (error) {
      final platformCode = error is PlatformException ? ' (${error.code})' : '';
      debugPrint(
        'IAP purchase start failed: ${error.runtimeType}$platformCode',
      );
      _purchaseStartErrorMessage =
          'The App Store could not start this purchase. '
          'Please check your App Store account and try again.';
      return false;
    }
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
    _restoreHadVerificationFailure = false;
    try {
      await _platform.restorePurchases(applicationUserName: _appAccountToken);
      _startRestoreTimeout();
      return await _restoreCompleter!.future;
    } catch (error) {
      debugPrint('IAP restore failed: $error');
      _restoreHadVerificationFailure = true;
      _startRestoreTimeout();
      return await _restoreCompleter!.future;
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

  void _startRestoreTimeout() {
    final completer = _restoreCompleter;
    if (completer == null || completer.isCompleted) return;
    _restoreTimer?.cancel();
    _restoreTimer = Timer(_restoreTimeout, () {
      _completeRestore(
        _restoreHadVerificationFailure
            ? AppleRestoreResult.failed
            : AppleRestoreResult.noPurchases,
      );
    });
  }

  Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
    var restoredVerified = false;
    var restoredVerificationFailed = false;
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final verificationResult = await _verifyAndFinish(
            purchase,
            notifyPurchaseFinished: purchase.status != PurchaseStatus.restored,
          );
          if (purchase.status == PurchaseStatus.restored) {
            restoredVerified |=
                verificationResult == _AppleVerificationResult.verified;
            restoredVerificationFailed |=
                verificationResult == _AppleVerificationResult.failed;
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
    if (restoredVerified) {
      _completeRestore(AppleRestoreResult.restored);
    } else if (restoredVerificationFailed) {
      _restoreHadVerificationFailure = true;
    }
  }

  Future<_AppleVerificationResult> _verifyAndFinish(
    PurchaseDetails purchase, {
    required bool notifyPurchaseFinished,
  }) async {
    final currentAppAccountToken = _appAccountToken;
    if (currentAppAccountToken == null) {
      debugPrint('IAP verification deferred until a DINQ user is available');
      return _AppleVerificationResult.deferred;
    }
    final transactionAppAccountToken = switch (purchase) {
      SK2PurchaseDetails(:final appAccountToken) => appAccountToken,
      _ => null,
    };
    if (purchase is SK2PurchaseDetails && transactionAppAccountToken == null) {
      debugPrint(
        'IAP verification skipped because the StoreKit transaction has no '
        'DINQ account link',
      );
      if (notifyPurchaseFinished) {
        onPurchaseFinished?.call(
          false,
          'This purchase is not linked to a DINQ account. '
          'Please contact support.',
        );
      }
      return _AppleVerificationResult.unlinkedAccount;
    }
    if (transactionAppAccountToken != null &&
        transactionAppAccountToken.toLowerCase() !=
            currentAppAccountToken.toLowerCase()) {
      debugPrint(
        'IAP verification skipped because the transaction belongs to '
        'another DINQ account',
      );
      if (notifyPurchaseFinished) {
        onPurchaseFinished?.call(
          false,
          'This purchase belongs to another DINQ account. '
          'Sign in with the account used for this purchase.',
        );
      }
      return _AppleVerificationResult.foreignAccount;
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
      return _AppleVerificationResult.verified;
    } catch (error) {
      debugPrint('IAP server verify failed: $error');
      if (notifyPurchaseFinished) {
        onPurchaseFinished?.call(false, _activationFailureMessage(error));
      }
      return _AppleVerificationResult.failed;
    }
  }

  static String _activationFailureMessage(Object error) {
    final backendMessage = error is DioException
        ? error.error?.toString()
        : null;
    switch (backendMessage) {
      case 'This App Store product is not configured.':
        return '$backendMessage Please contact support.';
      case 'This purchase belongs to another DINQ account.':
        return '$backendMessage Sign in with the account used for this purchase.';
      case 'This App Store subscription is no longer active.':
      case 'The App Store transaction could not be verified.':
      case 'subscription is managed by another payment channel':
        return backendMessage!;
      default:
        return 'Purchase completed but activation failed. It will be retried automatically.';
    }
  }

  Future<void> showManageSubscriptions() =>
      _bridge.invokeMethod<void>('showManageSubscriptions');

  Future<String?> beginRefundRequest(String plan) async {
    PlatformException? noTransactionError;
    for (final productId in refundProductIdsForPlan(plan)) {
      try {
        return await _bridge.invokeMethod<String>('beginRefundRequest', {
          'productId': productId,
        });
      } on PlatformException catch (error) {
        if (error.code != 'no_transaction') rethrow;
        noTransactionError = error;
      }
    }
    if (noTransactionError != null) throw noTransactionError;
    return null;
  }

  void dispose() {
    _restoreTimer?.cancel();
    _purchaseSub?.cancel();
    _ready = false;
  }
}
