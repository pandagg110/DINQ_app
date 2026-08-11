import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/user_models.dart';
import '../../services/analytics_service.dart';
import '../../services/apple_iap_service.dart';
import '../../services/payment_service.dart';
import '../../services/store_cancellation_flow.dart';
import '../../services/subscription_pricing_navigation.dart';
import '../../stores/user_store.dart';
import '../../utils/color_util.dart';
import '../../utils/top_toast_util.dart';
import '../../widgets/common/base_page.dart';
import '../../widgets/common/common_dialog.dart';
import '../../widgets/common/default_app_bar.dart';
import '../../widgets/marketing/store_cancellation_dialog.dart';

/// 计划样式配置
class PlanStyle {
  final Color backgroundColor;
  final Color textColor;
  final String? icon;

  const PlanStyle({
    required this.backgroundColor,
    required this.textColor,
    this.icon,
  });
}

/// 获取计划显示名称
String getPlanLabel(String basePlan) {
  switch (basePlan) {
    case 'free':
      return 'Free';
    case 'basic':
      return 'Basic';
    case 'pro':
      return 'Pro Plan';
    case 'plus':
      return 'Plus Plan';
    case 'custom':
      return 'Custom Plan';
    default:
      return basePlan;
  }
}

/// 获取计划样式
PlanStyle getPlanStyle(String basePlan) {
  switch (basePlan) {
    case 'free':
      return const PlanStyle(
        backgroundColor: Colors.white,
        textColor: Color(0xFF171717),
      );
    case 'basic':
      return const PlanStyle(
        backgroundColor: Color(0xFFFAF5EB), // 浅棕/奶油色
        textColor: Color(0xFF171717),
        icon: '📒',
      );
    case 'pro':
      return const PlanStyle(
        backgroundColor: Color(0xFFFAF5EB), // 浅棕/金色
        textColor: Color(0xFF171717),
        icon: '📙',
      );
    case 'plus':
      return const PlanStyle(
        backgroundColor: Color(0xFF3D3D3D), // 深灰色
        textColor: Colors.white,
        icon: '👑',
      );
    case 'custom':
      return const PlanStyle(
        backgroundColor: Color(0xFF171717), // 黑色
        textColor: Colors.white,
        icon: '⭐',
      );
    default:
      return const PlanStyle(
        backgroundColor: Colors.white,
        textColor: Color(0xFF171717),
      );
  }
}

class SettingsSubscriptionPage extends StatefulWidget {
  const SettingsSubscriptionPage({super.key});

  @override
  State<SettingsSubscriptionPage> createState() =>
      _SettingsSubscriptionPageState();
}

class _SettingsSubscriptionPageState extends State<SettingsSubscriptionPage> {
  final PaymentService _paymentService = PaymentService();
  bool _isLoadingAutoRenew = false;

  bool get _isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    // 刷新订阅信息
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserStore>().refreshSubscription();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userStore = context.watch<UserStore>();
    final subscription = userStore.subscription;

    return Scaffold(
      appBar: DefaultAppBar(
        context,
        titleString: "Subscriptions",
        backgroundColor: Colors.transparent,
      ),
      backgroundColor: ColorUtil.pageBgColor,
      body: userStore.isLoadingSubscription
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Current Plan 卡片
                  _buildCurrentPlanCard(subscription),
                  if (subscription != null &&
                      subscription.cancelAtPeriodEnd) ...[
                    const SizedBox(height: 12),
                    StoreCancellationNotice(
                      message: confirmedStoreCancellationMessage(
                        cancelAtPeriodEnd: true,
                        expirationDate: _formatDate(
                          subscription.currentPeriodEnd,
                        ),
                      )!,
                    ),
                  ],
                  const SizedBox(height: 12),

                  // Credits 卡片
                  _buildCreditsCard(subscription),
                  const SizedBox(height: 12),

                  if (_isIOS &&
                      subscription != null &&
                      subscription.isAppleChannel) ...[
                    _buildAppleActionButton(
                      label: 'Manage Subscription',
                      onTap: _handleManageAppleSubscription,
                    ),
                    const SizedBox(height: 12),
                    _buildAppleActionButton(
                      label: 'Request a Refund',
                      onTap: _handleRequestRefund,
                    ),
                  ] else if (subscription != null &&
                      subscription.isGooglePlayChannel) ...[
                    _buildAppleActionButton(
                      label: 'Manage Subscription',
                      onTap: _handleManageGooglePlaySubscription,
                    ),
                  ] else if (subscription != null &&
                      !subscription.isFree &&
                      !subscription.cancelAtPeriodEnd)
                    _buildCancelSubscriptionButton(),

                  const SizedBox(height: 16),

                  // Help 链接
                  _buildHelpLink(),
                ],
              ),
            ),
    );
  }

  /// 构建 Current Plan 卡片
  Widget _buildCurrentPlanCard(Subscription? subscription) {
    final basePlan = subscription?.basePlan ?? 'free';
    final billingPeriod = subscription?.billingPeriod;
    final isFree = subscription?.isFree ?? true;
    final currentPeriodEnd = subscription?.currentPeriodEnd;
    final cancelAtPeriodEnd = subscription?.cancelAtPeriodEnd ?? false;

    final planStyle = getPlanStyle(basePlan);
    final planLabel = getPlanLabel(basePlan);

    return Container(
      decoration: BoxDecoration(
        color: planStyle.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5E5), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 计划信息和 Change Plan 按钮
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // 计划名称和周期
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Plan',
                        style: TextStyle(
                          fontSize: 12,
                          color: planStyle.textColor.withOpacity(0.6),
                          fontFamily: 'Geist',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (planStyle.icon != null) ...[
                            Text(
                              planStyle.icon!,
                              style: const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            planLabel,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: planStyle.textColor,
                              fontFamily: 'Geist',
                            ),
                          ),
                          if (billingPeriod != null) ...[
                            const SizedBox(width: 12),
                            Text(
                              billingPeriod == 'yearly'
                                  ? 'Billed annually'
                                  : 'Billed monthly',
                              style: TextStyle(
                                fontSize: 12,
                                color: planStyle.textColor.withOpacity(0.5),
                                fontFamily: 'Geist',
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Change Plan 按钮
                _buildChangePlanButton(isFree, planStyle),
              ],
            ),
          ),

          // Next billing date（非 Free 计划显示）
          if (!isFree && currentPeriodEnd != null) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              height: 1,
              color: planStyle.textColor.withOpacity(0.1),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    cancelAtPeriodEnd ? 'Access until' : 'Next billing date',
                    style: TextStyle(
                      fontSize: 14,
                      color: planStyle.textColor.withOpacity(0.6),
                      fontFamily: 'Geist',
                    ),
                  ),
                  Text(
                    _formatDate(currentPeriodEnd),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: planStyle.textColor,
                      fontFamily: 'Geist',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建 Change Plan 按钮
  Widget _buildChangePlanButton(bool isFree, PlanStyle planStyle) {
    // 判断是否是深色背景
    final isDarkBg = planStyle.backgroundColor.computeLuminance() < 0.5;

    return NormalButton(
      onTap: () => openSubscriptionPricing(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isDarkBg ? Colors.white : const Color(0xFF171717),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bolt,
              size: 16,
              color: isDarkBg ? const Color(0xFF171717) : Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              isFree ? 'Upgrade Plan' : 'Change Plan',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDarkBg ? const Color(0xFF171717) : Colors.white,
                fontFamily: 'Geist',
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建 Credits 卡片
  Widget _buildCreditsCard(Subscription? subscription) {
    final creditBalance = subscription?.creditsBalance ?? 0;
    final monthlyCredits = subscription?.monthlyCredits ?? 3;
    final progressPercent = monthlyCredits > 0
        ? (creditBalance / monthlyCredits)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5E5), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题和数量
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Credits this month',
                style: TextStyle(
                  fontSize: 14,
                  color: ColorUtil.textColor,
                  fontFamily: 'Geist',
                ),
              ),
              Text(
                '$creditBalance / $monthlyCredits remaining',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ColorUtil.textColor,
                  fontFamily: 'Geist',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 进度条
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E5E5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progressPercent.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF171717),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // 提示文字
          Text(
            'Credits reset monthly',
            style: TextStyle(
              fontSize: 12,
              color: ColorUtil.sub3TextColor,
              fontFamily: 'Geist',
            ),
          ),
        ],
      ),
    );
  }

  /// 构建取消订阅按钮
  Widget _buildAppleActionButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return NormalButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E5E5)),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: ColorUtil.sub3TextColor,
              fontFamily: 'Geist',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCancelSubscriptionButton() {
    return NormalButton(
      onTap: _isLoadingAutoRenew ? () {} : _handleCancelSubscription,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E5E5), width: 1),
        ),
        child: Center(
          child: _isLoadingAutoRenew
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  'Cancel Subscription',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: ColorUtil.sub3TextColor,
                    fontFamily: 'Geist',
                  ),
                ),
        ),
      ),
    );
  }

  /// 构建帮助链接
  Widget _buildHelpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Need help? ',
          style: TextStyle(
            fontSize: 12,
            color: ColorUtil.sub3TextColor,
            fontFamily: 'Geist',
          ),
        ),
        NormalButton(
          onTap: _handleContactSupport,
          child: Text(
            'Contact support',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: ColorUtil.textColor,
              fontFamily: 'Geist',
            ),
          ),
        ),
      ],
    );
  }

  /// 格式化日期
  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '—';
    try {
      final date = DateTime.parse(dateStr);
      final months = [
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
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  /// 处理取消订阅
  void _handleCancelSubscription() {
    final subscription = context.read<UserStore>().subscription;
    final currentPeriodEnd = subscription?.currentPeriodEnd;
    final planLabel = getPlanLabel(subscription?.basePlan ?? 'free');

    CommonDialog.showAlert(
      context: context,
      barrierDismissible: true,
      customAlert: _CancelSubscriptionDialog(
        planLabel: planLabel,
        periodEndDate: _formatDate(currentPeriodEnd),
        onKeepSubscription: () => CommonDialog.closeDialog(context),
        onConfirmCancel: () async {
          CommonDialog.closeDialog(context);
          await _executeAutoRenewToggle(false);
        },
      ),
    );
  }

  /// 执行自动续费切换
  Future<void> _executeAutoRenewToggle(bool enable) async {
    if (_isLoadingAutoRenew) return;

    setState(() => _isLoadingAutoRenew = true);

    try {
      final userStore = context.read<UserStore>();
      // 埋点用：取消前的当前计划（取消后刷新可能变化）
      final planBeforeToggle = userStore.subscription?.basePlan ?? 'free';
      await _paymentService.setAutoRenew(autoRenew: enable);
      // 埋点：用户发起且后端确认取消（关闭自动续费）
      if (!enable) {
        AnalyticsService.instance.track(
          'subscription_cancel',
          params: {
            'current_plan': planBeforeToggle,
            'payment_provider': 'stripe',
          },
          activationIntent: 'unknown',
        );
      }
      await userStore.refreshSubscription();

      if (!mounted) return;
      TopToastUtil.showSuccess(
        context: context,
        title: enable ? 'Auto-renewal enabled' : 'Subscription cancelled',
      );
    } catch (e) {
      if (!mounted) return;
      TopToastUtil.showError(
        context: context,
        title: 'Failed to update subscription',
        description: '$e',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingAutoRenew = false);
      }
    }
  }

  Future<void> _handleManageAppleSubscription() async {
    try {
      await AppleIapService.instance.showManageSubscriptions();
    } catch (_) {
      final uri = Uri.parse('https://apps.apple.com/account/subscriptions');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
    if (mounted) await context.read<UserStore>().refreshSubscription();
  }

  Future<void> _handleManageGooglePlaySubscription() async {
    final uri = Uri.parse(
      'https://play.google.com/store/account/subscriptions?package=me.dinq.app',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    if (mounted) await context.read<UserStore>().refreshSubscription();
  }

  Future<void> _handleRequestRefund() async {
    final plan = context.read<UserStore>().subscription?.plan;
    if (plan == null) return;
    try {
      final status = await AppleIapService.instance.beginRefundRequest(plan);
      if (status == 'success' && mounted) {
        TopToastUtil.showInfo(
          context: context,
          title: 'Refund request submitted',
          description: 'Apple will notify you of the result.',
        );
      }
    } catch (_) {
      if (mounted) {
        TopToastUtil.showError(
          context: context,
          title: 'Unable to open refund request',
          description: 'Please try again later.',
        );
      }
    }
  }

  /// 联系支持
  void _handleContactSupport() async {
    final uri = Uri.parse('mailto:support@dinqlabs.com');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

/// 取消订阅确认对话框
class _CancelSubscriptionDialog extends StatelessWidget {
  final String planLabel;
  final String periodEndDate;
  final VoidCallback onKeepSubscription;
  final VoidCallback onConfirmCancel;

  const _CancelSubscriptionDialog({
    required this.planLabel,
    required this.periodEndDate,
    required this.onKeepSubscription,
    required this.onConfirmCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 关闭按钮
            Align(
              alignment: Alignment.topRight,
              child: NormalButton(
                onTap: onKeepSubscription,
                child: const Icon(
                  Icons.close,
                  size: 24,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ),

            // 标题
            const Text(
              'Are you sure you want to cancel your subscription?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF171717),
                fontFamily: 'Geist',
                decoration: TextDecoration.underline,
              ),
            ),
            const SizedBox(height: 16),

            // 描述
            Text(
              'Your $planLabel features will remain active until $periodEndDate. After this date, you will no longer be charged and your account will revert to the Free Plan.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                fontFamily: 'Geist',
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // Keep Subscription 按钮
            SizedBox(
              width: double.infinity,
              child: NormalButton(
                onTap: onKeepSubscription,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF171717),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'Keep Subscription',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        fontFamily: 'Geist',
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Confirm Cancellation 按钮
            SizedBox(
              width: double.infinity,
              child: NormalButton(
                onTap: onConfirmCancel,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E5E5)),
                  ),
                  child: const Center(
                    child: Text(
                      'Confirm Cancellation',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF171717),
                        fontFamily: 'Geist',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
