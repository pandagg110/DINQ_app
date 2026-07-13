import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/analytics_service.dart';
import '../../services/payment_service.dart';
import '../../stores/user_store.dart';
import '../../utils/color_util.dart';
import '../../utils/top_toast_util.dart';
import '../../widgets/common/base_page.dart';
import '../../widgets/common/default_app_bar.dart';

// ─── Plan 配置常量 ────────────────────────────────────────────────

const List<String> kPlanOrder = ['free', 'basic', 'pro', 'plus'];

const Map<String, int> kPlanLevel = {
  'free': 0,
  'basic': 1,
  'pro': 2,
  'plus': 3,
};

const Map<String, String> kPlanLabel = {
  'free': 'Free',
  'basic': 'Basic',
  'pro': 'Pro',
  'plus': 'Plus',
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

const Map<String, _PlanConfig> kPlanConfig = {
  'free': _PlanConfig(
    subtitle: 'Personal Experience',
    sectionHeader: 'Free includes:',
    creditsFormat: '{credits} Credits (One-time)',
  ),
  // subtitle 对齐 web PricingModal PLAN_CONFIG
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
  'plus': _PlanConfig(
    subtitle: 'HR/Recruiter',
    sectionHeader: 'Everything in Pro, plus:',
    creditsFormat: '{credits} Credits /month',
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
      spans.add(TextSpan(
        text: part.substring(2, part.length - 2),
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF171717),
          fontSize: 14,
          fontFamily: 'Geist',
        ),
      ));
    } else if (part.isNotEmpty) {
      spans.add(TextSpan(
        text: part,
        style: const TextStyle(
          color: Color(0xFF666666),
          fontSize: 14,
          fontFamily: 'Geist',
        ),
      ));
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

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.82,
      initialPage: _currentPage,
    );
    _fetchPricing();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchPricing() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final data = await _paymentService.getPricing();
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

  // ─── 升级逻辑 ──────────────────────────────────────────────

  bool _canUpgrade(String targetBasePlan) {
    final userStore = context.read<UserStore>();
    if (!userStore.isLoggedIn()) return true;

    final subscription = userStore.subscription;
    final currentBasePlan = subscription?.basePlan ?? 'free';
    final currentBillingPeriod = subscription?.billingPeriod;

    final targetLevel = kPlanLevel[targetBasePlan] ?? 0;
    final currentLevel = kPlanLevel[currentBasePlan] ?? 0;

    if (targetLevel > currentLevel) return true;

    if (targetLevel == currentLevel && targetBasePlan != 'free') {
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
    return basePlan == currentBasePlan && _billingPeriod == currentBillingPeriod;
  }

  String _getButtonText(String basePlan) {
    final userStore = context.read<UserStore>();

    if (!userStore.isLoggedIn()) {
      return basePlan == 'free' ? 'Sign up Free' : 'Upgrade Plan';
    }

    if (_isCurrentPlan(basePlan)) return 'Current Plan';

    final subscription = userStore.subscription;
    final currentBasePlan = subscription?.basePlan ?? 'free';
    final currentBillingPeriod = subscription?.billingPeriod;

    if (basePlan == currentBasePlan &&
        currentBillingPeriod == 'yearly' &&
        _billingPeriod == 'monthly') {
      return 'Yearly Subscriber';
    }

    if (!_canUpgrade(basePlan)) return 'Included';

    return 'Upgrade Plan';
  }

  bool _isButtonDisabled(String basePlan) {
    if (_processingPlan != null) return true;
    if (_isCurrentPlan(basePlan)) return true;
    final userStore = context.read<UserStore>();
    if (userStore.isLoggedIn() && !_canUpgrade(basePlan)) return true;
    return false;
  }

  Future<void> _handleSelectPlan(String basePlan) async {
    final userStore = context.read<UserStore>();

    if (_isCurrentPlan(basePlan)) return;
    if (userStore.isLoggedIn() && !_canUpgrade(basePlan)) return;

    // 未登录 → 跳转登录
    if (!userStore.isLoggedIn()) {
      context.push('/signin');
      return;
    }

    final subscription = userStore.subscription;
    final currentBasePlan = subscription?.basePlan ?? 'free';
    final currentBillingPeriod = subscription?.billingPeriod;
    final isCurrentPlanFree = subscription?.isFree ?? true;

    // 年费用户升级时强制使用年费
    final targetPeriod = (currentBillingPeriod == 'yearly' &&
            (kPlanLevel[basePlan] ?? 0) > (kPlanLevel[currentBasePlan] ?? 0))
        ? 'yearly'
        : _billingPeriod;

    final fullPlan = '${basePlan}_$targetPeriod';

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
        context.push('/webview', extra: {
          'url': url,
          'navTitle': 'Checkout',
          'showAppBar': 'true',
        }).then((_) {
          if (mounted) context.read<UserStore>().refreshSubscription();
        });
      } else if (mounted) {
        TopToastUtil.showError(
          context: context,
          title: 'Unable to start checkout',
          description: 'Please try again later.',
        );
      }
    } catch (_) {
      if (mounted) {
        TopToastUtil.showError(
          context: context,
          title: 'Unable to start checkout',
          description: 'Please try again later.',
        );
      }
    } finally {
      if (mounted) setState(() => _processingPlan = null);
    }
  }

  void _handleContactSupport() async {
    final uri = Uri.parse('mailto:support@dinqlabs.com');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
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
              alignment: isYearly ? Alignment.centerRight : Alignment.centerLeft,
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
                          color: !isYearly ? const Color(0xFF171717) : const Color(0xFF9CA3AF),
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
                              color:
                                  isYearly ? const Color(0xFF171717) : const Color(0xFF9CA3AF),
                              fontFamily: 'Geist',
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
    final monthlyDisplayPrice =
        (plan != 'free' && _billingPeriod == 'yearly') ? (displayPrice / 12).round() : displayPrice;
    final credits = (planData['monthly_credits'] as num?)?.toInt() ?? 0;
    final features = (planData['features'] as List<dynamic>?)?.cast<String>() ?? [];

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
        child: isPopular ? _buildPopularCard(plan, config, monthlyDisplayPrice, displayPrice, credits, features) : _buildRegularCard(plan, config, monthlyDisplayPrice, displayPrice, credits, features),
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
              // "Most popular" 文字
              Positioned(
                top: 10,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1487FA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Most popular',
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
                    child: _buildCardContent(plan, config, monthlyPrice, yearlyPrice, credits, features),
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
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _buildCardContent(plan, config, monthlyPrice, yearlyPrice, credits, features),
      ),
    );
  }

  Widget _buildCardContent(
    String plan,
    _PlanConfig config,
    int monthlyPrice,
    int yearlyPrice,
    int credits,
    List<String> features,
  ) {
    final isFreePlan = plan == 'free';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Plan header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
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
            if (config.popular)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1487FA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Most popular',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    fontFamily: 'Geist',
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),

        // Price
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '\$$monthlyPrice',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Color(0xFF171717),
                fontFamily: 'Geist',
              ),
            ),
            if (!isFreePlan) ...[
              const Text(
                '/month',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF171717),
                  fontFamily: 'Geist',
                ),
              ),
              if (_billingPeriod == 'yearly') ...[
                const SizedBox(width: 12),
                Text(
                  // 对齐 web："$1,008 /year"（无 total）
                  '\$${_formatNumber(yearlyPrice)} /year',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFBDBDBD),
                    fontFamily: 'Geist',
                  ),
                ),
              ],
            ],
          ],
        ),
        const SizedBox(height: 24),

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
                config.creditsFormat
                    .replaceAll('{credits}', _formatNumber(credits)),
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
        const SizedBox(height: 20),

        // Divider
        Container(height: 1, color: const Color(0xFFF0F0F0)),
        const SizedBox(height: 20),

        // Features（对齐 web getFeatureList：credits 行已单独展示，此处过滤）
        ...features
            .where((f) => !f.toLowerCase().contains('credits'))
            .map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.check, size: 18, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RichText(
                      text: TextSpan(children: _parseBoldText(feature)),
                    ),
                  ),
                ],
              ),
            )),
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

  // ─── Custom Enterprise Card ────────────────────────────────

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
                  'Custom',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF171717),
                    fontFamily: 'Geist',
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Large Enterprise/Organization',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF9CA3AF),
                    fontFamily: 'Geist',
                  ),
                ),
                const SizedBox(height: 20),

                // Price
                const Text(
                  'Custom pricing',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF171717),
                    fontFamily: 'Geist',
                  ),
                ),
                const SizedBox(height: 24),

                // Divider
                Container(height: 1, color: const Color(0xFFF0F0F0)),
                const SizedBox(height: 20),

                // Section header
                const Text(
                  'Everything in Plus, plus:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF171717),
                    fontFamily: 'Geist',
                  ),
                ),
                const SizedBox(height: 16),

                // Features
                ...[
                  'Network',
                  'Onboarding and training',
                  'Usage analytics',
                  'Custom integrations',
                  'Dedicated support',
                  'SLA guarantee',
                  'Custom SLA & Contract',
                ].map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(Icons.check, size: 18, color: Color(0xFF6B7280)),
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
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Bottom Section ────────────────────────────────────────

  Widget _buildBottomSection() {
    final currentPlan = _currentPage < kPlanOrder.length ? kPlanOrder[_currentPage] : null;
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
          ],
        ),
      ),
    );
  }

  String _getBottomButtonText() {
    if (_currentPage >= kPlanOrder.length) return 'Contact Sales';
    final plan = kPlanOrder[_currentPage];
    return _getButtonText(plan);
  }

  bool _getBottomButtonDisabled() {
    if (_currentPage >= kPlanOrder.length) return false;
    final plan = kPlanOrder[_currentPage];
    return _isButtonDisabled(plan);
  }
}
