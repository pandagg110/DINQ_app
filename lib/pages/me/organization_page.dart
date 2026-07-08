import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/account_service.dart';
import '../../theme/dinq_tokens.dart';
import '../../widgets/common/default_app_bar.dart';
import '../../widgets/common/dinq_nav_buttons.dart';
import 'organization_create_page.dart';
import 'organization_detail_page.dart';

/// My → Organization 列表页。对齐 web organization/page.tsx：
/// 三分区（My Organization / Pending Approval / Recommended）+ 富卡片
/// （banner + logo 叠加 + 名称/状态标签 + 类型·成员数 + 描述/标签框 +
/// 地点 | dinq.me/slug 复制）。
/// 数据：GET /org/my（role≠'' 为已加入；request_status=pending 为待审批）
/// + GET /orgs（排除前两类 = 推荐）。
class OrganizationPage extends StatefulWidget {
  const OrganizationPage({super.key});

  @override
  State<OrganizationPage> createState() => _OrganizationPageState();
}

class _OrganizationPageState extends State<OrganizationPage> {
  final _service = AccountService();
  List<Map<String, dynamic>> _memberOrgs = [];
  List<Map<String, dynamic>> _pendingOrgs = [];
  List<Map<String, dynamic>> _recommendedOrgs = [];
  bool _loading = true;
  String? _error;
  String? _copiedSlug;

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
      final results = await Future.wait([
        _service.getMyOrganizations(),
        _service.getOrganizations(),
      ]);
      if (!mounted) return;
      final my = results[0]
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      final all = results[1]
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      final member = <Map<String, dynamic>>[];
      final pending = <Map<String, dynamic>>[];
      final knownIds = <String>{};
      for (final o in my) {
        final id = (o['id'] ?? '').toString();
        knownIds.add(id);
        final role = (o['role'] ?? '').toString();
        if (role.isNotEmpty) {
          member.add(o);
        } else if ((o['request_status'] ?? '').toString() == 'pending') {
          pending.add(o);
        }
      }
      final recommended = all
          .where((o) => !knownIds.contains((o['id'] ?? '').toString()))
          .toList();
      setState(() {
        _memberOrgs = member;
        _pendingOrgs = pending;
        _recommendedOrgs = recommended;
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
      context,
      MaterialPageRoute(builder: (_) => const OrganizationCreatePage()),
    );
    if (created == true && mounted) await _load();
  }

  Future<void> _openDetail(Map<String, dynamic> org) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrganizationDetailPage(org: org),
      ),
    );
    if (mounted) await _load();
  }

  void _copySlugLink(String slug) {
    Clipboard.setData(ClipboardData(text: 'https://dinq.me/$slug'));
    setState(() => _copiedSlug = slug);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && _copiedSlug == slug) {
        setState(() => _copiedSlug = null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DinqTokens.bgPage,
      appBar: DefaultAppBar(
        context,
        titleString: 'Organization',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: DinqCircleActionButton(
                icon: Icons.add,
                primary: true,
                onTap: _openCreate,
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
            Text(_error!,
                style: const TextStyle(color: DinqTokens.textTertiary)),
            const SizedBox(height: 12),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    final empty = _memberOrgs.isEmpty &&
        _pendingOrgs.isEmpty &&
        _recommendedOrgs.isEmpty;
    if (empty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.business_outlined,
                size: 40, color: DinqTokens.textTertiary),
            const SizedBox(height: 12),
            const Text('No organizations yet',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: DinqTokens.textPrimary)),
            const SizedBox(height: 20),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _openCreate,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
                decoration: BoxDecoration(
                  color: const Color(0xFF171717),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text('Create',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          if (_memberOrgs.isNotEmpty)
            _section('My Organization', null, _memberOrgs),
          if (_pendingOrgs.isNotEmpty)
            _section('Pending Approval', _pendingOrgs.length, _pendingOrgs),
          if (_recommendedOrgs.isNotEmpty)
            _section('Recommended', null, _recommendedOrgs),
        ],
      ),
    );
  }

  Widget _section(String title, int? count, List<Map<String, dynamic>> orgs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16, top: 8),
          child: Row(
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF171717))),
              if (count != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEEDE9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text('$count',
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF9E9B93))),
                ),
              ],
            ],
          ),
        ),
        for (final o in orgs)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: _orgCard(o),
          ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ── 富卡片（对齐 web OrganizationCard）──────────────────────────
  Widget _orgCard(Map<String, dynamic> o) {
    final name = (o['name'] ?? '').toString();
    final slug = (o['slug'] ?? '').toString();
    final logoUrl = (o['logo_url'] ?? '').toString();
    final backgroundUrl = (o['background_url'] ?? '').toString();
    final orgType = (o['org_type'] ?? '').toString();
    final description = (o['description'] ?? '').toString();
    final location = (o['location'] ?? '').toString();
    final tags = (o['tags'] as List?)?.map((e) => e.toString()).toList() ??
        const <String>[];
    final memberCount = (o['member_count'] as num?)?.toInt();
    final role = (o['role'] ?? '').toString();
    final isPending = (o['request_status'] ?? '').toString() == 'pending';
    final pendingRequests =
        (o['pending_request_count'] as num?)?.toInt() ?? 0;
    final canManage = role == 'owner' || role == 'admin';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openDetail(o),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE8E6E1)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // banner
            SizedBox(
              height: 120,
              width: double.infinity,
              child: backgroundUrl.isNotEmpty
                  ? Image.network(backgroundUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          Container(color: const Color(0xFFF8F7F4)))
                  : Container(color: const Color(0xFFF8F7F4)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // logo 叠加 banner 下缘
                  Transform.translate(
                    offset: const Offset(0, -24),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _logo(logoUrl, name),
                        if (canManage && pendingRequests > 0)
                          Positioned(
                            right: -4,
                            top: -4,
                            child: Container(
                              constraints: const BoxConstraints(minWidth: 20),
                              height: 20,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                pendingRequests > 99
                                    ? '99+'
                                    : '$pendingRequests',
                                style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 名称 + 状态标签
                        Row(
                          children: [
                            Expanded(
                              child: Text(name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF1F1F1F))),
                            ),
                            const SizedBox(width: 8),
                            if (isPending && role.isEmpty)
                              _pill('Pending', const Color(0x14C06224),
                                  const Color(0xFFE2703A))
                            else if (role.isNotEmpty)
                              _rolePill(role),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // 类型 · 成员数
                        Row(
                          children: [
                            if (orgType.isNotEmpty) ...[
                              Text(_capitalize(orgType),
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF9E9B93))),
                              if (memberCount != null)
                                const Text(' · ',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF9E9B93))),
                            ],
                            if (memberCount != null) ...[
                              const Icon(Icons.people_outline,
                                  size: 14, color: Color(0xFF9E9B93)),
                              const SizedBox(width: 4),
                              Text(
                                  '$memberCount member${memberCount == 1 ? '' : 's'}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF9E9B93))),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),
                        // 描述/标签框
                        Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(minHeight: 64),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9F9F9),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: description.isEmpty && tags.isEmpty
                              ? const Center(
                                  child: Text('No description yet',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFFC8C6C1))),
                                )
                              : Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    if (description.isNotEmpty)
                                      Text(description,
                                          maxLines: tags.isNotEmpty ? 2 : 3,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              height: 1.6,
                                              color: Color(0xFF8A8880))),
                                    if (tags.isNotEmpty) ...[
                                      if (description.isNotEmpty)
                                        const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          for (final t in tags)
                                            Container(
                                              height: 28,
                                              padding: const EdgeInsets
                                                  .symmetric(horizontal: 10),
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                color:
                                                    const Color(0x1A888888),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(t,
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Color(
                                                          0xFF171717))),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                        ),
                        const SizedBox(height: 12),
                        // 底部：地点 | dinq.me/slug 复制
                        Row(
                          children: [
                            Expanded(
                              child: location.isEmpty
                                  ? const SizedBox.shrink()
                                  : Row(
                                      children: [
                                        const Icon(Icons.place_outlined,
                                            size: 14,
                                            color: Color(0xFF9E9B93)),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(location,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF9E9B93))),
                                        ),
                                      ],
                                    ),
                            ),
                            if (slug.isNotEmpty)
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => _copySlugLink(slug),
                                child: Text(
                                  _copiedSlug == slug
                                      ? 'Copied!'
                                      : 'dinq.me/$slug',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                    color: _copiedSlug == slug
                                        ? const Color(0xFF2A5E52)
                                        : const Color(0xFF9E9B93),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _logo(String logoUrl, String name) {
    final initial = name.isNotEmpty ? name.characters.first.toUpperCase() : '?';
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7F4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: logoUrl.isNotEmpty
          ? Image.network(logoUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _initialBox(initial))
          : _initialBox(initial),
    );
  }

  Widget _initialBox(String initial) => Container(
        color: const Color(0xFFEADFCE),
        alignment: Alignment.center,
        child: Text(initial,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F1F1F))),
      );

  Widget _pill(String label, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w600, color: fg)),
      );

  Widget _rolePill(String role) {
    switch (role) {
      case 'owner':
        return _pill('OWNER', const Color(0xFFE5F4EA), const Color(0xFF35B66B));
      case 'admin':
        return _pill('ADMIN', const Color(0xFFE9EAF6), const Color(0xFF777BA8));
      default:
        return _pill(
            'MEMBER', const Color(0xFFEFEFED), const Color(0xFF8B8B8B));
    }
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
