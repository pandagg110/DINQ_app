import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../services/account_service.dart';
import '../../theme/dinq_tokens.dart';
import '../../utils/color_util.dart';
import '../../widgets/common/default_app_bar.dart';

/// My → Organization → 详情（组织轻管理）。
/// 还原线上 H5：成员查看 + 邀请链接（admin/owner 可刷新）+ 加入申请审批（admin/owner）。
/// 接口：/orgs/{id}/members、/orgs/{id}/refresh-invite、/orgs/{id}/requests(+审批)。
class OrganizationDetailPage extends StatefulWidget {
  final Map<String, dynamic> org;
  const OrganizationDetailPage({super.key, required this.org});

  @override
  State<OrganizationDetailPage> createState() => _OrganizationDetailPageState();
}

class _OrganizationDetailPageState extends State<OrganizationDetailPage> {
  final _service = AccountService();

  List<dynamic> _members = [];
  List<dynamic> _requests = [];
  bool _loading = true;
  String? _error;
  late String _inviteCode;
  bool _refreshing = false;

  String get _id => (widget.org['id'] ?? '').toString();
  String get _role => (widget.org['role'] ?? widget.org['my_role'] ?? '').toString();
  bool get _isManager => _role == 'owner' || _role == 'admin';

  @override
  void initState() {
    super.initState();
    _inviteCode = (widget.org['invite_code'] ?? '').toString();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final members = await _service.getOrgMembers(_id);
      List<dynamic> requests = const [];
      if (_isManager) {
        requests = await _service.getOrgJoinRequests(_id);
      }
      if (!mounted) return;
      setState(() {
        _members = members;
        _requests = requests;
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

  String get _inviteLink =>
      _inviteCode.isEmpty ? '' : 'https://dinq.me/invite/${_inviteCode.toUpperCase()}';

  Future<void> _copyInvite() async {
    if (_inviteLink.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _inviteLink));
    _snack('Invite link copied');
  }

  Future<void> _refreshInvite() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    try {
      final code = await _service.refreshOrgInvite(_id);
      if (!mounted) return;
      setState(() => _inviteCode = code);
      _snack('Invite link refreshed');
    } catch (e) {
      _snack('Refresh failed: $e');
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _review(Map<String, dynamic> req, String action) async {
    final rid = (req['id'] ?? '').toString();
    try {
      await _service.reviewOrgJoinRequest(_id, rid, action);
      if (!mounted) return;
      setState(() => _requests = _requests.where((r) => (r as Map)['id'].toString() != rid).toList());
      _snack(action == 'approved' ? 'Request approved' : 'Request rejected');
    } catch (e) {
      _snack('Failed: $e');
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final name = (widget.org['name'] ?? 'Organization').toString();
    return Scaffold(
      backgroundColor: DinqTokens.bgPage,
      appBar: DefaultAppBar(context, titleString: name),
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _header(),
        const SizedBox(height: 20),
        if (_inviteCode.isNotEmpty || _isManager) ...[
          _sectionTitle('Invite link'),
          const SizedBox(height: 8),
          _inviteCard(),
          const SizedBox(height: 20),
        ],
        if (_isManager && _requests.isNotEmpty) ...[
          _sectionTitle('Join requests (${_requests.length})'),
          const SizedBox(height: 8),
          for (final r in _requests) _requestRow(Map<String, dynamic>.from(r as Map)),
          const SizedBox(height: 20),
        ],
        _sectionTitle('Members (${_members.length})'),
        const SizedBox(height: 8),
        for (final m in _members) _memberRow(Map<String, dynamic>.from(m as Map)),
      ],
    );
  }

  Widget _header() {
    final name = (widget.org['name'] ?? 'Organization').toString();
    final slug = (widget.org['slug'] ?? '').toString();
    final count = (widget.org['member_count'] ?? _members.length).toString();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: DinqTokens.bgSurface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(initial,
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w700, color: ColorUtil.textColor)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700, color: ColorUtil.textColor)),
              const SizedBox(height: 3),
              Text(
                [
                  if (slug.isNotEmpty) '@$slug',
                  '$count members',
                  if (_role.isNotEmpty) _role,
                ].join(' · '),
                style: const TextStyle(fontSize: 13, color: DinqTokens.textTertiary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.w700, color: DinqTokens.textPrimary));

  Widget _inviteCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: DinqTokens.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DinqTokens.borderLL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _inviteLink.isEmpty ? 'No invite link yet' : _inviteLink,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 13,
                color: _inviteLink.isEmpty ? DinqTokens.textTertiary : ColorUtil.textColor),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (_inviteLink.isNotEmpty)
                _actionPill(
                  icon: Icons.copy_rounded,
                  label: 'Copy',
                  onTap: _copyInvite,
                ),
              if (_isManager) ...[
                if (_inviteLink.isNotEmpty) const SizedBox(width: 10),
                _actionPill(
                  icon: Icons.refresh_rounded,
                  label: _refreshing ? 'Refreshing…' : 'Refresh',
                  onTap: _refreshing ? null : _refreshInvite,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionPill({required IconData icon, required String label, VoidCallback? onTap}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: DinqTokens.bgSurface,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: ColorUtil.textColor),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: ColorUtil.textColor)),
          ],
        ),
      ),
    );
  }

  Widget _requestRow(Map<String, dynamic> r) {
    final user = (r['user'] as Map?)?.cast<String, dynamic>() ?? const {};
    final name = (user['name'] ?? r['user_id'] ?? 'User').toString();
    final sub = (user['full_position'] ?? user['domain'] ?? '').toString();
    final avatar = (user['avatar_url'] ?? '').toString();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: DinqTokens.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DinqTokens.borderLL),
      ),
      child: Row(
        children: [
          _avatar(avatar, name),
          const SizedBox(width: 12),
          Expanded(child: _nameSub(name, sub)),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _review(r, 'approved'),
            child: const Icon(Icons.check_circle_outline, size: 24, color: Color(0xFF5C8840)),
          ),
          const SizedBox(width: 14),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _review(r, 'rejected'),
            child: const Icon(Icons.cancel_outlined, size: 24, color: Color(0xFFE24B3C)),
          ),
        ],
      ),
    );
  }

  Widget _memberRow(Map<String, dynamic> m) {
    final user = (m['user'] as Map?)?.cast<String, dynamic>() ?? const {};
    final name = (user['name'] ?? m['user_id'] ?? 'Member').toString();
    final position = (user['full_position'] ?? user['full_degree'] ?? '').toString();
    final location = (user['location'] ?? '').toString();
    final sub = [
      if (position.isNotEmpty) position,
      if (location.isNotEmpty) location,
    ].join(' · ');
    final avatar = (user['avatar_url'] ?? '').toString();
    final domain = (user['domain'] ?? '').toString();
    final role = (m['role'] ?? '').toString();
    final uid = (m['user_id'] ?? '').toString();
    // 管理者可管理「非 owner」成员（对齐 H5：owner 不可被管理）
    final canManage = _isManager && role != 'owner';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: domain.isNotEmpty ? () => context.push('/$domain') : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: DinqTokens.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: DinqTokens.borderLL),
        ),
        child: Row(
          children: [
            _avatar(avatar, name),
            const SizedBox(width: 12),
            Expanded(child: _nameSub(name, sub)),
            if (role.isNotEmpty) _roleBadge(role),
            if (canManage)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz_rounded, size: 20, color: DinqTokens.textTertiary),
                onSelected: (v) => _manageMember(uid, name, v),
                itemBuilder: (_) => [
                  if (role != 'admin')
                    const PopupMenuItem(value: 'admin', child: Text('Make admin')),
                  if (role == 'admin')
                    const PopupMenuItem(value: 'member', child: Text('Make member')),
                  const PopupMenuItem(
                      value: 'remove',
                      child: Text('Remove member', style: TextStyle(color: Color(0xFFE24B3C)))),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _roleBadge(String role) {
    // owner 绿 / admin 金 / member 中性（对齐 H5 RoleBadge）
    Color fg;
    Color bg;
    switch (role) {
      case 'owner':
        fg = const Color(0xFF0E9463);
        bg = const Color(0xFFE7F6EF);
        break;
      case 'admin':
        fg = const Color(0xFFA67512);
        bg = const Color(0xFFFBF1DC);
        break;
      default:
        fg = DinqTokens.textSecondary;
        bg = DinqTokens.bgSurface;
    }
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(role[0].toUpperCase() + role.substring(1),
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }

  Future<void> _manageMember(String uid, String name, String action) async {
    try {
      if (action == 'remove') {
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Remove member'),
            content: Text('Remove $name from this organization?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Remove', style: TextStyle(color: Color(0xFFE24B3C)))),
            ],
          ),
        );
        if (ok != true) return;
        await _service.removeOrgMember(_id, uid);
      } else {
        await _service.updateOrgMemberRole(_id, uid, action); // 'admin' | 'member'
      }
      await _load();
    } catch (e) {
      _snack('Failed: $e');
    }
  }

  Widget _nameSub(String name, String sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: ColorUtil.textColor)),
        if (sub.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(sub,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: DinqTokens.textTertiary)),
        ],
      ],
    );
  }

  // 与 H5 nameToAvatarColor 思路一致：按名字哈希取一个柔和底色
  static const _avatarPalette = [
    Color(0xFFE7F6EF), Color(0xFFFBF1DC), Color(0xFFEAF0FB),
    Color(0xFFF7EAF3), Color(0xFFFCEEE8), Color(0xFFEDEEF7),
  ];

  Widget _avatar(String url, String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final tint = _avatarPalette[name.hashCode.abs() % _avatarPalette.length];
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: url.isNotEmpty ? DinqTokens.bgSurface : tint,
        image: url.isNotEmpty
            ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)
            : null,
      ),
      child: url.isNotEmpty
          ? null
          : Text(initial,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: ColorUtil.textColor)),
    );
  }
}
