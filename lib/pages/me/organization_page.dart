import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../services/account_service.dart';
import '../../theme/dinq_tokens.dart';
import '../../utils/org_avatar.dart';
import '../../widgets/common/default_app_bar.dart';
import 'organization_create_page.dart';
import 'organization_detail_page.dart';

/// My → Organization 列表页。对齐最新版 web organization/page.tsx：
/// 顶部搜索框（Search organizations... + 清空/加载态）+ grid/list 视图切换
/// （large 大卡片 / compact 紧凑卡片，默认 large，对齐 page.tsx:44）+
/// 三分区（My Organization / Pending Approval / Recommended，前后两个可
/// 折叠）+ 分页 Load more（fetch 24 / 显示批次 18，对齐 page.tsx:31-33）。
/// 数据：GET /org/my（role≠'' 为已加入；request_status=pending 为待审批）
/// + GET /orgs?keyword&limit&offset（排除前两类 = 推荐）。
class OrganizationPage extends StatefulWidget {
  const OrganizationPage({super.key});

  @override
  State<OrganizationPage> createState() => _OrganizationPageState();
}

class _OrganizationPageState extends State<OrganizationPage> {
  /// 无自定义封面时的默认 banner，对齐 web DEFAULT_ORG_BANNER
  /// （OrgBrandingEditor.tsx: "/images/org-card.png"，401x120）。
  static const kDefaultOrgBanner = 'assets/images/org-card.png';

  // 对齐 web page.tsx:31-33 的分页常量。
  static const _fetchSize = 24;
  static const _displayBatch = 18;
  static const _displayMultiple = 6;

  final _service = AccountService();
  final _searchCtrl = TextEditingController();
  Timer? _searchDebounce;

  List<Map<String, dynamic>> _memberOrgs = [];
  List<Map<String, dynamic>> _pendingOrgs = [];
  List<Map<String, dynamic>> _allOrgs = [];
  int _total = 0;
  int _visibleTarget = _displayBatch;

  /// 已生效的搜索关键词（debounce 300ms 后写入，对齐 page.tsx:46）。
  String _keyword = '';
  int _keywordSeq = 0; // 关键词竞态守卫（对齐 page.tsx latestKeywordRef）

  bool _loading = true; // 首屏加载
  bool _searching = false; // 关键词触发的 /orgs 重新加载
  bool _loadingMore = false;
  String? _error;
  String? _copiedSlug;

  /// false=large 大卡片（web 默认，page.tsx:44）；true=compact 紧凑卡片。
  bool _compact = false;
  bool _myCollapsed = false;
  bool _recommendedCollapsed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── 数据加载 ──────────────────────────────────────────────────

  List<Map<String, dynamic>> get _recommendedOrgs {
    final knownIds = <String>{
      for (final o in _memberOrgs) (o['id'] ?? '').toString(),
      for (final o in _pendingOrgs) (o['id'] ?? '').toString(),
    };
    return _allOrgs
        .where((o) => !knownIds.contains((o['id'] ?? '').toString()))
        .toList();
  }

  bool get _hasMoreOrgs => _allOrgs.length < _total;

  /// 对齐 web getVisibleRecommendedCount（page.tsx:370-374）：还有更多时
  /// 只显示到 6 的整数倍，避免尾行残缺。
  int get _visibleRecommendedCount {
    final capped = _recommendedOrgs.length < _visibleTarget
        ? _recommendedOrgs.length
        : _visibleTarget;
    if (!_hasMoreOrgs) return capped;
    return (capped ~/ _displayMultiple) * _displayMultiple;
  }

  bool get _canLoadMoreOrgs =>
      _visibleRecommendedCount < _recommendedOrgs.length || _hasMoreOrgs;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final seq = ++_keywordSeq;
    try {
      final results = await Future.wait<dynamic>([
        _service.getMyOrganizations(),
        _service.listOrgs(
            keyword: _keyword, limit: _fetchSize, offset: 0),
      ]);
      if (!mounted || seq != _keywordSeq) return;
      final my = (results[0] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      final listResp = results[1] as Map<String, dynamic>;
      final member = <Map<String, dynamic>>[];
      final pending = <Map<String, dynamic>>[];
      for (final o in my) {
        final role = (o['role'] ?? '').toString();
        if (role.isNotEmpty) {
          member.add(o);
        } else if ((o['request_status'] ?? '').toString() == 'pending') {
          pending.add(o);
        }
      }
      setState(() {
        _memberOrgs = member;
        _pendingOrgs = pending;
        _allOrgs = (listResp['organizations'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _total = (listResp['total'] as num?)?.toInt() ?? 0;
        _visibleTarget = _displayBatch;
        _loading = false;
        _searching = false;
      });
      unawaited(_topUpRecommended());
    } catch (e) {
      if (!mounted || seq != _keywordSeq) return;
      setState(() {
        _error = e.toString();
        _loading = false;
        _searching = false;
      });
    }
  }

  /// 搜索输入 → 300ms debounce（对齐 page.tsx:46 useDebounce(wait:300)）。
  void _onSearchChanged(String v) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _applyKeyword(v.trim());
    });
  }

  Future<void> _applyKeyword(String keyword) async {
    if (keyword == _keyword) return;
    _keyword = keyword;
    final seq = ++_keywordSeq;
    setState(() {
      _searching = true;
      _visibleTarget = _displayBatch;
    });
    try {
      final resp = await _service.listOrgs(
          keyword: keyword, limit: _fetchSize, offset: 0);
      if (!mounted || seq != _keywordSeq) return;
      setState(() {
        _allOrgs = (resp['organizations'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _total = (resp['total'] as num?)?.toInt() ?? 0;
        _searching = false;
      });
      unawaited(_topUpRecommended());
    } catch (_) {
      if (!mounted || seq != _keywordSeq) return;
      setState(() => _searching = false);
    }
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchCtrl.clear();
    _applyKeyword('');
  }

  Future<void> _fetchMoreOrgs() async {
    if (_loadingMore || !_hasMoreOrgs) return;
    setState(() => _loadingMore = true);
    final seq = _keywordSeq;
    try {
      final resp = await _service.listOrgs(
          keyword: _keyword, limit: _fetchSize, offset: _allOrgs.length);
      if (!mounted || seq != _keywordSeq) return;
      setState(() {
        _allOrgs = [
          ..._allOrgs,
          ...(resp['organizations'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e)),
        ];
        _total = (resp['total'] as num?)?.toInt() ?? _total;
      });
    } catch (_) {
      // 静默：下拉刷新可重试
    } finally {
      if (mounted && seq == _keywordSeq) {
        setState(() => _loadingMore = false);
      }
    }
  }

  /// 已加入/待审批会占掉 /orgs 返回额度，推荐不足一批时自动补拉
  /// （对齐 page.tsx:138-152 的 auto fetchMore effect）。
  Future<void> _topUpRecommended() async {
    var guard = 0;
    while (mounted &&
        _hasMoreOrgs &&
        !_loadingMore &&
        _recommendedOrgs.length < _visibleTarget &&
        guard < 5) {
      guard++;
      await _fetchMoreOrgs();
    }
  }

  Future<void> _loadMoreOrgs() async {
    if (_loadingMore || !_canLoadMoreOrgs) return;
    setState(() => _visibleTarget += _displayBatch);
    if (_recommendedOrgs.length < _visibleTarget && _hasMoreOrgs) {
      await _fetchMoreOrgs();
    }
  }

  // ── 导航/动作 ─────────────────────────────────────────────────

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

  // ── 页面骨架 ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DinqTokens.bgPage,
      appBar: DefaultAppBar(
        context,
        titleString: 'Organization',
        actions: [
          // 黑底 Create 按钮（对齐 web list header，page.tsx:179-186）
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _openCreate,
                child: Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF171717),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.add, size: 14, color: Colors.white),
                      SizedBox(width: 6),
                      Text('Create',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white)),
                    ],
                  ),
                ),
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
    final empty = _keyword.isEmpty &&
        _memberOrgs.isEmpty &&
        _pendingOrgs.isEmpty &&
        _recommendedOrgs.isEmpty &&
        !_hasMoreOrgs;
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

    final visibleRecommended =
        _recommendedOrgs.take(_visibleRecommendedCount).toList();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          // 搜索框 + 视图切换（对齐 page.tsx:199-223）
          Row(
            children: [
              Expanded(child: _searchField()),
              const SizedBox(width: 12),
              _viewToggle(),
            ],
          ),
          const SizedBox(height: 24),
          if (_memberOrgs.isNotEmpty)
            _section('My Organization', _memberOrgs,
                collapsed: _myCollapsed,
                onToggleCollapse: () =>
                    setState(() => _myCollapsed = !_myCollapsed)),
          if (_pendingOrgs.isNotEmpty)
            _section('Pending Approval', _pendingOrgs,
                count: _pendingOrgs.length),
          if (visibleRecommended.isNotEmpty ||
              _canLoadMoreOrgs ||
              _keyword.isNotEmpty)
            _recommendedSection(visibleRecommended),
        ],
      ),
    );
  }

  /// 搜索框（对齐 page.tsx:200-221）：左侧放大镜、右侧加载中转圈 /
  /// 有输入时的清空按钮。
  Widget _searchField() {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: color),
        );
    Widget? suffix;
    if (_searching) {
      suffix = const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: Color(0xFF9E9B93)),
        ),
      );
    } else if (_searchCtrl.text.isNotEmpty) {
      suffix = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _clearSearch,
        child: const Icon(Icons.close_rounded,
            size: 16, color: Color(0xFF9E9B93)),
      );
    }
    return SizedBox(
      height: 40,
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) {
          setState(() {}); // 刷新清空按钮显隐
          _onSearchChanged(v);
        },
        style: const TextStyle(fontSize: 14, color: Color(0xFF2A2826)),
        decoration: InputDecoration(
          hintText: 'Search organizations...',
          hintStyle: const TextStyle(fontSize: 14, color: Color(0xFFB9B6AE)),
          filled: true,
          fillColor: Colors.white,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          prefixIcon: const Icon(Icons.search_rounded,
              size: 18, color: Color(0xFF9E9B93)),
          suffixIcon: suffix,
          suffixIconConstraints:
              const BoxConstraints(minWidth: 40, minHeight: 40),
          // 全局 inputDecorationTheme 会覆盖 border，三种状态都要显式指定
          border: border(const Color(0xFFE6E3DD)),
          enabledBorder: border(const Color(0xFFE6E3DD)),
          focusedBorder: border(const Color(0xFF9E9B93)),
        ),
      ),
    );
  }

  /// grid/list 视图切换（对齐 web ViewModeToggle，page.tsx:376-415）。
  Widget _viewToggle() {
    return Container(
      height: 40,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F4F0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _viewToggleButton(
              icon: Icons.grid_view_rounded,
              active: !_compact,
              onTap: () => setState(() => _compact = false)),
          const SizedBox(width: 4),
          _viewToggleButton(
              icon: Icons.table_rows_rounded,
              active: _compact,
              onTap: () => setState(() => _compact = true)),
        ],
      ),
    );
  }

  Widget _viewToggleButton(
      {required IconData icon,
      required bool active,
      required VoidCallback onTap}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: active
              ? const [
                  BoxShadow(
                      color: Color(0x0D000000),
                      offset: Offset(0, 1),
                      blurRadius: 3),
                ]
              : null,
        ),
        child: Icon(icon,
            size: 16,
            color: active ? const Color(0xFF171717) : const Color(0xFF8A8880)),
      ),
    );
  }

  // ── 分区 ─────────────────────────────────────────────────────

  Widget _sectionHeader(String title,
      {int? count, bool? collapsed, VoidCallback? onToggleCollapse}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
          if (onToggleCollapse != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onToggleCollapse,
              child: SizedBox(
                width: 24,
                height: 24,
                child: Icon(
                  collapsed == true
                      ? Icons.keyboard_arrow_down_rounded
                      : Icons.keyboard_arrow_up_rounded,
                  size: 16,
                  color: const Color(0xFF9E9B93),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _section(String title, List<Map<String, dynamic>> orgs,
      {int? count, bool collapsed = false, VoidCallback? onToggleCollapse}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(title,
            count: count,
            collapsed: collapsed,
            onToggleCollapse: onToggleCollapse),
        if (!collapsed)
          for (final o in orgs)
            Padding(
              // 卡片间距：large gap-5=20 / compact gap-3=12（page.tsx:364-368）
              padding: EdgeInsets.only(bottom: _compact ? 12 : 20),
              child: _orgCard(o),
            ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _recommendedSection(List<Map<String, dynamic>> visible) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Recommended',
            collapsed: _recommendedCollapsed,
            onToggleCollapse: () => setState(
                () => _recommendedCollapsed = !_recommendedCollapsed)),
        if (!_recommendedCollapsed) ...[
          for (final o in visible)
            Padding(
              padding: EdgeInsets.only(bottom: _compact ? 12 : 20),
              child: _orgCard(o),
            ),
          // 搜索无结果（对齐 page.tsx:321-328）
          if (visible.isEmpty &&
              _keyword.isNotEmpty &&
              !_searching &&
              !_canLoadMoreOrgs)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE6E3DD)),
              ),
              child: const Text('No organizations found.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Color(0xFF9E9B93))),
            ),
          // Load more（对齐 page.tsx:329-341）
          if (_canLoadMoreOrgs)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Center(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _loadingMore ? null : _loadMoreOrgs,
                  child: Opacity(
                    opacity: _loadingMore ? 0.6 : 1,
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE6E3DD)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_loadingMore) ...[
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Color(0xFF6B6862)),
                            ),
                            const SizedBox(width: 8),
                          ],
                          const Text('Load more',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF6B6862))),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
        const SizedBox(height: 20),
      ],
    );
  }

  // ── 卡片 ─────────────────────────────────────────────────────

  Widget _orgCard(Map<String, dynamic> o) =>
      _compact ? _compactCard(o) : _largeCard(o);

  /// 紧凑卡片（对齐 web OrganizationCard compact 分支，page.tsx:472-537）：
  /// 小 logo + 名称 + Pending/角色徽章 + 「类型 · 👥N」+ 描述纯文本
  /// （无灰底容器，空时 "No description yet" 占位）+ 底部地点/slug。
  Widget _compactCard(Map<String, dynamic> o) {
    final name = (o['name'] ?? '').toString();
    final slug = (o['slug'] ?? '').toString();
    final orgType = (o['org_type'] ?? '').toString();
    final description = (o['description'] ?? '').toString();
    final location = (o['location'] ?? '').toString();
    final memberCount = (o['member_count'] as num?)?.toInt();
    final role = (o['role'] ?? '').toString();
    final isPending =
        role.isEmpty && (o['request_status'] ?? '').toString() == 'pending';
    final pendingRequests = (o['pending_request_count'] as num?)?.toInt() ?? 0;
    final canManage = role == 'owner' || role == 'admin';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openDetail(o),
      child: Container(
        height: 136,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        // 边框画在内容之上，防止内容在圆角处压线（全仓修复模式）
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8E6E1)),
        ),
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _avatar(o, small: true,
                    pendingCount: canManage ? pendingRequests : 0),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.25,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF1F1F1F))),
                          ),
                          const SizedBox(width: 8),
                          if (isPending)
                            _pendingPill()
                          else if (role.isNotEmpty)
                            _rolePill(role),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (orgType.isNotEmpty) ...[
                            Text(_capitalize(orgType),
                                style: const TextStyle(
                                    fontSize: 12, color: Color(0xFF9E9B93))),
                            if (memberCount != null)
                              const Text(' · ',
                                  style: TextStyle(
                                      fontSize: 12, color: Color(0xFF9E9B93))),
                          ],
                          if (memberCount != null) ...[
                            const Icon(Icons.people_outline,
                                size: 14, color: Color(0xFF9E9B93)),
                            const SizedBox(width: 4),
                            Text('$memberCount',
                                style: const TextStyle(
                                    fontSize: 12, color: Color(0xFF9E9B93))),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // 描述纯文本，固定两行高（web h-[39px]，page.tsx:508-516）
            SizedBox(
              height: 39,
              width: double.infinity,
              child: Text(
                description.isNotEmpty ? description : 'No description yet',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12,
                    height: 1.625,
                    color: description.isNotEmpty
                        ? const Color(0xFF8A8880)
                        : const Color(0xFFC8C6C1)),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: location.isEmpty
                      ? const SizedBox.shrink()
                      : Row(
                          children: [
                            const Icon(Icons.place_outlined,
                                size: 14, color: Color(0xFFB5B1A8)),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 11, color: Color(0xFFB5B1A8))),
                            ),
                          ],
                        ),
                ),
                if (slug.isNotEmpty)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _copySlugLink(slug),
                    child: Text(
                      _copiedSlug == slug ? 'Copied!' : 'dinq.me/$slug',
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: _copiedSlug == slug
                            ? const Color(0xFF2A5E52)
                            : const Color(0xFFB5B1A8),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 大卡片（对齐 web OrganizationCard large 分支，page.tsx:540-651）：
  /// banner + 叠加 logo + 名称/徽章 + 类型·成员数 + 描述/标签灰底框 +
  /// 地点 | dinq.me/slug 复制，整体固定高 352（web h-[352px]）。
  Widget _largeCard(Map<String, dynamic> o) {
    final name = (o['name'] ?? '').toString();
    final slug = (o['slug'] ?? '').toString();
    final backgroundUrl = (o['background_url'] ?? '').toString();
    final orgType = (o['org_type'] ?? '').toString();
    final description = (o['description'] ?? '').toString();
    final location = (o['location'] ?? '').toString();
    final tags = _parseTags(o['tags']);
    final memberCount = (o['member_count'] as num?)?.toInt();
    final role = (o['role'] ?? '').toString();
    final isPending =
        role.isEmpty && (o['request_status'] ?? '').toString() == 'pending';
    final pendingRequests = (o['pending_request_count'] as num?)?.toInt() ?? 0;
    final canManage = role == 'owner' || role == 'admin';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openDetail(o),
      child: Container(
        height: 352,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        // 边框画在内容之上（foregroundDecoration）：banner 图在圆角处的
        // 抗锯齿溢出会被边框盖住，避免角上出现截断/锯齿
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE8E6E1)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // banner（对齐 web：background_url 为空或加载失败时回退默认
            // banner 素材，而不是灰底）
            SizedBox(
              height: 120,
              width: double.infinity,
              child: backgroundUrl.isNotEmpty
                  ? Image.network(backgroundUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          Image.asset(kDefaultOrgBanner, fit: BoxFit.cover))
                  : Image.asset(kDefaultOrgBanner, fit: BoxFit.cover),
            ),
            Expanded(
              child: Padding(
                // web px-5 pb-3.5（page.tsx:553）
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // logo 叠加 banner 下缘：-mt-6 mb-2.5 → 占位 34 高，
                    // 上溢 24 画进 banner 区域
                    SizedBox(
                      height: 34,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            top: -24,
                            left: 0,
                            child: _avatar(o,
                                pendingCount:
                                    canManage ? pendingRequests : 0),
                          ),
                        ],
                      ),
                    ),
                    // 名称 + 状态徽章（徽章紧跟名称，web gap-2）
                    Row(
                      children: [
                        Flexible(
                          child: Text(name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.25,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1F1F1F))),
                        ),
                        const SizedBox(width: 8),
                        if (isPending)
                          _pendingPill()
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
                                  fontSize: 12, color: Color(0xFF9E9B93))),
                          if (memberCount != null)
                            const Text(' · ',
                                style: TextStyle(
                                    fontSize: 12, color: Color(0xFF9E9B93))),
                        ],
                        if (memberCount != null) ...[
                          const Icon(Icons.people_outline,
                              size: 16, color: Color(0xFF9E9B93)),
                          const SizedBox(width: 4),
                          Text(
                              '$memberCount member${memberCount == 1 ? '' : 's'}',
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF9E9B93))),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    // 描述/标签灰底框（撑满剩余高度，web flex-1）
                    Expanded(
                      child: Container(
                        width: double.infinity,
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (description.isNotEmpty)
                                    Text(description,
                                        maxLines: tags.isNotEmpty ? 2 : 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            height: 1.625,
                                            color: Color(0xFF8A8880))),
                                  if (tags.isNotEmpty)
                                    // tags 贴底（web mt-auto），超出灰底框
                                    // 裁剪（web overflow-hidden）
                                    Expanded(
                                      child: Align(
                                        alignment: Alignment.bottomLeft,
                                        child: ClipRect(
                                          child: Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: [
                                              for (final t in tags)
                                                Container(
                                                  height: 28,
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 10),
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                        0x1A888888),
                                                    borderRadius:
                                                        BorderRadius
                                                            .circular(4),
                                                  ),
                                                  // 注意不能用 Container.alignment
                                                  // （会撑满可用宽度）；chip 宽度
                                                  // 须随内容自适应（web w-fit）
                                                  child: Center(
                                                    widthFactor: 1,
                                                    child: Text(t,
                                                        style: const TextStyle(
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w500,
                                                            color: Color(
                                                                0xFF171717))),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
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
                                        size: 16, color: Color(0xFF9E9B93)),
                                    const SizedBox(width: 6),
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
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // web 的 DINQ 定制 slug 图标（page.tsx svg）
                                SvgPicture.asset(
                                  'assets/icons/dinq-slug.svg',
                                  width: 14,
                                  height: 14,
                                  colorFilter: ColorFilter.mode(
                                    _copiedSlug == slug
                                        ? const Color(0xFF2A5E52)
                                        : const Color(0xFF9E9B93),
                                    BlendMode.srcIn,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
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
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 组织头像（对齐 web OrgAvatar，page.tsx:703-740）：
  /// md=48/圆角10，sm=36/圆角8；无 logo 用 nameToAvatarColor 底色 +
  /// 双字母缩写；管理员可见的待审批红点角标。
  Widget _avatar(Map<String, dynamic> o,
      {bool small = false, int pendingCount = 0}) {
    final name = (o['name'] ?? '').toString();
    final logoUrl = (o['logo_url'] ?? '').toString();
    final size = small ? 36.0 : 48.0;
    final radius = small ? 8.0 : 10.0;

    Widget fallback() => Container(
          color: orgAvatarColor(name),
          alignment: Alignment.center,
          child: Text(orgInitials(name),
              style: TextStyle(
                  fontSize: small ? 14 : 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F1F1F))),
        );

    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7F4),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0D000000), offset: Offset(0, 1), blurRadius: 2),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: logoUrl.isNotEmpty
          ? Image.network(logoUrl,
              fit: BoxFit.cover, errorBuilder: (_, _, _) => fallback())
          : fallback(),
    );

    if (pendingCount <= 0) return avatar;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          right: -4,
          top: -4,
          child: Container(
            constraints: const BoxConstraints(minWidth: 20),
            height: 20,
            padding: const EdgeInsets.symmetric(horizontal: 5),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              pendingCount > 99 ? '99+' : '$pendingCount',
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  /// Pending 徽章：时钟 icon + 文案（对齐 web PendingPill，page.tsx:658-679）。
  Widget _pendingPill() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0x14C06224),
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule_rounded, size: 12, color: Color(0xFFE2703A)),
            SizedBox(width: 4),
            Text('Pending',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE2703A))),
          ],
        ),
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

  /// tags 容错解析：标准返回为 string[]（web Organization.tags），个别
  /// 序列化会给逗号拼接字符串，这里统一拆成逐个 tag，避免整串渲染成
  /// 一个 chip 或 cast 崩溃。
  static List<String> _parseTags(dynamic raw) {
    if (raw is List) {
      return raw
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (raw is String) {
      return raw
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const <String>[];
  }
}
