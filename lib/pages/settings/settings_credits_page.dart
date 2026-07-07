import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/payment_service.dart';
import '../../stores/user_store.dart';
import '../../theme/dinq_tokens.dart';
import '../../utils/color_util.dart';
import '../../utils/top_toast_util.dart';
import '../../widgets/common/default_app_bar.dart';
import '../marketing/pricing_page.dart' show kPlanLabel;

/// My → Available Credits 进入的积分页。对齐 web SubscriptionCard 左图：
/// {Plan} Plan + Upgrade/Get more credits + Available credits + 进度条 +
/// Pay as you go(只读) + Membership/Referral 明细 + Usage/Billing 列表。
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
        final list = (data['orders'] as List?) ?? (data['items'] as List?) ?? [];
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

  String _formatDate(String? iso) {
    final d = DateTime.tryParse(iso ?? '');
    if (d == null) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final sub = context.watch<UserStore>().subscription;
    final basePlan = sub?.basePlan ?? 'free';
    final planLabel = kPlanLabel[basePlan] ?? basePlan;

    // 对齐 web getCreditDisplayParts 的拆分算法
    final available = (sub?.creditsBalance ?? 0).clamp(0, 1 << 31);
    final monthlyTotal = sub?.monthlyCredits ?? 0;
    final referralTotal = sub?.referralCredits ?? 0;
    final referralRemaining =
        referralTotal < available ? referralTotal : available;
    final monthlyRemaining = (available - referralRemaining)
        .clamp(0, monthlyTotal);
    final extraRemaining =
        (available - referralRemaining - monthlyRemaining).clamp(0, 1 << 31);
    final totalCapacity = monthlyTotal + referralTotal;
    final progress = totalCapacity > 0
        ? (available / totalCapacity).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: DinqTokens.bgPage,
      appBar: DefaultAppBar(context, titleString: 'Credits'),
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
                Text(
                  '$planLabel Plan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Geist',
                    color: ColorUtil.textColor,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _pillButton(
                      'Upgrade',
                      filled: false,
                      onTap: () => context.push('/pricing'),
                    ),
                    const SizedBox(width: 10),
                    _pillButton(
                      'Get more credits',
                      filled: true,
                      onTap: () => context.push('/pricing'),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome,
                            size: 18, color: Color(0xFF171717)),
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
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Color(0xFF171717)),
                  ),
                ),
                const SizedBox(height: 16),
                // Pay as you go：启用/绑卡需 Stripe 网页流程，app 只读展示
                Row(
                  children: [
                    Switch(
                      value: sub?.paygEnabled ?? false,
                      onChanged: (_) {
                        TopToastUtil.showError(
                          context: context,
                          title: 'Manage on web',
                          description:
                              'Pay-as-you-go setup is available on dinq.me.',
                        );
                      },
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

  Widget _pillButton(String label,
      {required bool filled, required VoidCallback onTap}) {
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
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                        _formatDate((order['paid_at'] ?? order['created_at'])
                            ?.toString()),
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
                    final currency =
                        (order['currency'] ?? 'USD').toString().toUpperCase();
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
