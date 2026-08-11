import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/analytics_service.dart';
import '../../services/apple_iap_service.dart';
import '../../services/app_update_service.dart';
import '../../services/google_play_iap_service.dart';
import '../../services/payment_channel.dart';
import '../../services/payment_service.dart';
import '../../services/store_price_display.dart';
import '../../services/store_cancellation_flow.dart';
import '../../stores/user_store.dart';
import '../../utils/color_util.dart';
import '../../utils/top_toast_util.dart';
import '../../widgets/common/base_page.dart';
import '../../widgets/common/default_app_bar.dart';
import '../../widgets/marketing/contact_support_dialog.dart';
import '../../widgets/marketing/store_cancellation_dialog.dart';
import '../../widgets/subscription/subscription_managed_elsewhere_dialog.dart';
import 'subscription_plan_display.dart';

// ─── Plan 配置常量 ────────────────────────────────────────────────

// 对齐 web PUBLIC_PLAN_ORDER：线上只展示 free/basic/pro + Enterprise 共 4 档，
// plus 不再单独售卖（仅存量用户，展示为 Pro）
const List<String> kPlanOrder = ['free', 'basic', 'pro'];

const Map<String, int> kPlanLevel = {
  'free': 0,
  'basic': 1,
  'pro': 2,
  'plus': 3, // 存量 plus 订阅用户仍需比较档位
};

// 对齐 web PLAN_LABEL：plus 显示为 Pro
const Map<String, String> kPlanLabel = {
  'free': 'Free',
  'basic': 'Basic',
  'pro': 'Pro',
  'plus': 'Pro',
};

class _PlanConfig {
  final String subtitle;
  final String sectionHeader;
  final String creditsFormat;
  final bool popular;

  const _PlanConfig({
    required this.subtitle,
    required this.sectionHeader,
    required this.creditsFormat,
    this.popular = false,
  });
}

// 文案对齐 web messages/en/marketing.json pricing.plans
const Map<String, _PlanConfig> kPlanConfig = {
  'free': _PlanConfig(
    subtitle: 'Trial Users / Light Personal Use',
    sectionHeader: 'Free includes:',
    creditsFormat: '{credits} Credits (One-time)',
  ),
  'basic': _PlanConfig(
    subtitle: 'Individual Users / Beginners',
    sectionHeader: 'Everything in Free, plus:',
    creditsFormat: '{credits} Credits /month',
  ),
  'pro': _PlanConfig(
    subtitle: 'Recruiters / Sales',
    sectionHeader: 'Everything in Basic, plus:',
    creditsFormat: '{credits} Credits /month',
    popular: true,
  ),
};

// ─── 工具函数 ────────────────────────────────────────────────────

String _getPricingKey(String plan, String period) {
  if (plan == 'free') return 'free';
  return '${plan}_$period';
}

/// 解析 **text** 为加粗文本
List<InlineSpan> _parseBoldText(String text) {
  final regex = RegExp(r'(\*\*[^*]+\*\*)');
  final parts = text.split(regex);
  final spans = <InlineSpan>[];

  for (final part in parts) {
    if (part.startsWith('**') && part.endsWith('**')) {
      spans.add(
        TextSpan(
          text: part.substring(2, part.length - 2),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF171717),
            fontSize: 14,
            fontFamily: 'Geist',
          ),
        ),
      );
    } else if (part.isNotEmpty) {
      spans.add(
        TextSpan(
          text: part,
          style: const TextStyle(
            color: Color(0xFF666666),
            fontSize: 14,
            fontFamily: 'Geist',
          ),
        ),
      );
    }
  }
  return spans;
}

Future<void> refreshStorePurchaseUi({
  required Future<void> Function() refreshSubscription,
  required Future<void> Function() refreshPricing,
}) async {
  await refreshSubscription();
  await refreshPricing();
}

// ─── PricingPage ─────────────────────────────────────────────────

class PricingPage extends StatefulWidget {
  const PricingPage({super.key});

  @override
  State<PricingPage> createState() => _PricingPageState();
}

class SubscriptionPlanHeader extends StatelessWidget {
  const SubscriptionPlanHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.savingsLabel,
  });

  final String title;
  final String subtitle;
  final String? savingsLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: Color(0xFF171717),
                fontFamily: 'Geist',
              ),
            ),
            if (savingsLabel case final label?) ...[
              const SizedBox(width: 8),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.sell_outlined,
                            size: 14,
                            color: Color(0xFF16A34A),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            label,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF16A34A),
                              fontFamily: 'Geist',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF9CA3AF),
            fontFamily: 'Geist',
          ),
        ),
      ],
    );
  }
}

class SubscriptionPriceSummary extends StatelessWidget {
  const SubscriptionPriceSummary({
    super.key,
    required this.displayedPrice,
    this.displayedPeriod,
    this.strikethroughPrice,
    this.yearlyTotalLabel,
  });

  final String displayedPrice;
  final String? displayedPeriod;
  final String? strikethroughPrice;
  final String? yearlyTotalLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (strikethroughPrice case final originalPrice?) ...[
          Text(
            originalPrice,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF9E9B93),
              decoration: TextDecoration.lineThrough,
              decorationColor: Color(0xFF9E9B93),
              fontFamily: 'Geist',
            ),
          ),
          const SizedBox(height: 4),
        ],
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                displayedPrice,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF171717),
                  fontFamily: 'Geist',
                ),
              ),
              if (displayedPeriod case final period?)
                Text(
                  period,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF171717),
                    fontFamily: 'Geist',
                  ),
                ),
            ],
          ),
        ),
        if (yearlyTotalLabel case final total?) ...[
          const SizedBox(height: 4),
          Text(
            total,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0x4D303030),
              fontFamily: 'Geist',
            ),
          ),
        ],
      ],
    );
  }
}

class _PricingPageState extends State<PricingPage>
    with WidgetsBindingObserver {
  final PaymentService _paymentService = PaymentService();

  Map<String, dynamic>? _pricing;
  bool _isLoading = true;
  bool _hasError = false;
  String _billingPeriod = 'yearly';
  String? _processingPlan;
  bool _selectionInitialized = false;
  bool _awaitingStoreCancellationReturn = false;
  bool _leftAppForStoreCancellation = false;
  bool _isRefreshingStoreCancellation = false;

  late PageController _pageController;
  int _currentPage = 1; // Free 用户默认推荐 Basic Yearly

  bool get _isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  SubscriptionPaymentChannel get _paymentChannel =>
      resolveSubscriptionPaymentChannel(
        isWeb: kIsWeb,
        platform: defaultTargetPlatform,
        distributionChannel: distributionChannel,
      );
  bool get _usesAppleIap => _paymentChannel == SubscriptionPaymentChannel.apple;
  bool get _usesGooglePlay =>
      _paymentChannel == SubscriptionPaymentChannel.googlePlay;
  bool get _usesStoreBilling => _usesAppleIap || _usesGooglePlay;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController(
      viewportFraction: 0.82,
      initialPage: _currentPage,
    );
    _fetchPricing();
    if (_isIOS) {
      AppleIapService.instance.onPurchaseFinished = _onIapPurchaseFinished;
    } else if (_usesGooglePlay) {
      GooglePlayIapService.instance.onPurchaseFinished = _onIapPurchaseFinished;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userStore = context.watch<UserStore>();
    if (_selectionInitialized || !userStore.isInitialized) return;
    if (userStore.isLoggedIn() && userStore.isLoadingSubscription) return;

    final currentPlan = userStore.subscription?.plan ?? 'free';
    final (basePlan, billingPeriod) = initialSubscriptionSelection(currentPlan);
    final visiblePlans = visibleSubscriptionBasePlans(
      billingPeriod: billingPeriod,
      currentPlan: currentPlan,
    );
    _billingPeriod = billingPeriod;
    final selectedIndex = visiblePlans.indexOf(basePlan);
    _currentPage = selectedIndex >= 0 ? selectedIndex : 0;
    _selectionInitialized = true;
    if (_pageController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageController.hasClients) {
          _pageController.jumpToPage(_currentPage);
        }
      });
    } else {
      _pageController.dispose();
      _pageController = PageController(
        viewportFraction: 0.82,
        initialPage: _currentPage,
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_isIOS) AppleIapService.instance.onPurchaseFinished = null;
    if (_usesGooglePlay) {
      GooglePlayIapService.instance.onPurchaseFinished = null;
    }
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_awaitingStoreCancellationReturn) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _leftAppForStoreCancellation = true;
      return;
    }
    if (state == AppLifecycleState.resumed && _leftAppForStoreCancellation) {
      unawaited(_refreshStoreCancellationConfirmation());
    }
  }

  void _onIapPurchaseFinished(bool success, String? message) {
    if (!mounted) return;
    if (success) {
      unawaited(_refreshAfterStorePurchase());
    } else if (message != null) {
      setState(() => _processingPlan = null);
      TopToastUtil.showError(
        context: context,
        title: 'Purchase failed',
        description: message,
      );
    } else {
      setState(() => _processingPlan = null);
    }
  }

  Future<void> _refreshAfterStorePurchase() async {
    final userStore = context.read<UserStore>();
    await refreshStorePurchaseUi(
      refreshSubscription: userStore.refreshSubscription,
      refreshPricing: _refreshPricingActions,
    );
    if (!mounted) return;
    setState(() => _processingPlan = null);
    TopToastUtil.showSuccess(
      context: context,
      title: 'Subscription activated',
      description: 'Your plan has been updated.',
    );
  }

  Future<void> _refreshPricingActions() async {
    try {
      final data = await _paymentService.getPricing();
      if (mounted) setState(() => _pricing = data);
    } catch (_) {
      // The subscription itself is already refreshed. A later page load will
      // retry pricing action metadata if this secondary request fails.
    }
  }

  Future<void> _fetchPricing() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final data = await _paymentService.getPricing();
      if (_usesAppleIap) await AppleIapService.instance.init();
      if (_usesGooglePlay) await GooglePlayIapService.instance.init();
      if (mounted) {
        setState(() {
          _pricing = data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  // ─── 换购逻辑：以 pricing 接口的 upgrade 字段为准 ───────────

  String _planKey(String basePlan) {
    if (basePlan == 'free') return 'free';
    return '${basePlan}_$_billingPeriod';
  }

  PricingPlanAction _pricingAction(String basePlan) {
    return pricingPlanAction(pricing: _pricing, plan: _planKey(basePlan));
  }

  bool _canChangePlan(String targetBasePlan) {
    final action = _pricingAction(targetBasePlan);
    final actionEnabled = pricingPlanActionEnabled(action);
    if (actionEnabled != null) return actionEnabled;

    final userStore = context.read<UserStore>();
    if (!userStore.isLoggedIn()) return true;

    final subscription = userStore.subscription;
    final currentPlan = subscription?.plan ?? 'free';
    final targetPlan = targetBasePlan == 'free'
        ? 'free'
        : '${targetBasePlan}_$_billingPeriod';
    return targetPlan != currentPlan;
  }

  bool _isCurrentPlan(String basePlan) {
    final action = _pricingAction(basePlan);
    if (action != PricingPlanAction.unknown) {
      return action == PricingPlanAction.currentPlan;
    }

    final userStore = context.read<UserStore>();
    if (!userStore.isLoggedIn()) return false;

    final subscription = userStore.subscription;
    final currentPlan = subscription?.plan ?? 'free';
    final currentBasePlan = subscription?.basePlan ?? 'free';
    final currentBillingPeriod = subscription?.billingPeriod;

    if (basePlan == 'free') return currentPlan == 'free';
    return basePlan == currentBasePlan &&
        _billingPeriod == currentBillingPeriod;
  }

  // 按钮文案对齐 web pricing.cta
  String _getButtonText(String basePlan) {
    final userStore = context.read<UserStore>();
    final fallbackLabel = subscriptionActionLabel(
      currentPlan: userStore.subscription?.plan ?? 'free',
      targetBasePlan: basePlan,
      targetBillingPeriod: _billingPeriod,
      isLoggedIn: userStore.isLoggedIn(),
      cancelAtPeriodEnd:
          basePlan == 'free' &&
          (userStore.subscription?.cancelAtPeriodEnd ?? false),
    );
    final action = _pricingAction(basePlan);
    if (basePlan == 'free' &&
        (userStore.subscription?.cancelAtPeriodEnd ?? false) &&
        (action == PricingPlanAction.unknown ||
            action == PricingPlanAction.legacyUnavailable)) {
      return fallbackLabel;
    }
    return subscriptionButtonLabel(
      action: action,
      currentPlan: userStore.subscription?.plan ?? 'free',
      fallbackLabel: fallbackLabel,
    );
  }

  bool _isButtonDisabled(String basePlan) {
    if (_processingPlan != null) return true;
    final userStore = context.read<UserStore>();
    if (basePlan == 'free' &&
        (userStore.subscription?.cancelAtPeriodEnd ?? false)) {
      return true;
    }
    final action = _pricingAction(basePlan);
    final actionEnabled = pricingPlanActionEnabled(action);
    if (actionEnabled == false) return true;
    if (!_isPlanAvailable(basePlan)) return true;
    if (_isCurrentPlan(basePlan)) return true;
    if (userStore.isLoggedIn() && !_canChangePlan(basePlan)) return true;
    return false;
  }

  bool _isPlanAvailable(String basePlan) {
    if (basePlan == 'free' || !_usesStoreBilling) return true;
    final fullPlan = '${basePlan}_$_billingPeriod';
    return _usesAppleIap
        ? AppleIapService.instance.supportsPlan(fullPlan) &&
              AppleIapService.instance.hasProductForPlan(fullPlan)
        : GooglePlayIapService.instance.supportsPlan(fullPlan);
  }

  Future<void> _handleSelectPlan(String basePlan) async {
    final userStore = context.read<UserStore>();

    if (_isCurrentPlan(basePlan)) return;
    if (userStore.isLoggedIn() && !_canChangePlan(basePlan)) return;

    // 未登录 → 跳转登录
    if (!userStore.isLoggedIn()) {
      context.push('/signin');
      return;
    }

    final currentPlan = userStore.subscription?.plan ?? 'free';
    if (requiresProYearlyExitConfirmation(
          currentPlan: currentPlan,
          targetBasePlan: basePlan,
          targetBillingPeriod: _billingPeriod,
        ) &&
        !await _confirmLeavingProYearly()) {
      return;
    }
    if (!mounted) return;

    // 降级到 Free：确认后关闭自动续费（对齐 web downgradeDialog + setAutoRenew）
    if (basePlan == 'free') {
      final storeChannel = storeSubscriptionChannelFromApi(
        userStore.subscription?.channel,
      );
      if (storeChannel != null) {
        await _handleStoreDowngrade(storeChannel);
        return;
      }
      await _handleDowngradeToFree();
      return;
    }

    final subscription = userStore.subscription;
    final isCurrentPlanFree = subscription?.isFree ?? true;
    final fullPlan = '${basePlan}_$_billingPeriod';

    if (_usesAppleIap) {
      await _handleAppleCheckout(fullPlan, basePlan);
      return;
    }
    if (_usesGooglePlay) {
      await _handleGooglePlayCheckout(fullPlan, basePlan);
      return;
    }

    if (!isCurrentPlanFree &&
        (subscription?.isAppleChannel == true ||
            subscription?.isGooglePlayChannel == true)) {
      await showSubscriptionManagedElsewhereDialog(
        context,
        subscriptionChannel: subscription?.channel,
      );
      return;
    }

    setState(() => _processingPlan = basePlan);

    try {
      Map<String, dynamic>? response;

      if (isCurrentPlanFree) {
        response = await _paymentService.checkout({'plan': fullPlan});
      } else {
        response = await _paymentService.changePlan({'target_plan': fullPlan});
      }

      final url = response['url']?.toString();
      if (url != null && url.isNotEmpty && mounted) {
        // 埋点：成功进入支付流程（App 内 web 收银台按方案记 stripe）。
        // markCheckoutStarted 供订阅刷新时确认 subscription_success。
        AnalyticsService.instance.track(
          'subscription_checkout_start',
          params: {
            'target_plan': basePlan,
            'billing_period': _billingPeriod,
            'payment_provider': 'stripe',
          },
          activationIntent: 'unknown',
        );
        AnalyticsService.instance.markCheckoutStarted(
          targetPlan: basePlan,
          billingPeriod: _billingPeriod,
          paymentProvider: 'stripe',
        );
        // 支付页关闭后刷新订阅，驱动 subscription_success 的后端确认上报
        context
            .push(
              '/webview',
              extra: {'url': url, 'navTitle': 'Checkout', 'showAppBar': 'true'},
            )
            .then((_) {
              if (mounted) context.read<UserStore>().refreshSubscription();
            });
      } else if (mounted) {
        if (!isCurrentPlanFree) {
          // 换购无需跳转支付页（如降级排期到期后生效）→ 视为成功，对齐 web
          await context.read<UserStore>().refreshSubscription();
          if (mounted) {
            TopToastUtil.showSuccess(
              context: context,
              title: response['message']?.toString() ?? 'Plan change scheduled',
            );
          }
        } else {
          TopToastUtil.showError(
            context: context,
            title: 'Unable to start checkout',
            description: 'Please try again later.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // 透出后端错误信息，便于定位支付失败原因（如月付 price 配置错误）
        TopToastUtil.showError(
          context: context,
          title: 'Unable to start checkout',
          description: _checkoutErrorDescription(e),
        );
      }
    } finally {
      if (mounted) setState(() => _processingPlan = null);
    }
  }

  Future<bool> _confirmLeavingProYearly() async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Switch plans?'),
            content: const Text(
              'Pro Yearly is not currently available for selection in this app.\n\n'
              'After switching, you won’t be able to switch back to this plan within the app.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Continue'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _handleAppleCheckout(String fullPlan, String basePlan) async {
    final subscription = context.read<UserStore>().subscription;
    final isCurrentPlanFree = subscription?.isFree ?? true;

    if (!isCurrentPlanFree && !(subscription?.isAppleChannel ?? false)) {
      await showSubscriptionManagedElsewhereDialog(
        context,
        subscriptionChannel: subscription?.channel,
      );
      return;
    }
    if (!AppleIapService.instance.supportsPlan(fullPlan)) {
      TopToastUtil.showError(
        context: context,
        title: 'Plan unavailable',
        description: 'This plan is not available on iOS.',
      );
      return;
    }

    setState(() => _processingPlan = basePlan);
    final started = await AppleIapService.instance.buy(fullPlan);
    if (!started && mounted) {
      setState(() => _processingPlan = null);
      TopToastUtil.showError(
        context: context,
        title: 'Unable to start purchase',
        description:
            AppleIapService.instance.purchaseStartErrorMessage ??
            'Please try again later.',
      );
      return;
    }
    if (started) {
      AnalyticsService.instance.track(
        'subscription_checkout_start',
        params: {
          'target_plan': basePlan,
          'billing_period': fullPlan.endsWith('_yearly') ? 'yearly' : 'monthly',
          'payment_provider': 'apple',
        },
        activationIntent: 'unknown',
      );
      AnalyticsService.instance.markCheckoutStarted(
        targetPlan: basePlan,
        billingPeriod: fullPlan.endsWith('_yearly') ? 'yearly' : 'monthly',
        paymentProvider: 'apple',
      );
    }
  }

  Future<void> _handleGooglePlayCheckout(
    String fullPlan,
    String basePlan,
  ) async {
    final subscription = context.read<UserStore>().subscription;
    final isCurrentPlanFree = subscription?.isFree ?? true;
    if (!isCurrentPlanFree && !(subscription?.isGooglePlayChannel ?? false)) {
      await showSubscriptionManagedElsewhereDialog(
        context,
        subscriptionChannel: subscription?.channel,
      );
      return;
    }
    if (!GooglePlayIapService.instance.supportsPlan(fullPlan)) {
      TopToastUtil.showError(
        context: context,
        title: 'Plan unavailable',
        description: 'This plan is not available on Google Play.',
      );
      return;
    }

    setState(() => _processingPlan = basePlan);
    final started = await GooglePlayIapService.instance.buy(fullPlan);
    if (!started && mounted) {
      setState(() => _processingPlan = null);
      TopToastUtil.showError(
        context: context,
        title: 'Unable to start purchase',
        description: 'Please try again later.',
      );
      return;
    }
    if (started) {
      final billingPeriod = fullPlan.endsWith('_yearly') ? 'yearly' : 'monthly';
      AnalyticsService.instance.track(
        'subscription_checkout_start',
        params: {
          'target_plan': basePlan,
          'billing_period': billingPeriod,
          'payment_provider': 'google_play',
        },
        activationIntent: 'unknown',
      );
      AnalyticsService.instance.markCheckoutStarted(
        targetPlan: basePlan,
        billingPeriod: billingPeriod,
        paymentProvider: 'google_play',
      );
    }
  }

  Future<void> _handleStoreDowngrade(
    StoreSubscriptionChannel channel,
  ) async {
    final subscription = context.read<UserStore>().subscription;
    if (subscription == null || subscription.cancelAtPeriodEnd) return;
    final copy = storeCancellationCopy(
      channel: channel,
      expirationDate: _formatFullDate(subscription.currentPeriodEnd),
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StoreCancellationDialog(
        copy: copy,
        onCancel: () => Navigator.of(dialogContext).pop(false),
        onContinue: () => Navigator.of(dialogContext).pop(true),
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _processingPlan = 'free');
    if (channel == StoreSubscriptionChannel.apple) {
      try {
        await AppleIapService.instance.showManageSubscriptions();
        await _refreshStoreCancellationConfirmation();
        return;
      } catch (_) {
        final launched = await _launchStoreSubscriptions(
          Uri.parse('https://apps.apple.com/account/subscriptions'),
        );
        if (launched) return;
      }
    } else {
      final launched = await _launchStoreSubscriptions(
        Uri.parse(
          'https://play.google.com/store/account/subscriptions?package=me.dinq.app',
        ),
      );
      if (launched) return;
    }

    if (!mounted) return;
    setState(() => _processingPlan = null);
    TopToastUtil.showError(
      context: context,
      title: 'Unable to open subscriptions',
      description: 'Please open your store account and manage the subscription.',
    );
  }

  Future<bool> _launchStoreSubscriptions(Uri uri) async {
    var launched = false;
    try {
      if (await canLaunchUrl(uri)) {
        _awaitingStoreCancellationReturn = true;
        _leftAppForStoreCancellation = false;
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
    if (!launched) {
      _awaitingStoreCancellationReturn = false;
      _leftAppForStoreCancellation = false;
    }
    return launched;
  }

  Future<void> _refreshStoreCancellationConfirmation() async {
    if (_isRefreshingStoreCancellation || !mounted) return;
    _isRefreshingStoreCancellation = true;
    _awaitingStoreCancellationReturn = false;
    _leftAppForStoreCancellation = false;
    final userStore = context.read<UserStore>();
    final confirmed = await refreshUntilStoreCancellationConfirmed(
      refresh: userStore.refreshSubscription,
      isConfirmed: () => userStore.subscription?.cancelAtPeriodEnd == true,
    );
    _isRefreshingStoreCancellation = false;
    if (!mounted) return;
    setState(() => _processingPlan = null);

    if (confirmed) {
      final subscription = userStore.subscription;
      final message = confirmedStoreCancellationMessage(
        cancelAtPeriodEnd: subscription?.cancelAtPeriodEnd ?? false,
        expirationDate: _formatFullDate(subscription?.currentPeriodEnd),
      );
      AnalyticsService.instance.track(
        'subscription_cancel',
        params: {
          'current_plan': subscription?.basePlan ?? 'unknown',
          'payment_provider': subscription?.channel ?? 'unknown',
        },
        activationIntent: 'unknown',
      );
      TopToastUtil.showSuccess(
        context: context,
        title: 'Cancellation scheduled',
        description: message!,
      );
      return;
    }

    TopToastUtil.showInfo(
      context: context,
      title: 'Cancellation not confirmed',
      description:
          'We have not received confirmation from the store yet. '
          'Your current plan remains active.',
    );
  }

  Future<void> _handleRestorePurchases() async {
    if (_usesGooglePlay) {
      final result = await GooglePlayIapService.instance.restorePurchases();
      if (!mounted) return;
      switch (result) {
        case GooglePlayRestoreResult.restored:
          TopToastUtil.showSuccess(
            context: context,
            title: 'Purchases restored',
            description: 'Your subscription has been refreshed.',
          );
        case GooglePlayRestoreResult.noPurchases:
          TopToastUtil.showInfo(
            context: context,
            title: 'No purchases found',
            description: 'No active Google Play subscription was found.',
          );
        case GooglePlayRestoreResult.unavailable:
        case GooglePlayRestoreResult.failed:
          TopToastUtil.showError(
            context: context,
            title: 'Unable to restore purchases',
            description: 'Please check your Google Play account and try again.',
          );
      }
      return;
    }
    final result = await AppleIapService.instance.restorePurchases();
    if (!mounted) return;
    switch (result) {
      case AppleRestoreResult.restored:
        TopToastUtil.showSuccess(
          context: context,
          title: 'Purchases restored',
          description: 'Your subscription has been refreshed.',
        );
      case AppleRestoreResult.noPurchases:
        TopToastUtil.showInfo(
          context: context,
          title: 'No purchases found',
          description: 'No active App Store subscription was found.',
        );
      case AppleRestoreResult.unavailable:
      case AppleRestoreResult.failed:
        TopToastUtil.showError(
          context: context,
          title: 'Unable to restore purchases',
          description: 'Please check your App Store account and try again.',
        );
    }
  }

  /// 从 DioException 提取后端 message；无可用信息时回退通用提示
  String _checkoutErrorDescription(Object error) {
    if (error is DioException) {
      final err = error.error;
      if (err is String && err.isNotEmpty) return err;
      final data = error.response?.data;
      if (data is Map &&
          data['message'] is String &&
          (data['message'] as String).isNotEmpty) {
        return data['message'] as String;
      }
    }
    return 'Please try again later.';
  }

  /// 降级到 Free：确认弹窗 + 关闭自动续费（文案对齐 web pricing.downgradeDialog）
  Future<void> _handleDowngradeToFree() async {
    final userStore = context.read<UserStore>();
    final accessUntil = _formatFullDate(
      userStore.subscription?.currentPeriodEnd,
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Downgrade to Free?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF171717),
                  fontFamily: 'Geist',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your paid plan will remain active until $accessUntil, '
                'then switch to Free. You will not be charged again.',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF525252),
                  fontFamily: 'Geist',
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  NormalButton(
                    onTap: () => Navigator.of(dialogContext).pop(true),
                    child: Container(
                      alignment: Alignment.center,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF171717),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Downgrade to Free',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontFamily: 'Geist',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  NormalButton(
                    onTap: () => Navigator.of(dialogContext).pop(false),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Text(
                        'Keep plan',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6B6862),
                          fontFamily: 'Geist',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _processingPlan = 'free');
    try {
      await _paymentService.setAutoRenew(autoRenew: false);
      await userStore.refreshSubscription();
      if (mounted) {
        TopToastUtil.showSuccess(
          context: context,
          title: 'Free downgrade scheduled',
        );
      }
    } catch (_) {
      if (mounted) {
        TopToastUtil.showError(
          context: context,
          title: 'Unable to update subscription',
          description: 'Please try again later.',
        );
      }
    } finally {
      if (mounted) setState(() => _processingPlan = null);
    }
  }

  /// ISO 日期 → "July 16, 2026"
  String _formatFullDate(String? iso) {
    final d = DateTime.tryParse(iso ?? '');
    if (d == null) return 'the end of your billing period';
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  Future<void> _handleContactSupport() async {
    final shouldContact = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => ContactSupportDialog(
        onContact: () => Navigator.of(dialogContext).pop(true),
      ),
    );
    if (shouldContact != true || !mounted) return;
    final uri = Uri.parse('mailto:support@dinqlabs.com');
    var launched = false;
    try {
      if (await canLaunchUrl(uri)) {
        launched = await launchUrl(uri);
      }
    } catch (_) {}
    if (!launched && mounted) {
      TopToastUtil.showError(
        context: context,
        title: 'Unable to open email',
        description: 'Please email support@dinqlabs.com manually.',
      );
    }
  }

  // ─── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // 监听 subscription 变化
    context.watch<UserStore>();

    return Scaffold(
      backgroundColor: ColorUtil.pageBgColor,
      appBar: DefaultAppBar(
        context,
        titleString: 'Plans & Pricing',
        backgroundColor: ColorUtil.pageBgColor,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF171717)),
            )
          : _hasError
          ? _buildErrorState()
          : _buildContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Failed to load pricing',
            style: TextStyle(fontSize: 16, fontFamily: 'Geist'),
          ),
          const SizedBox(height: 16),
          NormalButton(
            onTap: _fetchPricing,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF171717),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(color: Colors.white, fontFamily: 'Geist'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final subscription = context.read<UserStore>().subscription;
    final cancellationMessage = confirmedStoreCancellationMessage(
      cancelAtPeriodEnd: subscription?.cancelAtPeriodEnd ?? false,
      expirationDate: _formatFullDate(subscription?.currentPeriodEnd),
    );
    return Column(
      children: [
        const SizedBox(height: 12),
        if (cancellationMessage != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: StoreCancellationNotice(message: cancellationMessage),
          ),
          const SizedBox(height: 12),
        ],
        // Billing period toggle
        _buildBillingToggle(),
        const SizedBox(height: 20),
        // Plan cards（横向滚动）
        Expanded(child: _buildPlanCarousel()),
        // 底部按钮区域
        _buildBottomSection(),
      ],
    );
  }

  // ─── Billing Toggle ────────────────────────────────────────

  Widget _buildBillingToggle() {
    final isYearly = _billingPeriod == 'yearly';

    return Center(
      child: Container(
        width: 280,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFECECEC),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(4),
        child: Stack(
          children: [
            // 滑动指示器
            AnimatedAlign(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: isYearly
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Container(
                width: (280 - 8) / 2,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            // 按钮
            Row(
              children: [
                // Monthly
                Expanded(
                  child: NormalButton(
                    onTap: () => _setBillingPeriod('monthly'),
                    child: Center(
                      child: Text(
                        'Monthly',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: !isYearly
                              ? const Color(0xFF171717)
                              : const Color(0xFF9CA3AF),
                          fontFamily: 'Geist',
                        ),
                      ),
                    ),
                  ),
                ),
                // Yearly
                Expanded(
                  child: NormalButton(
                    onTap: () => _setBillingPeriod('yearly'),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Yearly',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isYearly
                                  ? const Color(0xFF171717)
                                  : const Color(0xFF9CA3AF),
                              fontFamily: 'Geist',
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1487FA),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '15% OFF',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                                fontFamily: 'Geist',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Plan Carousel ─────────────────────────────────────────

  List<String> get _visiblePlanOrder {
    final currentPlan = context.read<UserStore>().subscription?.plan ?? 'free';
    return visibleSubscriptionBasePlans(
      billingPeriod: _billingPeriod,
      currentPlan: currentPlan,
    );
  }

  void _setBillingPeriod(String billingPeriod) {
    if (_billingPeriod == billingPeriod) return;
    final oldPlans = _visiblePlanOrder;
    final selectedPlan = _currentPage < oldPlans.length
        ? oldPlans[_currentPage]
        : null;
    setState(() {
      _billingPeriod = billingPeriod;
      final newPlans = _visiblePlanOrder;
      final selectedIndex = selectedPlan == null
          ? -1
          : newPlans.indexOf(selectedPlan);
      _currentPage = selectedIndex >= 0
          ? selectedIndex
          : newPlans.indexOf('basic');
    });
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget _buildPlanCarousel() {
    final visiblePlans = _visiblePlanOrder;
    final totalCards = visiblePlans.length + 1;

    return PageView.builder(
      controller: _pageController,
      itemCount: totalCards,
      onPageChanged: (index) => setState(() => _currentPage = index),
      itemBuilder: (context, index) {
        if (index < visiblePlans.length) {
          return _buildPlanCard(visiblePlans[index], index);
        } else {
          return _buildCustomCard(index);
        }
      },
    );
  }

  Widget _buildPlanCard(String plan, int index) {
    final config = kPlanConfig[plan]!;
    final pricingKey = _getPricingKey(plan, _billingPeriod);
    final planData = _pricing?[pricingKey] as Map<String, dynamic>?;

    if (planData == null) return const SizedBox.shrink();

    final priceInCents = (planData['price'] as num?)?.toInt() ?? 0;
    final displayPrice = (priceInCents / 100).round();
    final monthlyDisplayPrice = (plan != 'free' && _billingPeriod == 'yearly')
        ? (displayPrice / 12).round()
        : displayPrice;
    final credits = (planData['monthly_credits'] as num?)?.toInt() ?? 0;
    final features =
        (planData['features'] as List<dynamic>?)?.cast<String>() ?? [];

    // 年付时的原月价（划线价）与 You save 节省额（对齐 web yearlySavings）
    final monthlyPlanData = plan != 'free'
        ? (_pricing?[_getPricingKey(plan, 'monthly')] as Map<String, dynamic>?)
        : null;
    final fullMonthlyRate = monthlyPlanData != null
        ? ((monthlyPlanData['price'] as num?)?.toInt() ?? 0) ~/ 100
        : null;
    final yearlySavings =
        (plan != 'free' &&
            _billingPeriod == 'yearly' &&
            fullMonthlyRate != null)
        ? fullMonthlyRate * 12 - displayPrice
        : 0;

    final badge = plan == 'basic' && _billingPeriod == 'yearly'
        ? 'Recommended'
        : (config.popular ? 'Popular' : null);
    final isFeatured = badge != null;
    final isFocused = _currentPage == index;

    return AnimatedScale(
      scale: isFocused ? 1.0 : 0.95,
      duration: const Duration(milliseconds: 200),
      child: Padding(
        padding: EdgeInsets.only(
          top: isFeatured ? 0 : 32,
          left: 6,
          right: 6,
          bottom: 16,
        ),
        child: isFeatured
            ? _buildPopularCard(
                plan,
                config,
                monthlyDisplayPrice,
                displayPrice,
                credits,
                features,
                fullMonthlyRate,
                yearlySavings,
                badge,
              )
            : _buildRegularCard(
                plan,
                config,
                monthlyDisplayPrice,
                displayPrice,
                credits,
                features,
                fullMonthlyRate,
                yearlySavings,
              ),
      ),
    );
  }

  Widget _buildPopularCard(
    String plan,
    _PlanConfig config,
    int monthlyPrice,
    int yearlyPrice,
    int credits,
    List<String> features,
    int? fullMonthlyRate,
    int yearlySavings,
    String badge,
  ) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 蓝色背景
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1487FA),
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
              ),
              // "Popular" 徽标文字
              Positioned(
                top: 10,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1487FA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        fontFamily: 'Geist',
                      ),
                    ),
                  ),
                ),
              ),
              // 白色卡片
              Positioned(
                top: 36,
                left: 4,
                right: 4,
                bottom: 4,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFF0F0F0)),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: _buildCardContent(
                      plan,
                      config,
                      monthlyPrice,
                      yearlyPrice,
                      credits,
                      features,
                      fullMonthlyRate: fullMonthlyRate,
                      yearlySavings: yearlySavings,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRegularCard(
    String plan,
    _PlanConfig config,
    int monthlyPrice,
    int yearlyPrice,
    int credits,
    List<String> features,
    int? fullMonthlyRate,
    int yearlySavings,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _buildCardContent(
          plan,
          config,
          monthlyPrice,
          yearlyPrice,
          credits,
          features,
          fullMonthlyRate: fullMonthlyRate,
          yearlySavings: yearlySavings,
        ),
      ),
    );
  }

  Widget _buildCardContent(
    String plan,
    _PlanConfig config,
    int monthlyPrice,
    int yearlyPrice,
    int credits,
    List<String> features, {
    int? fullMonthlyRate,
    int yearlySavings = 0,
  }) {
    final isFreePlan = plan == 'free';
    final fullPlan = '${plan}_$_billingPeriod';
    final appleSelectedPrice = !isFreePlan && _usesAppleIap
        ? AppleIapService.instance.loadedPriceDetailsForPlan(fullPlan)
        : null;
    final appleMonthlyPrice =
        !isFreePlan && _usesAppleIap && _billingPeriod == 'yearly'
        ? AppleIapService.instance.loadedPriceDetailsForPlan('${plan}_monthly')
        : null;
    final applePriceDisplay = appleSelectedPrice == null
        ? null
        : buildStorePriceDisplay(
            billingPeriod: _billingPeriod,
            selectedPrice: appleSelectedPrice,
            monthlyPrice: appleMonthlyPrice,
            localeName: Localizations.localeOf(context).toLanguageTag(),
          );
    final storePrice = !isFreePlan && _usesStoreBilling
        ? (_usesAppleIap
              ? appleSelectedPrice?.localizedPrice
              : GooglePlayIapService.instance.priceForPlan(
                  fullPlan,
                ))
        : null;
    final showYearlyExtras = !isFreePlan &&
        _billingPeriod == 'yearly' &&
        (!_usesStoreBilling || applePriceDisplay?.yearlyTotal != null);
    final displayedPrice = _usesAppleIap && !isFreePlan
        ? applePriceDisplay?.primaryPrice ?? 'Not available'
        : (_usesStoreBilling && !isFreePlan
              ? storePrice ?? 'Not available'
              : '\$$monthlyPrice');
    final displayedPeriod = _usesAppleIap
        ? applePriceDisplay?.primaryPeriod
        : (_usesStoreBilling
              ? (_billingPeriod == 'yearly' ? '/year' : '/month')
              : '/month');
    final strikethroughPrice = _usesAppleIap
        ? applePriceDisplay?.strikethroughPrice
        : (fullMonthlyRate == null ? null : '\$$fullMonthlyRate');
    final yearlyTotalLabel = _usesAppleIap
        ? applePriceDisplay?.yearlyTotal
        : '\$${_formatNumber(yearlyPrice)} /year';
    final yearlySavingsLabel = _usesAppleIap
        ? applePriceDisplay?.yearlySavings
        : (yearlySavings > 0
              ? '\$${_formatNumber(yearlySavings)}/year'
              : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Plan header：标题与 You save 标签同一中心线，副标题独占下一行。
        SubscriptionPlanHeader(
          title: kPlanLabel[plan] ?? plan,
          subtitle: config.subtitle,
          savingsLabel: showYearlyExtras && yearlySavingsLabel != null
              ? 'You save $yearlySavingsLabel'
              : null,
        ),
        const SizedBox(height: 20),

        // 年付价格使用三行结构：原月价、折后月均价、年付总价。
        // 避免 US$ / HK$ 等较长本地化币种与周期挤在同一行导致溢出。
        SubscriptionPriceSummary(
          displayedPrice: displayedPrice,
          displayedPeriod: !isFreePlan ? displayedPeriod : null,
          strikethroughPrice: showYearlyExtras ? strikethroughPrice : null,
          yearlyTotalLabel: showYearlyExtras ? yearlyTotalLabel : null,
        ),
        const SizedBox(height: 20),

        // Section header（对齐 web："Free includes:" / "Everything in X, plus:"）
        Text(
          config.sectionHeader,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF171717),
            fontFamily: 'Geist',
          ),
        ),
        const SizedBox(height: 16),

        // Credits 独立展示卡（对齐 web：蓝框 Credits + "{N} Credits /month"，
        // features 里含 credits 的行被过滤，不再混在特性列表里）
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1487FA).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFCCE5FF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Credits',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF171717),
                  fontFamily: 'Geist',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                config.creditsFormat.replaceAll(
                  '{credits}',
                  _formatNumber(credits),
                ),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1487FA),
                  fontFamily: 'Geist',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Features（对齐 web getFeatureList：credits 行已单独展示，此处过滤）
        ...features
            .where((f) => !f.toLowerCase().contains('credits'))
            .map(
              (feature) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.check,
                        size: 18,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: RichText(
                        text: TextSpan(children: _parseBoldText(feature)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  /// 格式化数字，添加千位分隔符 (如 1008 → "1,008")
  String _formatNumber(int number) {
    final str = number.toString();
    if (str.length <= 3) return str;
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write(',');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  // ─── Enterprise Card（对齐 web pricing.enterprise）─────────────

  Widget _buildCustomCard(int index) {
    final isFocused = _currentPage == index;

    return AnimatedScale(
      scale: isFocused ? 1.0 : 0.95,
      duration: const Duration(milliseconds: 200),
      child: Padding(
        padding: const EdgeInsets.only(top: 32, left: 6, right: 6, bottom: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE5E5E5)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const Text(
                  'Enterprise',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF171717),
                    fontFamily: 'Geist',
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Teams / Enterprise Customers',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF9CA3AF),
                    fontFamily: 'Geist',
                  ),
                ),
                const SizedBox(height: 20),

                // Price
                const Text(
                  'Contact us',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF171717),
                    fontFamily: 'Geist',
                  ),
                ),
                const SizedBox(height: 20),

                // Section header
                const Text(
                  'Custom Pricing and Contract',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF171717),
                    fontFamily: 'Geist',
                  ),
                ),
                const SizedBox(height: 16),

                // Credits 蓝框（对齐 web enterprise.customCredits）
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1487FA).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCCE5FF)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Credits',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF171717),
                          fontFamily: 'Geist',
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Custom Credits',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1487FA),
                          fontFamily: 'Geist',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Features（对齐 web ENTERPRISE_FEATURE_KEYS）
                ...[
                  'Custom Shortlist projects',
                  'Custom Talent Radars',
                  'Early access to new features',
                  'Dedicated support + SLA',
                ].map(
                  (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.check,
                            size: 18,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            feature,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF666666),
                              fontFamily: 'Geist',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Bottom Section ────────────────────────────────────────

  Widget _buildBottomSection() {
    final visiblePlans = _visiblePlanOrder;
    final currentPlan = _currentPage < visiblePlans.length
        ? visiblePlans[_currentPage]
        : null;
    final isCustom = _currentPage >= visiblePlans.length;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Upgrade / Contact 按钮
            SizedBox(
              width: double.infinity,
              child: NormalButton(
                onTap: () {
                  if (_getBottomButtonDisabled()) return;
                  if (isCustom) {
                    _handleContactSupport();
                  } else if (currentPlan != null) {
                    _handleSelectPlan(currentPlan);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _getBottomButtonDisabled()
                        ? const Color(0xFF171717).withValues(alpha: 0.5)
                        : const Color(0xFF171717),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: _processingPlan != null
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _getBottomButtonText(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              fontFamily: 'Geist',
                            ),
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Need help?
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Need help? ',
                  style: TextStyle(
                    fontSize: 13,
                    color: ColorUtil.sub3TextColor,
                    fontFamily: 'Geist',
                  ),
                ),
                NormalButton(
                  onTap: _handleContactSupport,
                  child: const Text(
                    'Contact support',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF171717),
                      fontFamily: 'Geist',
                    ),
                  ),
                ),
              ],
            ),
            if (_usesStoreBilling) ...[
              const SizedBox(height: 8),
              NormalButton(
                onTap: _handleRestorePurchases,
                child: const Text(
                  'Restore Purchases',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF171717),
                    fontFamily: 'Geist',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getBottomButtonText() {
    final visiblePlans = _visiblePlanOrder;
    if (_currentPage >= visiblePlans.length) return 'Contact Sales';
    final plan = visiblePlans[_currentPage];
    if (_isCurrentPlan(plan)) return _getButtonText(plan);
    if (!_isPlanAvailable(plan)) return 'Unavailable';
    return _getButtonText(plan);
  }

  bool _getBottomButtonDisabled() {
    final visiblePlans = _visiblePlanOrder;
    if (_currentPage >= visiblePlans.length) return false;
    final plan = visiblePlans[_currentPage];
    return _isButtonDisabled(plan);
  }
}
