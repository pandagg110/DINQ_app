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
import '../../stores/user_store.dart';
import '../../utils/color_util.dart';
import '../../utils/top_toast_util.dart';
import '../../widgets/common/base_page.dart';
import '../../widgets/common/default_app_bar.dart';
import '../../widgets/marketing/contact_support_dialog.dart';

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

// ─── PricingPage ─────────────────────────────────────────────────

class PricingPage extends StatefulWidget {
  const PricingPage({super.key});

  @override
  State<PricingPage> createState() => _PricingPageState();
}

class _PricingPageState extends State<PricingPage> {
  final PaymentService _paymentService = PaymentService();

  Map<String, dynamic>? _pricing;
  bool _isLoading = true;
  bool _hasError = false;
  String _billingPeriod = 'yearly';
  String? _processingPlan;

  late PageController _pageController;
  int _currentPage = 2; // 默认聚焦 Pro

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
  void dispose() {
    if (_isIOS) AppleIapService.instance.onPurchaseFinished = null;
    if (_usesGooglePlay) {
      GooglePlayIapService.instance.onPurchaseFinished = null;
    }
    _pageController.dispose();
    super.dispose();
  }

  void _onIapPurchaseFinished(bool success, String? message) {
    if (!mounted) return;
    setState(() => _processingPlan = null);
    if (success) {
      TopToastUtil.showSuccess(
        context: context,
        title: 'Subscription activated',
        description: 'Your plan has been updated.',
      );
    } else if (message != null) {
      TopToastUtil.showError(
        context: context,
        title: 'Purchase failed',
        description: message,
      );
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

  // ─── 换购逻辑（对齐 web canChangePlan：升级/降级均放开）───────

  bool _canChangePlan(String targetBasePlan) {
    final userStore = context.read<UserStore>();
    if (!userStore.isLoggedIn()) return true;

    final subscription = userStore.subscription;
    final currentBasePlan = subscription?.basePlan ?? 'free';
    final currentBillingPeriod = subscription?.billingPeriod;

    final targetLevel = kPlanLevel[targetBasePlan] ?? 0;
    final currentLevel = kPlanLevel[currentBasePlan] ?? 0;

    // 升级或降级都允许
    if (targetLevel != currentLevel) return true;

    // 同级别付费计划：仅允许月付 → 年付
    if (targetBasePlan != 'free') {
      return currentBillingPeriod == 'monthly' && _billingPeriod == 'yearly';
    }

    return false;
  }

  bool _isCurrentPlan(String basePlan) {
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

    if (!userStore.isLoggedIn()) {
      return basePlan == 'free' ? 'Get started' : 'Subscribe';
    }

    if (_isCurrentPlan(basePlan)) return 'Current plan';

    final subscription = userStore.subscription;
    final isCurrentPlanFree = subscription?.isFree ?? true;
    final currentBasePlan = subscription?.basePlan ?? 'free';
    final currentBillingPeriod = subscription?.billingPeriod;

    if (basePlan == 'free') return 'Downgrade to Free';
    if (isCurrentPlanFree) return 'Subscribe';

    if (basePlan == currentBasePlan &&
        currentBillingPeriod == 'yearly' &&
        _billingPeriod == 'monthly') {
      return 'Yearly subscriber';
    }

    final targetLevel = kPlanLevel[basePlan] ?? 0;
    final currentLevel = kPlanLevel[currentBasePlan] ?? 0;
    return targetLevel < currentLevel ? 'Downgrade' : 'Upgrade';
  }

  bool _isButtonDisabled(String basePlan) {
    if (_processingPlan != null) return true;
    if (!_isPlanAvailable(basePlan)) return true;
    if (_isCurrentPlan(basePlan)) return true;
    final userStore = context.read<UserStore>();
    if (userStore.isLoggedIn() && !_canChangePlan(basePlan)) return true;
    return false;
  }

  bool _isPlanAvailable(String basePlan) {
    if (basePlan == 'free' || !_usesStoreBilling) return true;
    final fullPlan = '${basePlan}_$_billingPeriod';
    return _usesAppleIap
        ? AppleIapService.instance.supportsPlan(fullPlan)
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

    // 降级到 Free：确认后关闭自动续费（对齐 web downgradeDialog + setAutoRenew）
    if (basePlan == 'free') {
      if (_isIOS && userStore.subscription?.isAppleChannel == true) {
        try {
          await AppleIapService.instance.showManageSubscriptions();
        } catch (_) {
          final uri = Uri.parse('https://apps.apple.com/account/subscriptions');
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
        return;
      }
      if (_usesGooglePlay &&
          userStore.subscription?.isGooglePlayChannel == true) {
        await _openGooglePlaySubscriptions();
        return;
      }
      await _handleDowngradeToFree();
      return;
    }

    final subscription = userStore.subscription;
    final currentBasePlan = subscription?.basePlan ?? 'free';
    final currentBillingPeriod = subscription?.billingPeriod;
    final isCurrentPlanFree = subscription?.isFree ?? true;

    // 年费用户升级时强制使用年费
    final targetPeriod =
        (currentBillingPeriod == 'yearly' &&
            (kPlanLevel[basePlan] ?? 0) > (kPlanLevel[currentBasePlan] ?? 0))
        ? 'yearly'
        : _billingPeriod;

    final fullPlan = '${basePlan}_$targetPeriod';

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
      TopToastUtil.showError(
        context: context,
        title: 'Subscription managed elsewhere',
        description:
            'Manage this subscription through the store where you purchased it.',
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
            'billing_period': targetPeriod,
            'payment_provider': 'stripe',
          },
          activationIntent: 'unknown',
        );
        AnalyticsService.instance.markCheckoutStarted(
          targetPlan: basePlan,
          billingPeriod: targetPeriod,
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

  Future<void> _handleAppleCheckout(String fullPlan, String basePlan) async {
    final subscription = context.read<UserStore>().subscription;
    final isCurrentPlanFree = subscription?.isFree ?? true;

    if (!isCurrentPlanFree && !(subscription?.isAppleChannel ?? false)) {
      TopToastUtil.showError(
        context: context,
        title: 'Subscription managed elsewhere',
        description:
            'Your current plan was purchased outside the App Store. Manage it where you subscribed.',
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
      TopToastUtil.showError(
        context: context,
        title: 'Subscription managed elsewhere',
        description:
            'Your current plan was purchased outside Google Play. Manage it where you subscribed.',
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

  Future<void> _openGooglePlaySubscriptions() async {
    final uri = Uri.parse(
      'https://play.google.com/store/account/subscriptions?package=me.dinq.app',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    if (mounted) await context.read<UserStore>().refreshSubscription();
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
    return Column(
      children: [
        const SizedBox(height: 12),
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
                    onTap: () => setState(() => _billingPeriod = 'monthly'),
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
                    onTap: () => setState(() => _billingPeriod = 'yearly'),
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

  Widget _buildPlanCarousel() {
    // 4 plans + 1 custom = 5 cards
    final totalCards = kPlanOrder.length + 1;

    return PageView.builder(
      controller: _pageController,
      itemCount: totalCards,
      onPageChanged: (index) => setState(() => _currentPage = index),
      itemBuilder: (context, index) {
        if (index < kPlanOrder.length) {
          return _buildPlanCard(kPlanOrder[index], index);
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

    final isPopular = config.popular;
    final isFocused = _currentPage == index;

    return AnimatedScale(
      scale: isFocused ? 1.0 : 0.95,
      duration: const Duration(milliseconds: 200),
      child: Padding(
        padding: EdgeInsets.only(
          top: isPopular ? 0 : 32,
          left: 6,
          right: 6,
          bottom: 16,
        ),
        child: isPopular
            ? _buildPopularCard(
                plan,
                config,
                monthlyDisplayPrice,
                displayPrice,
                credits,
                features,
                fullMonthlyRate,
                yearlySavings,
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
                    child: const Text(
                      // 对齐 web pricing.badge.popular
                      'Popular',
                      style: TextStyle(
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
    final storePrice = !isFreePlan && _usesStoreBilling
        ? (_usesAppleIap
              ? AppleIapService.instance.priceForPlan('${plan}_$_billingPeriod')
              : GooglePlayIapService.instance.priceForPlan(
                  '${plan}_$_billingPeriod',
                ))
        : null;
    final showYearlyExtras =
        !isFreePlan && !_usesStoreBilling && _billingPeriod == 'yearly';
    final displayedPrice = _usesStoreBilling && !isFreePlan
        ? (storePrice ?? 'Unavailable')
        : '\$$monthlyPrice';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Plan header：标题 + You save 节省标签（对齐 web savingsLabel）
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kPlanLabel[plan] ?? plan,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF171717),
                      fontFamily: 'Geist',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    config.subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF9CA3AF),
                      fontFamily: 'Geist',
                    ),
                  ),
                ],
              ),
            ),
            if (showYearlyExtras && yearlySavings > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                      'You save \$${_formatNumber(yearlySavings)}/year',
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
          ],
        ),
        const SizedBox(height: 20),

        // Price：年付时先展示划线原月价（对齐 web）
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            if (showYearlyExtras && fullMonthlyRate != null) ...[
              Text(
                '\$$fullMonthlyRate',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF9E9B93),
                  decoration: TextDecoration.lineThrough,
                  decorationColor: Color(0xFF9E9B93),
                  fontFamily: 'Geist',
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              displayedPrice,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Color(0xFF171717),
                fontFamily: 'Geist',
              ),
            ),
            if (!isFreePlan && (!_usesStoreBilling || storePrice != null))
              Text(
                _usesStoreBilling
                    ? (_billingPeriod == 'yearly' ? '/year' : '/month')
                    : '/month',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF171717),
                  fontFamily: 'Geist',
                ),
              ),
          ],
        ),
        if (showYearlyExtras) ...[
          const SizedBox(height: 4),
          Text(
            // 对齐 web priceSuffix.perYearTotal："$1,008 /year"
            '\$${_formatNumber(yearlyPrice)} /year',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0x4D303030),
              fontFamily: 'Geist',
            ),
          ),
        ],
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
    final currentPlan = _currentPage < kPlanOrder.length
        ? kPlanOrder[_currentPage]
        : null;
    final isCustom = _currentPage >= kPlanOrder.length;

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
                        ? const Color(0xFF171717).withOpacity(0.5)
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
    if (_currentPage >= kPlanOrder.length) return 'Contact Sales';
    final plan = kPlanOrder[_currentPage];
    if (!_isPlanAvailable(plan)) return 'Unavailable';
    return _getButtonText(plan);
  }

  bool _getBottomButtonDisabled() {
    if (_currentPage >= kPlanOrder.length) return false;
    final plan = kPlanOrder[_currentPage];
    return _isButtonDisabled(plan);
  }
}
