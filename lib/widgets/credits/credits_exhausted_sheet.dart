import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/user_models.dart';
import '../../services/payment_service.dart';
import '../../stores/user_store.dart';
import '../../utils/top_toast_util.dart';
import 'credits_sheet_icons.dart';

/// 触发场景，对齐 Web `CreditsExhaustedReason`。
/// 注：当前 Web `CreditsExhaustedModal` 文案按套餐分流，不按 reason 分流；
/// reason 仍保留以兼容调用方（search / email）。
enum CreditsExhaustedReason { search, email }

const _defaultPaygLimitCents = 4000;
const _salesEmail = 'support@dinqlabs.com';

/// 对齐 `.example/DINQ_client-main` `CreditsExhaustedModal.tsx`。
/// 按套餐（free / basic / pro / enterprise）+ PAYG 状态展示不同文案与操作。
Future<void> showCreditsExhaustedSheet(
  BuildContext context, {
  CreditsExhaustedReason reason = CreditsExhaustedReason.search,
}) {
  final userStore = context.read<UserStore>();
  unawaited(userStore.refreshSubscription());

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (ctx) => CreditsExhaustedSheet(reason: reason),
  );
}

class CreditsExhaustedSheet extends StatefulWidget {
  const CreditsExhaustedSheet({super.key, required this.reason});

  final CreditsExhaustedReason reason;

  @override
  State<CreditsExhaustedSheet> createState() => _CreditsExhaustedSheetState();
}

class _CreditsExhaustedSheetState extends State<CreditsExhaustedSheet> {
  static const _ink = Color(0xFF2A2826);
  static const _muted = Color(0xFF6B6862);
  static const _sheetBg = Color(0xFFFCFBF9);

  final _paymentService = PaymentService();
  final _limitController = TextEditingController();
  bool _paygUpdating = false;
  int? _syncedLimitCents;

  @override
  void initState() {
    super.initState();
    _syncLimitFromSubscription(context.read<UserStore>().subscription?.payg);
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  void _syncLimitFromSubscription(PaygSettings? payg) {
    final cents = payg?.monthlyLimitCents ?? _defaultPaygLimitCents;
    if (_syncedLimitCents == cents) return;
    _syncedLimitCents = cents;
    final amount = cents / 100;
    _limitController.text = amount == amount.roundToDouble()
        ? '${amount.round()}'
        : amount.toStringAsFixed(2);
  }

  String _planText(CreditsPlanAudience audience) {
    switch (audience) {
      case CreditsPlanAudience.enterprise:
        return 'Contact sales or review usage details.';
      case CreditsPlanAudience.pro:
        return 'Set up Pay-as-you-go to continue, or contact sales.';
      case CreditsPlanAudience.basic:
        return 'Set up Pay-as-you-go to continue, or upgrade to Pro.';
      case CreditsPlanAudience.free:
        return 'Upgrade for more credits, or set up Pay-as-you-go.';
    }
  }

  String _paygStatusText(PaygAction action, int paygLimitCents) {
    switch (action) {
      case PaygAction.bindCard:
        return 'Pay only for the additional credits you use.';
      case PaygAction.enable:
        return 'A payment method is saved. Enable Pay-as-you-go to continue.';
      case PaygAction.updatePaymentMethod:
        return 'The last Pay-as-you-go payment failed. Update the card before continuing.';
      case PaygAction.increaseLimit:
        return 'Your Pay-as-you-go monthly cap (${_formatCurrency(paygLimitCents)}) has been reached.';
      case PaygAction.manage:
        return 'Pay-as-you-go is enabled. Review settings if this message keeps appearing.';
    }
  }

  String _paygButtonLabel(PaygAction action) {
    switch (action) {
      case PaygAction.bindCard:
        return 'Set up';
      case PaygAction.enable:
        return 'Enable PAYG';
      case PaygAction.updatePaymentMethod:
        return 'Update payment method';
      case PaygAction.increaseLimit:
        return 'Increase monthly limit';
      case PaygAction.manage:
        return 'Manage Pay-as-you-go';
    }
  }

  String _paygButtonIcon(PaygAction action) {
    switch (action) {
      case PaygAction.bindCard:
      case PaygAction.updatePaymentMethod:
        return CreditsSheetIcons.creditCard;
      case PaygAction.enable:
        return CreditsSheetIcons.power;
      case PaygAction.increaseLimit:
      case PaygAction.manage:
        return CreditsSheetIcons.adjustments;
    }
  }

  List<_SheetAction> _resolveActions(CreditsPlanAudience audience) {
    switch (audience) {
      case CreditsPlanAudience.enterprise:
        return [
          _SheetAction(
            label: 'Contact sales',
            icon: CreditsSheetIcons.chatBubble,
            onTap: _openContactSales,
          ),
          _SheetAction(
            label: 'View usage',
            onTap: _openUsage,
          ),
        ];
      case CreditsPlanAudience.pro:
        return [
          _SheetAction(
            label: 'Contact sales',
            icon: CreditsSheetIcons.chatBubble,
            onTap: _openContactSales,
          ),
          _SheetAction(
            label: 'Invite friends',
            icon: CreditsSheetIcons.userPlus,
            onTap: _openInvite,
          ),
        ];
      case CreditsPlanAudience.basic:
        return [
          _SheetAction(
            label: 'Upgrade to Pro',
            icon: CreditsSheetIcons.bolt,
            onTap: _openUpgrade,
          ),
          _SheetAction(
            label: 'Invite friends',
            icon: CreditsSheetIcons.userPlus,
            onTap: _openInvite,
          ),
        ];
      case CreditsPlanAudience.free:
        return [
          _SheetAction(
            label: 'Upgrade',
            icon: CreditsSheetIcons.bolt,
            onTap: _openUpgrade,
          ),
          _SheetAction(
            label: 'Invite friends',
            icon: CreditsSheetIcons.userPlus,
            onTap: _openInvite,
          ),
        ];
    }
  }

  void _closeThen(VoidCallback action) {
    Navigator.pop(context);
    action();
  }

  void _openUpgrade() => _closeThen(() => context.push('/pricing'));

  void _openUsage() => _closeThen(() => context.push('/settings/credits'));

  void _openInvite() => _closeThen(() => context.push('/me/invite'));

  Future<void> _openContactSales() async {
    Navigator.pop(context);
    final uri = Uri(
      scheme: 'mailto',
      path: _salesEmail,
      queryParameters: {'subject': 'DINQ sales inquiry'},
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      context.push('/pricing');
    }
  }

  int? _parseLimitCents() {
    final amount = double.tryParse(_limitController.text.trim());
    if (amount == null || !amount.isFinite || amount <= 0) {
      TopToastUtil.showError(
        context: context,
        title: 'Enter a monthly limit above \$0.',
      );
      return null;
    }
    return (amount * 100).round();
  }

  Future<void> _handlePaygAction(PaygAction action, int currentLimitCents) async {
    if (_paygUpdating) return;

    if (action == PaygAction.manage) {
      _openUsage();
      return;
    }

    if (action == PaygAction.increaseLimit) {
      final monthlyLimitCents = _parseLimitCents();
      if (monthlyLimitCents == null) return;
      if (monthlyLimitCents <= currentLimitCents) {
        TopToastUtil.showError(
          context: context,
          title: 'Enter an amount above the current monthly cap.',
        );
        return;
      }
      setState(() => _paygUpdating = true);
      try {
        await _paymentService.updatePayg(
          enabled: true,
          monthlyLimitCents: monthlyLimitCents,
        );
        if (!mounted) return;
        await context.read<UserStore>().refreshSubscription();
        if (!mounted) return;
        TopToastUtil.showSuccess(
          context: context,
          title: 'Pay-as-you-go limit updated',
        );
        Navigator.pop(context);
      } catch (_) {
        if (!mounted) return;
        TopToastUtil.showError(
          context: context,
          title: 'Could not update Pay-as-you-go. Please try again.',
        );
      } finally {
        if (mounted) setState(() => _paygUpdating = false);
      }
      return;
    }

    setState(() => _paygUpdating = true);
    try {
      if (action == PaygAction.bindCard ||
          action == PaygAction.updatePaymentMethod) {
        final res = await _paymentService.setupPayg(
          monthlyLimitCents: currentLimitCents,
        );
        final url = res['url']?.toString();
        if (!mounted) return;
        if (url == null || url.isEmpty) {
          TopToastUtil.showError(
            context: context,
            title: 'Could not update Pay-as-you-go. Please try again.',
          );
          return;
        }
        Navigator.pop(context);
        await context.push('/webview', extra: {
          'url': url,
          'navTitle': 'Pay-as-you-go',
          'showAppBar': 'true',
        });
        return;
      }

      await _paymentService.updatePayg(
        enabled: true,
        monthlyLimitCents: currentLimitCents,
      );
      if (!mounted) return;
      await context.read<UserStore>().refreshSubscription();
      if (!mounted) return;
      TopToastUtil.showSuccess(
        context: context,
        title: 'Pay-as-you-go enabled',
      );
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      TopToastUtil.showError(
        context: context,
        title: 'Could not update Pay-as-you-go. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _paygUpdating = false);
    }
  }

  static String _formatCurrency(int cents) {
    final amount = cents / 100;
    if (amount == amount.roundToDouble()) {
      return '\$${amount.toInt()}';
    }
    return '\$${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final subscription = context.watch<UserStore>().subscription;
    final audience = creditsPlanAudience(subscription?.plan);
    final payg = subscription?.payg;
    final paygAction = resolvePaygAction(payg);
    final paygLimitCents =
        (payg?.monthlyLimitCents ?? 0) > 0
            ? payg!.monthlyLimitCents
            : _defaultPaygLimitCents;
    final actions = _resolveActions(audience);
    final nextLimit =
        (payg?.monthlyLimitCents ?? 0) > 0
            ? payg!.monthlyLimitCents
            : _defaultPaygLimitCents;
    if (_syncedLimitCents != nextLimit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncLimitFromSubscription(payg);
      });
    }

    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        decoration: const BoxDecoration(
          color: _sheetBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Color(0x2E000000),
              offset: Offset(0, -18),
              blurRadius: 48,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 对齐 Web AdaptiveModal 移动端 BottomSheet header
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFECE9E2)),
                ),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Out of credits',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF171717),
                        height: 1.4,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const CreditsSheetSvgIcon(
                      CreditsSheetIcons.close,
                      size: 18,
                      color: Color(0xFF8A8880),
                    ),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                // 对齐 Web 移动端：px-5 pb-4 pt-5 + gap-3
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _planText(audience),
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: _ink,
                      ),
                    ),
                    if (audience != CreditsPlanAudience.enterprise) ...[
                      const SizedBox(height: 4),
                      const Text(
                        'You can also invite friends to earn free credits.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: _muted,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _PaygCard(
                        title: 'Pay-as-you-go',
                        statusText: _paygStatusText(paygAction, paygLimitCents),
                        actionLabel: _paygButtonLabel(paygAction),
                        actionIcon: _paygButtonIcon(paygAction),
                        loading: _paygUpdating,
                        showLimitInput: paygAction == PaygAction.increaseLimit,
                        limitController: _limitController,
                        onPaygTap: () =>
                            _handlePaygAction(paygAction, paygLimitCents),
                      ),
                    ],
                    const SizedBox(height: 12),
                    // 对齐 Web 移动端：grid-cols-1，按钮纵向排列
                    for (var i = 0; i < actions.length; i++) ...[
                      if (i > 0) const SizedBox(height: 8),
                      _SheetButton(
                        label: actions[i].label,
                        icon: actions[i].icon,
                        primary: i == 0,
                        onTap: actions[i].onTap,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetAction {
  const _SheetAction({
    required this.label,
    required this.onTap,
    this.icon,
  });

  final String label;
  final String? icon;
  final VoidCallback onTap;
}

class _PaygCard extends StatelessWidget {
  const _PaygCard({
    required this.title,
    required this.statusText,
    required this.actionLabel,
    required this.actionIcon,
    required this.onPaygTap,
    required this.limitController,
    this.loading = false,
    this.showLimitInput = false,
  });

  final String title;
  final String statusText;
  final String actionLabel;
  final String actionIcon;
  final VoidCallback onPaygTap;
  final TextEditingController limitController;
  final bool loading;
  final bool showLimitInput;

  static const _ink = Color(0xFF2A2826);
  static const _muted = Color(0xFF6B6862);
  static const _line = Color(0xFFE5E2DC);
  static const _fieldBg = Color(0xFFFAFAF8);
  static const _placeholder = Color(0xFF9E9B93);

  @override
  Widget build(BuildContext context) {
    final actionButton = _PaygInlineButton(
      label: actionLabel,
      icon: actionIcon,
      loading: loading,
      onTap: onPaygTap,
      fullWidth: true,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(8),
      ),
      // 对齐 Web 移动端：flex-col gap-2（文案在上，按钮在下）
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _ink,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            statusText,
            style: const TextStyle(
              fontSize: 12,
              height: 1.4,
              color: _muted,
            ),
          ),
          if (showLimitInput) ...[
            const SizedBox(height: 12),
            const Text(
              'Monthly cap',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _muted,
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 36,
              child: Row(
                children: [
                  Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: _fieldBg,
                      border: Border(
                        top: BorderSide(color: _line),
                        left: BorderSide(color: _line),
                        bottom: BorderSide(color: _line),
                      ),
                      borderRadius: BorderRadius.horizontal(
                        left: Radius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '\$',
                      style: TextStyle(
                        fontSize: 14,
                        color: _placeholder,
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: limitController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        color: _ink,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.horizontal(
                            right: Radius.circular(8),
                          ),
                          borderSide: BorderSide(color: _line),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.horizontal(
                            right: Radius.circular(8),
                          ),
                          borderSide: BorderSide(color: _line),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.horizontal(
                            right: Radius.circular(8),
                          ),
                          borderSide: BorderSide(color: _ink),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          actionButton,
        ],
      ),
    );
  }
}

class _PaygInlineButton extends StatelessWidget {
  const _PaygInlineButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.loading = false,
    this.fullWidth = false,
  });

  final String label;
  final String icon;
  final VoidCallback onTap;
  final bool loading;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: fullWidth ? double.infinity : null,
          constraints: const BoxConstraints(minHeight: 36),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E2DC)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF2A2826),
                  ),
                )
              else
                CreditsSheetSvgIcon(
                  icon,
                  size: 14,
                  color: const Color(0xFF2A2826),
                ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2A2826),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  const _SheetButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.primary = false,
  });

  final String label;
  final String? icon;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final fg = primary ? Colors.white : const Color(0xFF2A2826);
    return Material(
      color: primary ? const Color(0xFF2A2826) : Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: primary
                ? null
                : Border.all(color: const Color(0xFFE5E2DC)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                CreditsSheetSvgIcon(icon!, size: 16, color: fg),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: fg,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
