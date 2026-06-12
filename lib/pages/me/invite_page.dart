import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/account_service.dart';
import '../../theme/dinq_tokens.dart';
import '../../utils/color_util.dart';
import '../../widgets/common/default_app_bar.dart';

/// My → 邀请赚积分（Invite friends, earn credits）。
/// 接 /referral/codes + /referral/history。
class InvitePage extends StatefulWidget {
  const InvitePage({super.key});

  @override
  State<InvitePage> createState() => _InvitePageState();
}

class _InvitePageState extends State<InvitePage> {
  final _service = AccountService();
  Map<String, dynamic>? _overview;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final overview = await _service.getReferralCodes();
      if (!mounted) return;
      setState(() {
        _overview = overview;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _copy(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied $code'), duration: const Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DinqTokens.bgPage,
      appBar: DefaultAppBar(context, titleString: 'Invite friends'),
      body: _body(),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: DinqTokens.textTertiary)),
            const SizedBox(height: 12),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    final o = _overview ?? {};
    final total = (o['total'] as num?)?.toInt() ?? 0;
    final used = (o['used'] as num?)?.toInt() ?? 0;
    final left = (o['left'] as num?)?.toInt() ?? 0;
    final rewards = (o['total_rewards'] as num?)?.toInt() ?? 0;
    final codes = (o['codes'] as List?) ?? const [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Invite friends, earn credits',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: DinqTokens.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Share an invite code. When a friend joins, you both earn credits.',
          style: TextStyle(fontSize: 13, color: DinqTokens.textSecondary, height: 1.4),
        ),
        const SizedBox(height: 18),
        // 统计
        Row(
          children: [
            _stat('Left', '$left'),
            _stat('Used', '$used'),
            _stat('Total', '$total'),
            _stat('Rewards', '$rewards'),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'Your invite codes',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: DinqTokens.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        for (final c in codes) _codeRow(Map<String, dynamic>.from(c as Map)),
        if (codes.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text('No invite codes yet',
                  style: TextStyle(color: DinqTokens.textTertiary)),
            ),
          ),
      ],
    );
  }

  Widget _stat(String label, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: DinqTokens.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: DinqTokens.borderLL),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: ColorUtil.textColor,
                )),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(fontSize: 11, color: DinqTokens.textTertiary)),
          ],
        ),
      ),
    );
  }

  Widget _codeRow(Map<String, dynamic> c) {
    final code = (c['code'] ?? '').toString();
    final usedBy = c['used_by_name'];
    final isUsed = usedBy != null && usedBy.toString().isNotEmpty;
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
          Text(
            code,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: isUsed ? DinqTokens.textTertiary : ColorUtil.textColor,
            ),
          ),
          const SizedBox(width: 10),
          if (isUsed)
            Text('used by $usedBy',
                style: const TextStyle(fontSize: 12, color: DinqTokens.textTertiary)),
          const Spacer(),
          if (!isUsed)
            GestureDetector(
              onTap: () => _copy(code),
              behavior: HitTestBehavior.opaque,
              child: const Icon(Icons.copy_rounded, size: 18, color: DinqTokens.textSecondary),
            )
          else
            const Icon(Icons.check_circle, size: 18, color: Color(0xFF6E9B72)),
        ],
      ),
    );
  }
}
