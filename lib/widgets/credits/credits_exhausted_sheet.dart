import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/user_models.dart';
import '../../services/subscription_pricing_navigation.dart';
import '../../stores/user_store.dart';
import 'credits_sheet_icons.dart';

/// 触发场景，对齐 Web `CreditsExhaustedReason`。
/// 注：当前 Web `CreditsExhaustedModal` 文案按套餐分流，不按 reason 分流；
/// reason 仍保留以兼容调用方（search / email）。
enum CreditsExhaustedReason { search, email }

const _salesEmail = 'support@dinqlabs.com';

/// 对齐 `.example/DINQ_client-main` `CreditsExhaustedModal.tsx`。
/// 按套餐（free / basic / pro / enterprise）展示不同文案与操作。
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

  static const _ink = Color(0xFF2A2826);
  static const _muted = Color(0xFF6B6862);
  static const _sheetBg = Color(0xFFFCFBF9);

  String _planText(CreditsPlanAudience audience) {
    switch (audience) {
      case CreditsPlanAudience.enterprise:
        return 'Contact sales or review usage details.';
      case CreditsPlanAudience.pro:
        return 'Contact sales to continue.';
      case CreditsPlanAudience.basic:
        return 'Upgrade to Pro for more credits.';
      case CreditsPlanAudience.free:
        return 'Upgrade for more credits.';
    }
  }

  List<_SheetAction> _resolveActions(
    BuildContext context,
    CreditsPlanAudience audience,
  ) {
    switch (audience) {
      case CreditsPlanAudience.enterprise:
        return [
          _SheetAction(
            label: 'Contact sales',
            icon: CreditsSheetIcons.chatBubble,
            onTap: () => _openContactSales(context),
          ),
          _SheetAction(
            label: 'View usage',
            onTap: () => _openUsage(context),
          ),
        ];
      case CreditsPlanAudience.pro:
        return [
          _SheetAction(
            label: 'Contact sales',
            icon: CreditsSheetIcons.chatBubble,
            onTap: () => _openContactSales(context),
          ),
          _SheetAction(
            label: 'Invite friends +500 Credits',
            icon: CreditsSheetIcons.userPlus,
            onTap: () => _openInvite(context),
          ),
        ];
      case CreditsPlanAudience.basic:
        return [
          _SheetAction(
            label: 'Upgrade to Pro',
            icon: CreditsSheetIcons.bolt,
            onTap: () => _openUpgrade(context),
          ),
          _SheetAction(
            label: 'Invite friends +500 Credits',
            icon: CreditsSheetIcons.userPlus,
            onTap: () => _openInvite(context),
          ),
        ];
      case CreditsPlanAudience.free:
        return [
          _SheetAction(
            label: 'Upgrade',
            icon: CreditsSheetIcons.bolt,
            onTap: () => _openUpgrade(context),
          ),
          _SheetAction(
            label: 'Invite friends +500 Credits',
            icon: CreditsSheetIcons.userPlus,
            onTap: () => _openInvite(context),
          ),
        ];
    }
  }

  void _closeThen(BuildContext context, VoidCallback action) {
    Navigator.pop(context);
    action();
  }

  void _openUpgrade(BuildContext context) =>
      _closeThen(context, () => openSubscriptionPricing(context));

  void _openUsage(BuildContext context) =>
      _closeThen(context, () => context.push('/settings/credits'));

  void _openInvite(BuildContext context) =>
      _closeThen(context, () => context.push('/me/invite'));

  Future<void> _openContactSales(BuildContext context) async {
    Navigator.pop(context);
    final uri = Uri(
      scheme: 'mailto',
      path: _salesEmail,
      queryParameters: {'subject': 'DINQ sales inquiry'},
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      await openSubscriptionPricing(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subscription = context.watch<UserStore>().subscription;
    final audience = creditsPlanAudience(subscription?.plan);
    final actions = _resolveActions(context, audience);

    return Container(
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
      child: SafeArea(
        top: false,
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
