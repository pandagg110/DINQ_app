import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/user_models.dart';
import '../../stores/user_store.dart';
import 'credits_sheet_icons.dart';

/// 触发场景，对齐 Web `CreditsExhaustedReason`。
enum CreditsExhaustedReason { search, email }

/// 对齐 `.example/tanchuang_1` + Web `CreditsExhaustedModal.tsx`。
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

class CreditsExhaustedSheet extends StatelessWidget {
  const CreditsExhaustedSheet({super.key, required this.reason});

  final CreditsExhaustedReason reason;

  static const _ink = Color(0xFF111827);
  static const _body = Color(0xFF1F2937);
  static const _muted = Color(0xFF6B7280);
  static const _line = Color(0xFFE5E7EB);
  static const _cardBg = Color(0xFFF9FAFB);

  @override
  Widget build(BuildContext context) {
    final subscription = context.watch<UserStore>().subscription;
    final audience = creditsPlanAudience(subscription?.plan);
    final payg = subscription?.payg;
    final paygAction = resolvePaygAction(payg);
    final copy = _resolveCopy(audience, paygAction, payg);
    final actions = _resolveActions(audience);

    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
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
            const SizedBox(height: 12),
            Container(
              width: 48,
              height: 6,
              decoration: BoxDecoration(
                color: const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Out of credits',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: _ink,
                        height: 1.4,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const CreditsSheetSvgIcon(
                      CreditsSheetIcons.close,
                      size: 20,
                      color: Color(0xFF9CA3AF),
                    ),
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      copy.introMain,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: _body,
                      ),
                    ),
                    if (copy.introSub != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        copy.introSub!,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: _muted,
                        ),
                      ),
                    ],
                    if (audience != CreditsPlanAudience.enterprise) ...[
                      const SizedBox(height: 24),
                      _PaygCard(
                        title: 'Pay as you go',
                        copy: copy.paygCopy,
                        actionLabel: copy.paygButtonLabel,
                        actionIcon: copy.paygButtonIcon,
                        showLimitInput: paygAction == PaygAction.increaseLimit,
                        limitAmount: _formatCurrency(
                          payg?.monthlyLimitCents ?? 4000,
                        ),
                        onPaygTap: () {
                          Navigator.pop(context);
                          context.push('/settings/credits');
                        },
                      ),
                    ],
                    const SizedBox(height: 32),
                    for (var i = 0; i < actions.length; i++) ...[
                      if (i > 0) const SizedBox(height: 12),
                      _SheetButton(
                        label: actions[i].label,
                        icon: actions[i].icon,
                        primary: i == 0,
                        onTap: () {
                          Navigator.pop(context);
                          actions[i].navigate(context);
                        },
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

  _SheetCopy _resolveCopy(
    CreditsPlanAudience audience,
    PaygAction paygAction,
    PaygSettings? payg,
  ) {
    switch (audience) {
      case CreditsPlanAudience.enterprise:
        return const _SheetCopy(
          introMain: 'Contact sales or view your usage history.',
        );
      case CreditsPlanAudience.pro:
        return _SheetCopy(
          introMain: 'Enable pay-as-you-go to keep going, or contact sales.',
          introSub: 'You can also invite friends to earn free credits.',
          paygCopy: _paygStatusCopy(paygAction, payg),
          paygButtonLabel: _paygButtonLabel(paygAction),
          paygButtonIcon: _paygButtonIcon(paygAction),
        );
      case CreditsPlanAudience.basic:
        return _SheetCopy(
          introMain: 'Enable pay-as-you-go to keep going, or upgrade to Pro.',
          introSub: 'You can also invite friends to earn free credits.',
          paygCopy: _paygStatusCopy(paygAction, payg),
          paygButtonLabel: _paygButtonLabel(paygAction),
          paygButtonIcon: _paygButtonIcon(paygAction),
        );
      case CreditsPlanAudience.free:
        return _SheetCopy(
          introMain: reason == CreditsExhaustedReason.email
              ? 'Upgrade your plan for more credits to keep finding candidate emails.'
              : 'Upgrade your plan for more credits, or enable pay-as-you-go.',
          introSub: 'You can also invite friends to earn free credits.',
          paygCopy: _paygStatusCopy(paygAction, payg),
          paygButtonLabel: _paygButtonLabel(paygAction),
          paygButtonIcon: _paygButtonIcon(paygAction),
        );
    }
  }

  String _paygStatusCopy(PaygAction action, PaygSettings? payg) {
    switch (action) {
      case PaygAction.bindCard:
        return 'Only pay for the extra credits you actually use.';
      case PaygAction.enable:
        return 'Payment method saved.\nEnable pay-as-you-go to continue.';
      case PaygAction.updatePaymentMethod:
        return 'Your last pay-as-you-go charge failed.\nUpdate your payment method first.';
      case PaygAction.increaseLimit:
        final cap = _formatCurrency(payg?.monthlyLimitCents ?? 2500);
        return "You've reached your pay-as-you-go monthly limit ($cap).";
      case PaygAction.manage:
        return 'Pay-as-you-go is enabled.\nIf you still see this, check your settings.';
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
        return 'Increase limit';
      case PaygAction.manage:
        return 'Manage PAYG';
    }
  }

  String _paygButtonIcon(PaygAction action) {
    switch (action) {
      case PaygAction.bindCard:
        return CreditsSheetIcons.setup;
      case PaygAction.enable:
        return CreditsSheetIcons.power;
      case PaygAction.updatePaymentMethod:
        return CreditsSheetIcons.creditCard;
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
            navigate: (ctx) => ctx.push('/pricing'),
          ),
          _SheetAction(
            label: 'View usage history',
            navigate: (ctx) => ctx.push('/settings/credits'),
          ),
        ];
      case CreditsPlanAudience.pro:
        return [
          _SheetAction(
            label: 'Contact sales',
            icon: CreditsSheetIcons.chatBubble,
            navigate: (ctx) => ctx.push('/pricing'),
          ),
          _SheetAction(
            label: 'Invite friends +500 credits',
            icon: CreditsSheetIcons.userPlus,
            navigate: (ctx) => ctx.push('/me/invite'),
          ),
        ];
      case CreditsPlanAudience.basic:
        return [
          _SheetAction(
            label: 'Upgrade to Pro',
            icon: CreditsSheetIcons.bolt,
            navigate: (ctx) => ctx.push('/pricing'),
          ),
          _SheetAction(
            label: 'Invite friends +500 credits',
            icon: CreditsSheetIcons.userPlus,
            navigate: (ctx) => ctx.push('/me/invite'),
          ),
        ];
      case CreditsPlanAudience.free:
        return [
          _SheetAction(
            label: 'Upgrade',
            icon: CreditsSheetIcons.bolt,
            navigate: (ctx) => ctx.push('/pricing'),
          ),
          _SheetAction(
            label: 'Invite friends +500 credits',
            icon: CreditsSheetIcons.userPlus,
            navigate: (ctx) => ctx.push('/me/invite'),
          ),
        ];
    }
  }

  static String _formatCurrency(int cents) {
    final amount = cents / 100;
    if (amount == amount.roundToDouble()) {
      return '\$${amount.toInt()}';
    }
    return '\$${amount.toStringAsFixed(2)}';
  }
}

class _SheetCopy {
  const _SheetCopy({
    required this.introMain,
    this.introSub,
    this.paygCopy = 'Only pay for the extra credits you actually use.',
    this.paygButtonLabel = 'Set up',
    this.paygButtonIcon = CreditsSheetIcons.setup,
  });

  final String introMain;
  final String? introSub;
  final String paygCopy;
  final String paygButtonLabel;
  final String paygButtonIcon;
}

class _SheetAction {
  const _SheetAction({
    required this.label,
    required this.navigate,
    this.icon,
  });

  final String label;
  final String? icon;
  final void Function(BuildContext context) navigate;
}

class _PaygCard extends StatelessWidget {
  const _PaygCard({
    required this.title,
    required this.copy,
    required this.actionLabel,
    required this.actionIcon,
    required this.onPaygTap,
    this.showLimitInput = false,
    this.limitAmount = '\$40',
  });

  final String title;
  final String copy;
  final String actionLabel;
  final String actionIcon;
  final VoidCallback onPaygTap;
  final bool showLimitInput;
  final String limitAmount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CreditsExhaustedSheet._cardBg,
        border: Border.all(color: CreditsExhaustedSheet._line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: CreditsExhaustedSheet._ink,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            copy,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: CreditsExhaustedSheet._muted,
            ),
          ),
          if (showLimitInput) ...[
            const SizedBox(height: 16),
            const Text(
              'Monthly limit',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4B5563),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 42,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: CreditsExhaustedSheet._line),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                limitAmount,
                style: const TextStyle(
                  fontSize: 14,
                  color: CreditsExhaustedSheet._ink,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          _SmallActionButton(
            label: actionLabel,
            icon: actionIcon,
            onTap: onPaygTap,
          ),
        ],
      ),
    );
  }
}

class _SmallActionButton extends StatelessWidget {
  const _SmallActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 42,
          decoration: BoxDecoration(
            border: Border.all(color: CreditsExhaustedSheet._line),
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                offset: Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CreditsSheetSvgIcon(
                icon,
                size: 16,
                color: const Color(0xFF374151),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF374151),
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
    return Material(
      color: primary ? Colors.black : Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: primary ? 0 : 0,
      shadowColor: const Color(0x1F000000),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: primary ? null : Border.all(color: Colors.black),
            boxShadow: primary
                ? const [
                    BoxShadow(
                      color: Color(0x1F000000),
                      offset: Offset(0, 4),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
          child: SizedBox(
            height: 48,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  CreditsSheetSvgIcon(
                    icon!,
                    size: 20,
                    color: primary ? Colors.white : Colors.black,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: primary ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
