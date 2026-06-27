import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/account_service.dart';
import '../../theme/dinq_tokens.dart';
import '../../utils/color_util.dart';
import '../../widgets/common/default_app_bar.dart';
import 'organization_create_page.dart';
import 'organization_discover_page.dart';

/// My → Organization。接 /orgs（我加入/创建的组织列表）。
class OrganizationPage extends StatefulWidget {
  const OrganizationPage({super.key});

  @override
  State<OrganizationPage> createState() => _OrganizationPageState();
}

class _OrganizationPageState extends State<OrganizationPage> {
  final _service = AccountService();
  List<dynamic> _orgs = [];
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
      final orgs = await _service.getMyOrganizations();
      if (!mounted) return;
      setState(() {
        _orgs = orgs;
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

  Future<void> _openCreate() async {
    final created = await Navigator.push<bool>(
      context, MaterialPageRoute(builder: (_) => const OrganizationCreatePage()));
    if (created == true && mounted) await _load();
  }

  Future<void> _openDiscover() async {
    final joined = await Navigator.push<bool>(
      context, MaterialPageRoute(builder: (_) => const OrganizationDiscoverPage()));
    if (joined == true && mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DinqTokens.bgPage,
      appBar: DefaultAppBar(
        context,
        titleString: 'Organization',
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFF171717)),
            tooltip: 'Discover',
            onPressed: _openDiscover,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _openCreate,
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(color: Color(0xFF171717), shape: BoxShape.circle),
                child: const Icon(Icons.add, size: 20, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
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
    if (_orgs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.business_outlined, size: 40, color: DinqTokens.textTertiary),
            const SizedBox(height: 12),
            const Text('No organizations yet',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600, color: DinqTokens.textPrimary)),
            const SizedBox(height: 4),
            const Text('Organizations you join or create appear here.',
                style: TextStyle(fontSize: 13, color: DinqTokens.textSecondary)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _emptyBtn('Create', filled: true, onTap: _openCreate),
                const SizedBox(width: 12),
                _emptyBtn('Discover', filled: false, onTap: _openDiscover),
              ],
            ),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [for (final o in _orgs) _orgRow(Map<String, dynamic>.from(o as Map))],
    );
  }

  Widget _emptyBtn(String label, {required bool filled, required VoidCallback onTap}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
        decoration: BoxDecoration(
          color: filled ? ColorUtil.textColor : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: filled ? null : Border.all(color: DinqTokens.borderL),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: filled ? Colors.white : ColorUtil.textColor)),
      ),
    );
  }

  Widget _orgRow(Map<String, dynamic> o) {
    final name = (o['name'] ?? o['title'] ?? 'Organization').toString();
    final slug = (o['slug'] ?? o['handle'] ?? '').toString();
    final role = (o['role'] ?? o['my_role'] ?? '').toString();
    final members = (o['member_count'] ?? o['members'] ?? '').toString();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final pending = int.tryParse((o['pending_request_count'] ?? '0').toString()) ?? 0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/me/organization/detail', extra: o),
      child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          const SizedBox(width: 14),
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
                  [
                    if (slug.isNotEmpty) '@$slug',
                    if (role.isNotEmpty) role,
                    if (members.isNotEmpty) '$members members',
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: DinqTokens.textTertiary),
                ),
              ],
            ),
          ),
          if (pending > 0)
            Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE24B3C),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text('$pending',
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          const Icon(Icons.chevron_right_rounded, color: DinqTokens.textTertiary),
        ],
      ),
      ),
    );
  }
}
