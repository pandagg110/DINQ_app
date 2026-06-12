import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../stores/user_store.dart';
import '../../theme/dinq_tokens.dart';
import '../../utils/color_util.dart';
import '../../widgets/common/default_app_bar.dart';

/// My → Integration（已连接平台）。接 UserStore.connectedAccounts（/user/accounts）。
class IntegrationPage extends StatefulWidget {
  const IntegrationPage({super.key});

  @override
  State<IntegrationPage> createState() => _IntegrationPageState();
}

class _IntegrationPageState extends State<IntegrationPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<UserStore>().loadUserAccounts();
    });
  }

  IconData _iconFor(String provider) {
    switch (provider) {
      case 'google':
        return Icons.g_mobiledata_rounded;
      case 'github':
        return Icons.code_rounded;
      case 'email':
        return Icons.email_outlined;
      default:
        return Icons.link_rounded;
    }
  }

  String _labelFor(String provider) {
    switch (provider) {
      case 'google':
        return 'Google';
      case 'github':
        return 'GitHub';
      case 'email':
        return 'Email';
      default:
        return provider.isEmpty
            ? 'Account'
            : provider[0].toUpperCase() + provider.substring(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final us = context.watch<UserStore>();
    final accounts = us.connectedAccounts;

    return Scaffold(
      backgroundColor: DinqTokens.bgPage,
      appBar: DefaultAppBar(context, titleString: 'Integration'),
      body: accounts.isEmpty
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Connected accounts',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: DinqTokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                for (final a in accounts)
                  _accountRow(context, us, Map<String, dynamic>.from(a as Map)),
              ],
            ),
    );
  }

  Widget _accountRow(BuildContext context, UserStore us, Map<String, dynamic> a) {
    final provider = (a['provider'] ?? '').toString();
    final connected = a['connected'] == true;
    final displayUrl = (a['display_url'] ?? a['email'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: DinqTokens.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DinqTokens.borderLL),
      ),
      child: Row(
        children: [
          Icon(_iconFor(provider), size: 24, color: ColorUtil.textColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_labelFor(provider),
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: ColorUtil.textColor)),
                if (connected && displayUrl.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(displayUrl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: DinqTokens.textTertiary)),
                ],
              ],
            ),
          ),
          if (connected)
            _pill(
              label: 'Disconnect',
              color: const Color(0xFFE24B3C),
              onTap: provider == 'email'
                  ? null // 邮箱为主账号，不可解绑
                  : () => us.unlinkAccount(provider: provider),
            )
          else
            _pill(
              label: 'Connect',
              color: const Color(0xFF2563EB),
              onTap: () {},
            ),
        ],
      ),
    );
  }

  Widget _pill({required String label, required Color color, VoidCallback? onTap}) {
    final disabled = onTap == null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: disabled ? DinqTokens.bgSurface : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          disabled ? 'Primary' : label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: disabled ? DinqTokens.textTertiary : color,
          ),
        ),
      ),
    );
  }
}
