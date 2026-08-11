import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/payment_service.dart';
import '../../services/app_update_service.dart';
import '../../services/subscription_pricing_navigation.dart';
import '../../stores/user_store.dart';
import '../../theme/dinq_tokens.dart';
import '../../utils/color_util.dart';
import '../../utils/top_toast_util.dart';
import '../../widgets/common/default_app_bar.dart';
import '../marketing/pricing_page.dart' show kPlanLabel;
import 'credits_subscription_summary.dart';

bool shouldShowOfficialApkCreditControls({
  required bool isWeb,
  required TargetPlatform platform,
  required String channel,
}) => !isWeb && platform == TargetPlatform.android && channel == 'official_apk';

/// My → Available Credits 进入的积分页。对齐 web SubscriptionCard 左图：
/// {Plan} Plan + Upgrade/Get more credits + Available credits + 进度条 +
/// Pay as you go + Membership/Referral 明细 + Usage/Billing 列表。
/// Get more credits / PAYG 开关打开 Pay-as-you-go 管理弹层（对齐 web modal）。
class SettingsCreditsPage extends StatefulWidget {
  const SettingsCreditsPage({super.key});

  @override
  State<SettingsCreditsPage> createState() => _SettingsCreditsPageState();
}

class _SettingsCreditsPageState extends State<SettingsCreditsPage> {
  final _paymentService = PaymentService();

  String _tab = 'usage';
  bool _loadingList = true;
  List<Map<String, dynamic>> _usage = [];
  List<Map<String, dynamic>> _orders = [];
  bool _usageLoaded = false;
  bool _ordersLoaded = false;

  @override
  void initState() {
    super.initState();
    // 刷新订阅（拿最新 credits/referral），并加载 usage 列表
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserStore>().loadSubscription();
      _loadTab();
    });
  }

  Future<void> _loadTab() async {
    final isUsage = _tab == 'usage';
    if ((isUsage && _usageLoaded) || (!isUsage && _ordersLoaded)) return;
    setState(() => _loadingList = true);
    try {
      if (isUsage) {
        final data = await _paymentService.getCreditTransactions();
        final list = (data['transactions'] as List?) ?? [];
        _usage = list
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _usageLoaded = true;
      } else {
        final data = await _paymentService.getOrders();
        final list =
            (data['orders'] as List?) ?? (data['items'] as List?) ?? [];
        _orders = list
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _ordersLoaded = true;
      }
    } catch (_) {
      // 列表加载失败保持空态
    } finally {
      if (mounted) setState(() => _loadingList = false);
    }
  }

  void _switchTab(String tab) {
    if (_tab == tab) return;
    setState(() => _tab = tab);
    _loadTab();
  }

  /// Get more credits / Pay as you go 开关 → PAYG 管理弹层
  /// （对齐 web SubscriptionCard：getMoreCredits 按钮打开 Pay-as-you-go modal）
  Future<void> _openPaygSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PaygSheet(paymentService: _paymentService),
    );
    // 弹层内可能改动了 PAYG 状态，回来后刷新订阅
    if (mounted) context.read<UserStore>().refreshSubscription();
  }

  String _formatDate(String? iso) {
    final d = DateTime.tryParse(iso ?? '');
    if (d == null) return '';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final sub = context.watch<UserStore>().subscription;
    final basePlan = sub?.basePlan ?? 'free';
    final planLabel = kPlanLabel[basePlan] ?? basePlan;
    final billingLabel = subscriptionBillingLabel(sub);
    final renewalLabel = subscriptionRenewalLabel(sub);
    final showCreditPurchaseControls = shouldShowOfficialApkCreditControls(
      isWeb: kIsWeb,
      platform: defaultTargetPlatform,
      channel: distributionChannel,
    );

    // 对齐 web getCreditDisplayParts 的拆分算法
    final available = (sub?.creditsBalance ?? 0).clamp(0, 1 << 31);
    final monthlyTotal = sub?.monthlyCredits ?? 0;
    final referralTotal = sub?.referralCredits ?? 0;
    final referralRemaining = referralTotal < available
        ? referralTotal
        : available;
    final monthlyRemaining = (available - referralRemaining).clamp(
      0,
      monthlyTotal,
    );
    final extraRemaining = (available - referralRemaining - monthlyRemaining)
        .clamp(0, 1 << 31);
    final totalCapacity = monthlyTotal + referralTotal;
    final progress = totalCapacity > 0
        ? (available / totalCapacity).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: DinqTokens.bgPage,
      appBar: DefaultAppBar(context, titleString: 'Manage'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // ── 概览卡（对齐图左）─────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: DinqTokens.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: DinqTokens.borderLL),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '$planLabel Plan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Geist',
                        color: ColorUtil.textColor,
                      ),
                    ),
                    if (billingLabel != null)
                      Text(
                        billingLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          fontFamily: 'Geist',
                          color: Color(0xFF575757),
                        ),
                      ),
                  ],
                ),
                if (renewalLabel != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    renewalLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Geist',
                      color: Color(0xFF575757),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    _pillButton(
                      'Upgrade',
                      filled: false,
                      onTap: () => openSubscriptionPricing(context),
                    ),
                    if (showCreditPurchaseControls) ...[
                      const SizedBox(width: 10),
                      _pillButton(
                        'Get more credits',
                        filled: true,
                        onTap: _openPaygSheet,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          size: 18,
                          color: Color(0xFF171717),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Available credits',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Geist',
                            color: ColorUtil.textColor,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '$available',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Geist',
                        color: ColorUtil.textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFEDEBE6),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF171717),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (showCreditPurchaseControls) ...[
                  // PAYG is web checkout and must not appear in store builds.
                  Row(
                    children: [
                      Switch(
                        value: sub?.paygEnabled ?? false,
                        onChanged: (_) => _openPaygSheet(),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Pay as you go',
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Geist',
                          color: ColorUtil.textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                _detailRow(
                  'Membership Credits (resets monthly)',
                  '$monthlyRemaining/$monthlyTotal',
                ),
                const SizedBox(height: 6),
                _detailRow('Referral credits', '$referralRemaining'),
                if (extraRemaining > 0) ...[
                  const SizedBox(height: 6),
                  _detailRow('Additional credits', '$extraRemaining'),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Usage / Billing tabs ─────────────────────────
          Row(
            children: [
              _tabChip('Usage', 'usage'),
              const SizedBox(width: 8),
              _tabChip('Billing', 'billing'),
            ],
          ),
          const SizedBox(height: 12),
          if (_loadingList)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (_tab == 'usage')
            _usage.isEmpty ? _emptyHint('No usage records yet.') : _usageList()
          else
            _orders.isEmpty
                ? _emptyHint('No billing records yet.')
                : _billingList(),
        ],
      ),
    );
  }

  Widget _pillButton(
    String label, {
    required bool filled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: filled ? ColorUtil.textColor : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: filled ? null : Border.all(color: DinqTokens.borderL),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: 'Geist',
            color: filled ? Colors.white : ColorUtil.textColor,
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontFamily: 'Geist',
              color: Color(0xFF9E9B93),
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontFamily: 'Geist',
            color: Color(0xFF9E9B93),
          ),
        ),
      ],
    );
  }

  Widget _tabChip(String label, String value) {
    final selected = _tab == value;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _switchTab(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? DinqTokens.bgSurface : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            fontFamily: 'Geist',
            color: selected ? ColorUtil.textColor : const Color(0xFF9E9B93),
          ),
        ),
      ),
    );
  }

  Widget _emptyHint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontFamily: 'Geist',
            color: Color(0xFF9E9B93),
          ),
        ),
      ),
    );
  }

  Widget _usageList() {
    return Column(
      children: [
        for (final tx in _usage)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: DinqTokens.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: DinqTokens.borderLL),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (tx['description'] ?? tx['type'] ?? '').toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Geist',
                          color: ColorUtil.textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(tx['created_at']?.toString()),
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'Geist',
                          color: Color(0xFF9E9B93),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  () {
                    final n = tx['amount'];
                    final v = n is int
                        ? n
                        : int.tryParse(n?.toString() ?? '0') ?? 0;
                    return v > 0 ? '+$v' : '$v';
                  }(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Geist',
                    color: Color(0xFF171717),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _billingList() {
    return Column(
      children: [
        for (final order in _orders)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: DinqTokens.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: DinqTokens.borderLL),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDate(
                          (order['paid_at'] ?? order['created_at'])?.toString(),
                        ),
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Geist',
                          color: ColorUtil.textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        (order['status'] ?? '').toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'Geist',
                          color: Color(0xFF9E9B93),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  () {
                    final cents = order['amount'];
                    final v = cents is int
                        ? cents
                        : int.tryParse(cents?.toString() ?? '0') ?? 0;
                    final currency = (order['currency'] ?? 'USD')
                        .toString()
                        .toUpperCase();
                    return '\$${(v / 100).toStringAsFixed(2)} $currency';
                  }(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Geist',
                    color: Color(0xFF171717),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ─── Pay-as-you-go 管理弹层 ─────────────────────────────────────────
//
// 对齐 web SubscriptionCard 的 Pay-as-you-go modal（settings.subscription.payg）：
// 状态徽标 + 描述 + 绑卡/启用/停用按钮 + Monthly cap 输入 + Save limit。
// 绑卡（Set up payment method）走 /payment/payg/setup 返回的 Stripe 页面。
class _PaygSheet extends StatefulWidget {
  const _PaygSheet({required this.paymentService});

  final PaymentService paymentService;

  @override
  State<_PaygSheet> createState() => _PaygSheetState();
}

class _PaygSheetState extends State<_PaygSheet> {
  static const int _defaultLimitCents = 4000; // 对齐 web DEFAULT_PAYG_LIMIT_CENTS

  final TextEditingController _limitController = TextEditingController();

  bool _loading = true;
  bool _updating = false;
  Map<String, dynamic>? _payg;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await widget.paymentService.getPayg();
      if (!mounted) return;
      _payg = data;
      final cents =
          (data['monthly_limit_cents'] as num?)?.toInt() ?? _defaultLimitCents;
      final amount = cents / 100;
      _limitController.text = amount == amount.roundToDouble()
          ? '${amount.round()}'
          : amount.toStringAsFixed(2);
    } catch (_) {
      // 拉取失败保持默认值，仍可发起绑卡
      _limitController.text = '${_defaultLimitCents ~/ 100}';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool get _enabled => _payg?['enabled'] == true;
  String get _status => (_payg?['status'] ?? 'inactive').toString();
  bool get _hasPaymentMethod => _payg?['has_payment_method'] == true;

  /// 无可用卡（未绑卡或上次扣款失败需重新绑卡）→ 走 Stripe setup
  bool get _needsSetup => !_hasPaymentMethod || _status == 'payment_failed';

  /// 对齐 web getPaygStatusKey
  String get _statusLabel {
    if (_enabled && _status == 'active') return 'Active';
    if (_status == 'setup_pending') return 'Setup pending';
    if (_status == 'payment_failed') return 'Payment failed';
    return 'Inactive';
  }

  Color get _statusBg {
    if (_enabled && _status == 'active') return const Color(0xFFF0FDF4);
    if (_status == 'payment_failed') return const Color(0xFFFEF2F2);
    return const Color(0xFFF5F4F0);
  }

  Color get _statusFg {
    if (_enabled && _status == 'active') return const Color(0xFF16A34A);
    if (_status == 'payment_failed') return const Color(0xFFDC2626);
    return const Color(0xFF6B6862);
  }

  /// 解析月度上限（美元 → 分），非法返回 null（对齐 web parseLimitCents）
  int? _parseLimitCents() {
    final amount = double.tryParse(_limitController.text.trim());
    if (amount == null || !amount.isFinite || amount <= 0) {
      TopToastUtil.showError(
        context: context,
        title: 'Invalid monthly cap',
        description: 'Enter a monthly limit greater than \$0.',
      );
      return null;
    }
    return (amount * 100).round();
  }

  /// 绑卡：跳 Stripe 页面，回来后刷新
  Future<void> _handleSetup() async {
    if (_updating) return;
    final cents = _parseLimitCents();
    if (cents == null) return;

    setState(() => _updating = true);
    try {
      final res = await widget.paymentService.setupPayg(
        monthlyLimitCents: cents,
      );
      final url = res['url']?.toString();
      if (!mounted) return;
      if (url != null && url.isNotEmpty) {
        await context.push(
          '/webview',
          extra: {
            'url': url,
            'navTitle': 'Pay-as-you-go',
            'showAppBar': 'true',
          },
        );
        if (mounted) await _load();
      } else {
        TopToastUtil.showError(
          context: context,
          title: 'Setup failed',
          description: 'Unable to start pay-as-you-go setup.',
        );
      }
    } catch (_) {
      if (mounted) {
        TopToastUtil.showError(
          context: context,
          title: 'Setup failed',
          description: 'Unable to start pay-as-you-go setup.',
        );
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  /// 更新开关/上限（对齐 web executePaygUpdate）
  Future<void> _handleUpdate({required bool enabled}) async {
    if (_updating) return;
    final cents = _parseLimitCents();
    if (cents == null) return;

    // 想开启但没有可用卡 → 先绑卡
    if (enabled && _needsSetup) {
      await _handleSetup();
      return;
    }

    setState(() => _updating = true);
    try {
      await widget.paymentService.updatePayg(
        enabled: enabled,
        monthlyLimitCents: cents,
      );
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      TopToastUtil.showSuccess(
        context: context,
        title: enabled ? 'Pay-as-you-go enabled' : 'Pay-as-you-go disabled',
      );
    } catch (_) {
      if (mounted) {
        TopToastUtil.showError(
          context: context,
          title: 'Update failed',
          description: 'Failed to update pay-as-you-go.',
        );
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _handleSaveLimit() async {
    await _handleUpdate(enabled: _enabled);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 拖拽指示条
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD6D3CC),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // 标题 + 关闭
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pay-as-you-go',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Geist',
                      color: Color(0xFF171717),
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(context).pop(),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.close,
                        size: 22,
                        color: Color(0xFF9E9B93),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else ...[
                // 状态徽标
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _statusBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _statusLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Geist',
                      color: _statusFg,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Only applies after membership credits are used. '
                  'Set a monthly cap before enabling.',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Geist',
                    color: Color(0xFF6B6862),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                // 主操作：绑卡 / 启用 / 停用
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _updating
                        ? null
                        : () => _needsSetup
                              ? _handleSetup()
                              : _handleUpdate(enabled: !_enabled),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: _enabled && !_needsSetup
                            ? Colors.white
                            : const Color(0xFF171717),
                        borderRadius: BorderRadius.circular(24),
                        border: _enabled && !_needsSetup
                            ? Border.all(color: const Color(0xFFE5E2DC))
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: _updating
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _enabled && !_needsSetup
                                    ? const Color(0xFF171717)
                                    : Colors.white,
                              ),
                            )
                          : Text(
                              _needsSetup
                                  ? (_status == 'payment_failed'
                                        ? 'Update payment method'
                                        : 'Set up payment method')
                                  : (_enabled ? 'Disable' : 'Enable'),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Geist',
                                color: _enabled && !_needsSetup
                                    ? const Color(0xFF6B6862)
                                    : Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(height: 1, color: const Color(0xFFE5E2DC)),
                const SizedBox(height: 16),
                // Monthly cap 输入 + Save limit
                const Text(
                  'Monthly cap',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Geist',
                    color: Color(0xFF6B6862),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFAFAF8),
                        border: Border(
                          top: BorderSide(color: Color(0xFFE5E2DC)),
                          left: BorderSide(color: Color(0xFFE5E2DC)),
                          bottom: BorderSide(color: Color(0xFFE5E2DC)),
                        ),
                        borderRadius: BorderRadius.horizontal(
                          left: Radius.circular(8),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        '\$',
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Geist',
                          color: Color(0xFF9E9B93),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 120,
                      height: 40,
                      child: TextField(
                        controller: _limitController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'Geist',
                          color: Color(0xFF171717),
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(8),
                            ),
                            borderSide: const BorderSide(
                              color: Color(0xFFE5E2DC),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(8),
                            ),
                            borderSide: const BorderSide(
                              color: Color(0xFFE5E2DC),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(8),
                            ),
                            borderSide: const BorderSide(
                              color: Color(0xFF171717),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: (_updating || _payg == null)
                          ? null
                          : _handleSaveLimit,
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE5E2DC)),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Save limit',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Geist',
                            color: (_updating || _payg == null)
                                ? const Color(0xFFB8B5AE)
                                : const Color(0xFF6B6862),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
