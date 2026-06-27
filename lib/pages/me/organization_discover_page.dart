import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/account_service.dart';
import '../../theme/dinq_tokens.dart';
import '../../utils/color_util.dart';
import '../../widgets/common/default_app_bar.dart';

/// 发现 / 加入组织（对齐 web）：邀请码加入 + 公开组织列表(申请加入)。
class OrganizationDiscoverPage extends StatefulWidget {
  const OrganizationDiscoverPage({super.key});

  @override
  State<OrganizationDiscoverPage> createState() => _OrganizationDiscoverPageState();
}

class _OrganizationDiscoverPageState extends State<OrganizationDiscoverPage> {
  final _service = AccountService();
  final _codeCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  Timer? _searchDebounce;
  List<dynamic> _orgs = [];
  final Map<String, String> _joinStatus = {}; // orgId -> status
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _codeCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load([String? keyword]) async {
    setState(() => _loading = true);
    try {
      final orgs = await _service.discoverOrgs(keyword: keyword);
      if (!mounted) return;
      setState(() {
        _orgs = orgs;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _onSearch(String v) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () => _load(v.trim()));
  }

  Future<void> _joinByCode() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) return;
    try {
      final status = await _service.joinOrgByCode(code);
      if (status == 'joined') {
        _snack('Joined organization');
        if (mounted) Navigator.pop(context, true);
      } else if (status == 'already_member') {
        _snack('You are already a member');
      } else {
        _snack('Done');
      }
    } catch (e) {
      _snack('Invalid or expired code');
    }
  }

  Future<void> _requestJoin(Map<String, dynamic> org) async {
    final id = (org['id'] ?? '').toString();
    try {
      final status = await _service.requestJoinOrg(id);
      if (!mounted) return;
      setState(() => _joinStatus[id] = status);
      switch (status) {
        case 'pending':
          _snack('Join request sent');
          break;
        case 'already_member':
          _snack('You are already a member');
          break;
        case 'already_requested':
          _snack('Request already pending');
          break;
      }
    } catch (e) {
      _snack('Failed: $e');
    }
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {},
      child: Scaffold(
        backgroundColor: DinqTokens.bgPage,
        appBar: DefaultAppBar(context, titleString: 'Discover organizations'),
        body: Column(
          children: [
            // 邀请码加入
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _codeCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: 'Enter invite code',
                        hintStyle: const TextStyle(color: Color(0xFFA8A29E)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _joinByCode,
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: ColorUtil.textColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('Join',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
            // 搜索
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                onChanged: _onSearch,
                decoration: InputDecoration(
                  hintText: 'Search organizations',
                  hintStyle: const TextStyle(color: Color(0xFFA8A29E)),
                  prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF9E9B93)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                  : _orgs.isEmpty
                      ? const Center(
                          child: Text('No organizations found',
                              style: TextStyle(fontSize: 14, color: DinqTokens.textTertiary)))
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                          children: [
                            for (final o in _orgs) _orgRow(Map<String, dynamic>.from(o as Map)),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _orgRow(Map<String, dynamic> o) {
    final id = (o['id'] ?? '').toString();
    final name = (o['name'] ?? 'Organization').toString();
    final slug = (o['slug'] ?? '').toString();
    final count = (o['member_count'] ?? o['members'] ?? '').toString();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final status = _joinStatus[id];

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
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: DinqTokens.bgSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(initial,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: ColorUtil.textColor)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600, color: ColorUtil.textColor)),
                const SizedBox(height: 2),
                Text(
                  [if (slug.isNotEmpty) '@$slug', if (count.isNotEmpty) '$count members'].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: DinqTokens.textTertiary),
                ),
              ],
            ),
          ),
          _joinPill(status, () => _requestJoin(o)),
        ],
      ),
    );
  }

  Widget _joinPill(String? status, VoidCallback onTap) {
    String label;
    bool disabled = false;
    switch (status) {
      case 'pending':
      case 'already_requested':
        label = 'Pending';
        disabled = true;
        break;
      case 'already_member':
        label = 'Member';
        disabled = true;
        break;
      default:
        label = 'Request';
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: disabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: disabled ? DinqTokens.bgSurface : ColorUtil.textColor,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: disabled ? DinqTokens.textTertiary : Colors.white)),
      ),
    );
  }
}
