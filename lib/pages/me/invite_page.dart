import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/account_service.dart';
import '../../theme/dinq_tokens.dart';
import '../../widgets/common/default_app_bar.dart';

/// My → Invite friends。1:1 还原 web `InviteFriendsCard.tsx`：
/// 说明 + Enter invite code；3 统计(Total/Used/Left)；Your Invite Codes 列表
/// (子行 + Copy link 复制完整邀请链接 / Used 态)；Invite History 表(Name/Code/Date/Reward)。
/// 接口走 AccountService（/referral/codes, /referral/history, /referral/redeem）。
class InvitePage extends StatefulWidget {
  const InvitePage({super.key});

  @override
  State<InvitePage> createState() => _InvitePageState();
}

class _InvitePageState extends State<InvitePage> {
  final _service = AccountService();
  Map<String, dynamic> _data = {};
  List<dynamic> _history = [];
  bool _loading = true;
  String? _copiedCode;

  static const _ink = Color(0xFF2A2826);
  static const _muted = Color(0xFF9E9B93);
  static const _border = Color(0xFFE5E2DC);
  static const _rowBorder = Color(0xFFF0EEEB);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _service.getReferralCodes(),
        _service.getReferralHistory(),
      ]);
      if (!mounted) return;
      setState(() {
        _data = results[0] as Map<String, dynamic>;
        _history = results[1] as List<dynamic>;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _snack('Failed to load referral data');
    }
  }

  String _inviteLink(String code) => 'https://dinq.me/invite/${code.toUpperCase()}';

  Future<void> _copy(String code) async {
    await Clipboard.setData(ClipboardData(text: _inviteLink(code)));
    setState(() => _copiedCode = code);
    _snack('Invite link copied!');
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _copiedCode == code) setState(() => _copiedCode = null);
    });
  }

  Future<void> _enterInviteCode() async {
    final ctrl = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Enter invite code',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: _ink)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            hintText: 'Invite code',
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('Redeem')),
        ],
      ),
    );
    if (code == null || code.trim().isEmpty) return;
    try {
      await _service.redeemReferral(code.trim());
      _snack('Invite code redeemed');
      await _load();
    } catch (e) {
      _snack('Redeem failed: $e');
    }
  }

  String _fmtDate(String? s) {
    final d = DateTime.tryParse(s ?? '')?.toLocal();
    if (d == null) return '';
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${m[d.month - 1]} ${d.day}, ${d.year}';
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DinqTokens.bgPage,
      appBar: DefaultAppBar(context, titleString: 'Invite friends'),
      body: _loading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 80),
                child: Text('Loading...', style: TextStyle(fontSize: 14, color: _muted)),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _headerRow(),
                const SizedBox(height: 20),
                _stats(),
                const SizedBox(height: 20),
                _sectionTitle('Your Invite Codes'),
                const SizedBox(height: 12),
                _codesCard(),
                const SizedBox(height: 20),
                _sectionTitle('Invite History'),
                const SizedBox(height: 12),
                _historyCard(),
              ],
            ),
    );
  }

  Widget _headerRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Text(
            'Share your invite links with friends. You both earn credits for each successful invite.',
            style: TextStyle(fontSize: 14, height: 1.4, color: _muted),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _enterInviteCode,
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: _border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('Enter invite code',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _ink)),
          ),
        ),
      ],
    );
  }

  Widget _stats() {
    final total = (_data['total'] ?? 0).toString();
    final used = (_data['used'] ?? 0).toString();
    final left = (_data['left'] ?? 0).toString();
    return Row(
      children: [
        Expanded(child: _statCard('TOTAL', total)),
        const SizedBox(width: 12),
        Expanded(child: _statCard('USED', used)),
        const SizedBox(width: 12),
        Expanded(child: _statCard('LEFT', left)),
      ],
    );
  }

  Widget _statCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11, letterSpacing: 0.5, fontWeight: FontWeight.w500, color: _muted)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: _ink)),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) =>
      Text(t, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _ink));

  Widget _codesCard() {
    final codes = (_data['codes'] as List?) ?? const [];
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: codes.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text('No invite codes yet.', style: TextStyle(fontSize: 14, color: _muted)),
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < codes.length; i++)
                  _codeRow(Map<String, dynamic>.from(codes[i] as Map), i < codes.length - 1),
              ],
            ),
    );
  }

  Widget _codeRow(Map<String, dynamic> c, bool divider) {
    final code = (c['code'] ?? '').toString();
    final usedByName = (c['used_by_name'] ?? '').toString();
    final isUsed = (c['used_at'] != null && '${c['used_at']}'.isNotEmpty) || usedByName.isNotEmpty;
    final copied = _copiedCode == code;
    return Container(
      decoration: BoxDecoration(
        border: divider ? const Border(bottom: BorderSide(color: _rowBorder)) : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(code,
                    style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                        color: isUsed ? _muted : _ink)),
                const SizedBox(height: 2),
                Text(
                  isUsed
                      ? (usedByName.isNotEmpty ? 'Used by $usedByName' : 'Used')
                      : 'Available to share',
                  style: const TextStyle(fontSize: 12, color: _muted),
                ),
              ],
            ),
          ),
          if (isUsed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: _rowBorder,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text('Used',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _muted)),
            )
          else
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _copy(code),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: _ink,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(copied ? 'Copied!' : 'Copy link',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _historyCard() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: _history.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 40, horizontal: 16),
              child: Center(
                child: Text('No history yet. Start inviting friends to see your progress here.',
                    textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: _muted)),
              ),
            )
          : Column(
              children: [
                // 表头
                Container(
                  color: const Color(0xFFFAFAF8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: const Row(
                    children: [
                      Expanded(flex: 3, child: _Th('Name')),
                      Expanded(flex: 3, child: _Th('Code')),
                      Expanded(flex: 3, child: _Th('Date')),
                      Expanded(flex: 2, child: _Th('Reward', right: true)),
                    ],
                  ),
                ),
                for (var i = 0; i < _history.length; i++)
                  _historyRow(Map<String, dynamic>.from(_history[i] as Map), i < _history.length - 1),
              ],
            ),
    );
  }

  Widget _historyRow(Map<String, dynamic> h, bool divider) {
    final name = (h['name'] ?? '').toString();
    final code = (h['code'] ?? '').toString();
    final date = _fmtDate(h['used_at']?.toString());
    final reward = (h['reward'] ?? 0).toString();
    return Container(
      decoration: BoxDecoration(
        border: divider ? const Border(bottom: BorderSide(color: _rowBorder)) : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
              flex: 3,
              child: Text(name, style: const TextStyle(fontSize: 13, color: _ink))),
          Expanded(
              flex: 3,
              child: Text(code,
                  style: const TextStyle(fontSize: 13, fontFamily: 'monospace', color: _muted))),
          Expanded(
              flex: 3,
              child: Text(date, style: const TextStyle(fontSize: 13, color: _muted))),
          Expanded(
            flex: 2,
            child: Text('+$reward',
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF16A34A))),
          ),
        ],
      ),
    );
  }
}

class _Th extends StatelessWidget {
  const _Th(this.text, {this.right = false});
  final String text;
  final bool right;
  @override
  Widget build(BuildContext context) {
    return Text(text,
        textAlign: right ? TextAlign.right : TextAlign.left,
        style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF9E9B93)));
  }
}
