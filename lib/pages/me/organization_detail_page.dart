import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/organization_share_models.dart';
import '../../services/account_service.dart';
import '../../stores/user_store.dart';
import '../../theme/dinq_tokens.dart';
import '../../utils/color_util.dart';
import '../../utils/org_avatar.dart';
import '../../widgets/common/default_app_bar.dart';
import '../../widgets/inbox/create_team_recruit_sheet.dart';
import '../../widgets/organization/invite_org_sheet.dart';
import '../../widgets/organization/org_settings_sheet.dart';
import '../../widgets/profile/share_organization_dialog.dart';

/// My → Organization → 详情。对齐 web organization/[slug]：
/// 封面头图 + 叠加 logo + 组织名/成员数/地点/tags/描述 + 加入按钮状态机
/// （Join / Requested / Request again / 成员则 Chat）+ 四个 tab
/// （Cards / Members / Chat / Team，非成员对后三个 tab 显示 LockedGate）。
/// 数据：GET /org/profile?slug=（含 viewer 上下文）+ 各 tab 接口。
class OrganizationDetailPage extends StatefulWidget {
  final Map<String, dynamic> org;
  const OrganizationDetailPage({super.key, required this.org});

  @override
  State<OrganizationDetailPage> createState() => _OrganizationDetailPageState();
}

class _OrganizationDetailPageState extends State<OrganizationDetailPage> {
  /// 无自定义封面时的默认 banner，对齐 web DEFAULT_ORG_BANNER
  /// （OrgBrandingEditor.tsx: "/images/org-card.png"，401x120）。
  static const kDefaultOrgBanner = 'assets/images/org-card.png';

  final _service = AccountService();

  late Map<String, dynamic> _org;
  List<dynamic> _members = [];
  List<dynamic> _requests = [];
  List<dynamic> _cards = [];
  List<dynamic> _recruits = [];
  bool _cardsLoaded = false;
  bool _recruitsLoaded = false;
  bool _loading = true;
  bool _joining = false;
  bool _refreshing = false;
  bool _openingChat = false;
  bool _creatingRecruit = false;
  int _tab = 0; // 0 Cards / 1 Members / 2 Chat / 3 Team
  // Team tab 子筛选（对齐 web OrgTeamView TeamView "mine"/"all"）：
  // 0 My Team / 1 All Teams；仅当用户参与了组队时展示切换。
  int _teamView = 0;
  late String _inviteCode;

  static const _tabs = ['Cards', 'Members', 'Chat', 'Team'];

  // web tags 的 8 种 pastel 背景循环
  static const _tagPalette = [
    Color(0xFFFDE277), Color(0xFFFED7D7), Color(0xFFD6F995),
    Color(0xFFC6E2FF), Color(0xFFE2C6FF), Color(0xFFFFE4CC),
    Color(0xFFD4F4DD), Color(0xFFFFD6E8),
  ];

  // 对齐 web MAX_TAGS / MAX_TAG_LENGTH（OrgProfileHeader.tsx:60-61）
  static const _kMaxTags = 5;
  static const _kMaxTagLength = 20;

  String get _id => (_org['id'] ?? '').toString();
  String get _slug => (_org['slug'] ?? '').toString();

  String get _role {
    final viewer = _org['viewer'];
    if (viewer is Map && viewer['role'] != null) {
      return viewer['role'].toString();
    }
    return (_org['role'] ?? _org['my_role'] ?? '').toString();
  }

  /// member / pending / rejected / none（对齐 web joinStatus）
  String get _joinStatus {
    if (_role.isNotEmpty) return 'member';
    final viewer = _org['viewer'];
    final rs = viewer is Map
        ? (viewer['request_status'] ?? '').toString()
        : (_org['request_status'] ?? '').toString();
    if (rs == 'pending') return 'pending';
    if (rs == 'rejected') return 'rejected';
    return 'none';
  }

  bool get _isMember => _joinStatus == 'member';
  bool get _isManager => _role == 'owner' || _role == 'admin';

  @override
  void initState() {
    super.initState();
    _org = Map<String, dynamic>.from(widget.org);
    _inviteCode = (_org['invite_code'] ?? '').toString();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    // 刷新组织档案（拿 viewer 上下文/main_conversation_id 等）
    try {
      if (_slug.isNotEmpty) {
        final profile = await _service.getOrgProfile(_slug);
        if (profile.isNotEmpty) {
          _org = {..._org, ...profile};
          final code = (_org['invite_code'] ?? '').toString();
          if (code.isNotEmpty) _inviteCode = code;
        }
      }
    } catch (_) {}
    // 成员/审批（非成员会 403，静默忽略）
    try {
      _members = await _service.getOrgMembers(_id);
    } catch (_) {
      _members = const [];
    }
    if (_isManager) {
      try {
        _requests = await _service.getOrgJoinRequests(_id);
      } catch (_) {}
    }
    if (mounted) setState(() => _loading = false);
    _loadTabData();
  }

  Future<void> _loadTabData() async {
    if (_tab == 0 && !_cardsLoaded) {
      try {
        _cards = await _service.getOrgCardBoard(_id);
      } catch (_) {}
      _cardsLoaded = true;
      if (mounted) setState(() {});
    }
    if (_tab == 3 && !_recruitsLoaded && _isMember) {
      try {
        _recruits = await _service.getOrgTeamRecruits(_id);
      } catch (_) {}
      _recruitsLoaded = true;
      if (mounted) setState(() {});
    }
  }

  Future<void> _requestJoin() async {
    if (_joining) return;
    setState(() => _joining = true);
    try {
      final status = await _service.requestJoinOrg(_id);
      if (!mounted) return;
      if (status == 'already_member') {
        _snack('You are already a member');
      } else {
        _snack('Join request sent — waiting for approval');
        setState(() {
          final viewer = Map<String, dynamic>.from(
              (_org['viewer'] as Map?)?.cast<String, dynamic>() ?? {});
          viewer['request_status'] = 'pending';
          _org['viewer'] = viewer;
          _org['request_status'] = 'pending';
        });
      }
    } catch (e) {
      _snack('Request failed: $e');
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  OrganizationShareTarget _orgShareTarget() {
    final name = (_org['name'] ?? 'Organization').toString();
    final logoUrl = (_org['logo_url'] ?? '').toString();
    final description = (_org['description'] ?? '').toString();
    final location = (_org['location'] ?? '').toString();
    final tags = _parseTags(_org['tags']);
    final memberCount =
        (_org['member_count'] as num?)?.toInt() ?? _members.length;
    return OrganizationShareTarget(
      slug: _slug,
      name: name,
      description: description.isNotEmpty ? description : null,
      logoUrl: logoUrl.isNotEmpty ? logoUrl : null,
      tags: tags,
      location: location.isNotEmpty ? location : null,
      memberCount: memberCount,
    );
  }

  /// 右上分享：打开组织专用 ShareOrganizationDialog。
  Future<void> _share() async {
    if (_slug.isEmpty) return;
    if (!mounted) return;
    await ShareOrganizationDialog.show(
      context: context,
      organization: _orgShareTarget(),
    );
  }

  /// 邀请链接对齐 web InviteOrgModal.tsx:33-36：{origin}/join/{invite_code}，
  /// 邀请码小写原样（此前误用 /invite/ 路径 + 大写，链接打不开）。
  String get _inviteLink =>
      _inviteCode.isEmpty ? '' : 'https://dinq.me/join/$_inviteCode';

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
      setState(() => _requests = _requests
          .where((r) => (r as Map)['id'].toString() != rid)
          .toList());
      _snack(action == 'approved' ? 'Request approved' : 'Request rejected');
    } catch (e) {
      _snack('Failed: $e');
    }
  }

  /// 取组织主群聊 conv_id。新建组织后主群聊由后端异步创建（web
  /// organizationApi.create 注释「后端会异步创建群聊」；OrgChatView.tsx
  /// isPreparing 分支通过 refreshOrg 重拉 org profile 拿
  /// main_conversation_id）。App 对应做法：本地没有 conv_id 时重拉一次
  /// /org/profile；仍拿不到返回空串，由调用方 toast 提示。
  Future<String> _resolveMainConversationId() async {
    var convId = (_org['main_conversation_id'] ?? '').toString();
    if (convId.isEmpty && _slug.isNotEmpty) {
      try {
        final profile = await _service.getOrgProfile(_slug);
        if (profile.isNotEmpty) {
          _org = {..._org, ...profile};
        }
        convId = (_org['main_conversation_id'] ?? '').toString();
      } catch (_) {
        // 网络失败走调用方统一的 toast 反馈
      }
    }
    return convId;
  }

  /// 打开组织主群聊；conv_id 拿不到时 toast 提示，不允许静默无反应。
  Future<void> _openChat() async {
    if (_openingChat) return;
    setState(() => _openingChat = true);
    String convId;
    try {
      convId = await _resolveMainConversationId();
    } finally {
      if (mounted) setState(() => _openingChat = false);
    }
    if (!mounted) return;
    if (convId.isEmpty) {
      _snack('Chat is still being set up — please try again in a moment');
      return;
    }
    context.push('/admin/inbox/$convId');
  }

  /// Team tab「+」发起组队（对齐 web layout.tsx:442-451 的
  /// Start team recruit 按钮 → CreateTeamRecruitModal，目标会话为组织主
  /// 群聊 main_conversation_id，layout.tsx:336-345）。创建成功后重拉
  /// Team tab 列表并切回 My Team 子筛选（web 通过 teamRecruitsRefreshKey
  /// 触发重拉；OrgTeamView.tsx:134-138 myTeam 出现后 view 自动回 mine）。
  Future<void> _openCreateRecruit() async {
    if (_creatingRecruit) return;
    setState(() => _creatingRecruit = true);
    String convId;
    try {
      convId = await _resolveMainConversationId();
    } finally {
      if (mounted) setState(() => _creatingRecruit = false);
    }
    if (!mounted) return;
    if (convId.isEmpty) {
      _snack('Chat is still being set up — please try again in a moment');
      return;
    }
    final message = await CreateTeamRecruitSheet.show(
      context: context,
      conversationId: convId,
    );
    if (message == null || !mounted) return;
    setState(() {
      _teamView = 0;
      _recruitsLoaded = false;
    });
    _loadTabData();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DinqTokens.bgPage,
      // 分享入口移到封面右上（对齐 web OrgProfileHeader.tsx:194-204，
      // share 按钮叠在 banner 上而不是页面顶栏）
      appBar: DefaultAppBar(context, titleString: ''),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : RefreshIndicator(
              onRefresh: () async {
                _cardsLoaded = false;
                _recruitsLoaded = false;
                await _load();
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                children: [
                  _header(),
                  const SizedBox(height: 20),
                  _tabBar(),
                  const SizedBox(height: 16),
                  _tabContent(),
                ],
              ),
            ),
    );
  }

  // ── 头部（白底卡片：封面 + logo + 信息 + CTA + tags + 描述）─────
  /// 对齐 web OrgProfileHeader.tsx:188-348：整体是一张白底圆角卡片
  /// （rounded-2xl=16 + 边框 #E8E6E1 叠加在最上层），banner 在卡片顶部，
  /// 分享按钮叠在 banner 右上；字段顺序为 名称 → 成员数 → 地点 → CTA →
  /// tags → 描述。
  Widget _header() {
    final name = (_org['name'] ?? 'Organization').toString();
    final logoUrl = (_org['logo_url'] ?? '').toString();
    final backgroundUrl = (_org['background_url'] ?? '').toString();
    final location = (_org['location'] ?? '').toString();
    final description = (_org['description'] ?? '').toString();
    final tags = _parseTags(_org['tags']);
    final memberCount =
        (_org['member_count'] as num?)?.toInt() ?? _members.length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      // 边框画在内容之上（foregroundDecoration），防止 banner 在圆角处压线
      // （对齐 web 的 absolute inset-0 border 叠层，OrgProfileHeader.tsx:344-347）
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E6E1)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 封面（401:120）。对齐 web：background_url 为空或加载失败时
          // 回退默认 banner 素材，而不是灰底
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 401 / 120,
                child: SizedBox(
                  width: double.infinity,
                  child: backgroundUrl.isNotEmpty
                      ? Image.network(backgroundUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Image.asset(
                              kDefaultOrgBanner,
                              fit: BoxFit.cover))
                      : Image.asset(kDefaultOrgBanner, fit: BoxFit.cover),
                ),
              ),
              // banner 右上操作区（web OrgProfileHeader.tsx:194-236）：
              // 分享 + 管理员更多菜单。icon 对齐 web：Share2（节点分享）/
              // MoreHorizontal，h-8 w-8 rounded-lg 无底色、#6b6862。
              Positioned(
                top: 12,
                right: 12,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _share,
                      child: Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.share_outlined,
                            size: 16, color: Color(0xFF6B6862)),
                      ),
                    ),
                    // 更多菜单：仅 owner/admin（web canManage，
                    // OrgProfileHeader.tsx:205-235）；Settings 两者可见，
                    // Delete 仅 owner（web canDelete，layout.tsx:62-63）。
                    if (_isManager) ...[
                      const SizedBox(width: 4),
                      _moreMenuButton(),
                    ],
                  ],
                ),
              ),
            ],
          ),
          Padding(
            // web px-5 pb-6（OrgProfileHeader.tsx:239）
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // logo 140、圆角24、上溢 70 叠在 banner 上，下方留 24
                // （web -mt-[70px] mb-6，logoSize=140，rounded-3xl）
                SizedBox(
                  height: 94, // 140 - 70(上溢) + 24(mb-6)
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(top: -70, left: 0, child: _logo(logoUrl, name)),
                    ],
                  ),
                ),
                // 名称（web text-[32px] leading-[40px] font-semibold）
                Text(name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 32,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF171717))),
                const SizedBox(height: 4),
                // 成员数（独立一行，web OrgProfileHeader.tsx:263-268）
                Row(
                  children: [
                    const Icon(Icons.people_outline,
                        size: 16, color: Color(0xA3303030)),
                    const SizedBox(width: 6),
                    Text('$memberCount member${memberCount == 1 ? '' : 's'}',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF171717))),
                  ],
                ),
                // 地点（独立一行，web OrgProfileHeader.tsx:271-291)
                if (location.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.place_outlined,
                          size: 16, color: Color(0xA3303030)),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF171717))),
                      ),
                    ],
                  ),
                ],
                // CTA 紧跟档案字段（web OrgProfileHeader.tsx:293-307，
                // 在 tags/描述之前）
                const SizedBox(height: 12),
                _ctaButton(),
                // Tags（web TagsSection，OrgProfileHeader.tsx:410-583）：
                // 管理员即使 0 个 tag 也显示（有「+」添加入口）；
                // 非管理员无 tag 时整块隐藏（tsx:430）。
                if (tags.isNotEmpty || _isManager) ...[
                  const SizedBox(height: 16),
                  _tagsSection(tags),
                ],
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  // web text-[16px] leading-[24px] text-[#171717]
                  Text(description,
                      style: const TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: Color(0xFF171717))),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 组织 logo（对齐 web OrgLogo，OrgProfileHeader.tsx:828-853）：
  /// 140、rounded-3xl(24)；有图时带 #EEEDE9 边框；无图用
  /// nameToAvatarColor 底色 + 双字母缩写（text-[3.5rem]=56）。
  Widget _logo(String logoUrl, String name) {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        color: logoUrl.isNotEmpty
            ? const Color(0xFFF8F7F4)
            : orgAvatarColor(name.isNotEmpty ? name : '?'),
        borderRadius: BorderRadius.circular(24),
        border: logoUrl.isNotEmpty
            ? Border.all(color: const Color(0xFFEEEDE9))
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: logoUrl.isNotEmpty
          ? Image.network(logoUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _logoInitial(name))
          : _logoInitial(name),
    );
  }

  // ── 更多菜单 / 设置 / 删除（对齐 web OrgProfileHeader.tsx:205-235）──

  /// banner 右上「…」菜单：Settings（owner/admin）+ Delete（仅 owner，红色，
  /// 分隔线隔开），菜单宽 176（web w-44），入口按钮样式与分享一致。
  Widget _moreMenuButton() {
    return PopupMenuButton<String>(
      tooltip: 'More',
      position: PopupMenuPosition.under,
      color: Colors.white,
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFEEEDE9)),
      ),
      constraints: const BoxConstraints.tightFor(width: 176),
      onSelected: (v) {
        if (v == 'settings') _openSettingsSheet();
        if (v == 'delete') _confirmDeleteOrg();
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'settings',
          height: 40,
          child: Row(
            children: [
              Icon(Icons.settings_outlined, size: 14, color: Color(0xFF171717)),
              SizedBox(width: 8),
              Text('Settings',
                  style: TextStyle(fontSize: 14, color: Color(0xFF171717))),
            ],
          ),
        ),
        if (_role == 'owner') ...[
          const PopupMenuDivider(height: 1),
          const PopupMenuItem(
            value: 'delete',
            height: 40,
            child: Row(
              children: [
                Icon(Icons.delete_outline, size: 14, color: Color(0xFFDC2626)),
                SizedBox(width: 8),
                Text('Delete',
                    style: TextStyle(fontSize: 14, color: Color(0xFFDC2626))),
              ],
            ),
          ),
        ],
      ],
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
        child: const Icon(Icons.more_horiz, size: 16, color: Color(0xFF6B6862)),
      ),
    );
  }

  /// Settings 弹层（web OrgSettingsModal：branding + danger zone；App 侧
  /// 额外收敛 name/location/description——web 里这三个字段是 header 内联
  /// 编辑，App 无内联编辑形态）。更新成功后本地合并刷新头部。
  Future<void> _openSettingsSheet() async {
    await OrgSettingsSheet.show(
      context,
      org: _org,
      canDelete: _role == 'owner',
      onPatched: (patch) {
        if (mounted) setState(() => _org = {..._org, ...patch});
      },
      onDeleted: () {
        if (mounted) Navigator.of(context).pop();
      },
    );
  }

  /// 删除组织（web handleDelete，OrgProfileHeader.tsx:129-149）：
  /// 二次确认 → DELETE /orgs/{id} → toast「{name} deleted」→ 退出详情页。
  Future<void> _confirmDeleteOrg() async {
    final name = (_org['name'] ?? 'Organization').toString();
    final ok = await showDeleteOrganizationConfirm(context, name);
    if (!ok || !mounted) return;
    try {
      await _service.deleteOrg(_id);
      if (!mounted) return;
      _snack('$name deleted');
      Navigator.of(context).pop();
    } catch (e) {
      _snack('Delete failed: $e');
    }
  }

  // ── Tags（对齐 web TagsSection，OrgProfileHeader.tsx:410-583）────────

  /// pastel chip 流式换行；管理员可点 chip 编辑、点 X 删除、点「+」新增
  /// （上限 5、单个 ≤20 字符、大小写不敏感去重）。
  Widget _tagsSection(List<String> tags) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < tags.length; i++) _tagChip(tags, i),
        // 添加标签按钮（web tsx:545-580：h-8 w-8 rounded-lg bg #F0EEE8）
        if (_isManager && tags.length < _kMaxTags)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _promptTag(tags),
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF0EEE8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add, size: 16, color: Color(0xFF6B6862)),
            ),
          ),
      ],
    );
  }

  /// 单个 tag chip。注意：不能给 Container 设 alignment —— 设了 alignment
  /// 的 Container 会在 Wrap 的宽松约束下扩展成整行宽（此前「标签平铺」
  /// bug 的根因），改用 min 尺寸 Row 让 chip 随内容收缩（web inline-flex）。
  Widget _tagChip(List<String> tags, int i) {
    final canEdit = _isManager;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: canEdit ? () => _promptTag(tags, editIndex: i) : null,
      child: Container(
        height: 32,
        padding: EdgeInsets.only(left: 12, right: canEdit ? 4 : 12),
        decoration: BoxDecoration(
          color: _tagPalette[i % _tagPalette.length],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(tags[i],
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF171717))),
            // 移动端 X 常驻（web isMobile 分支，tsx:502-529）
            if (canEdit)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  final next = [...tags]..removeAt(i);
                  _updateTags(next);
                },
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child:
                      Icon(Icons.close, size: 12, color: Color(0xFF171717)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 新增/编辑 tag（web 是内联 input；App 用对话框承载同一套规则：
  /// ≤20 字符、过滤逗号、空值编辑=删除、大小写不敏感去重，tsx:432-461）。
  Future<void> _promptTag(List<String> tags, {int? editIndex}) async {
    final ctrl =
        TextEditingController(text: editIndex != null ? tags[editIndex] : '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(editIndex != null ? 'Edit tag' : 'Add tag',
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xFF171717))),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: _kMaxTagLength,
          inputFormatters: [FilteringTextInputFormatter.deny(RegExp(','))],
          decoration: const InputDecoration(
            hintText: 'New tag',
            hintStyle: TextStyle(color: Color(0xFFA8A29E)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: Color(0xFF6B6862)))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              child: Text(editIndex != null ? 'Save' : 'Add',
                  style: const TextStyle(
                      color: Color(0xFF171717), fontWeight: FontWeight.w600))),
        ],
      ),
    );
    if (result == null) return;
    final trimmed = result.trim();
    final next = [...tags];
    if (editIndex != null) {
      if (trimmed.isEmpty) {
        // 空值编辑 = 删除（web commitEdit 约定）
        next.removeAt(editIndex);
      } else if (trimmed != tags[editIndex]) {
        final dup = tags.asMap().entries.any((e) =>
            e.key != editIndex &&
            e.value.toLowerCase() == trimmed.toLowerCase());
        if (dup) return;
        next[editIndex] = trimmed;
      } else {
        return;
      }
    } else {
      if (trimmed.isEmpty || next.length >= _kMaxTags) return;
      final dup =
          tags.any((t) => t.toLowerCase() == trimmed.toLowerCase());
      if (dup) return;
      next.add(trimmed);
    }
    await _updateTags(next);
  }

  /// 乐观更新 + PUT /orgs/{id} {tags}（web updateField，
  /// OrgProfileHeader.tsx:120-127：失败保留乐观态，错误由 toast 提示）。
  Future<void> _updateTags(List<String> next) async {
    setState(() => _org = {..._org, 'tags': next});
    try {
      await _service.updateOrg(_id, {'tags': next});
    } catch (e) {
      _snack('Update failed: $e');
    }
  }

  /// tags 容错解析：标准返回为 string[]（web Organization.tags），个别
  /// 序列化会给逗号拼接字符串，统一拆成逐个 tag 渲染（与 web 一致），
  /// 避免整串渲染成一个 chip 或 cast 崩溃。
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

  Widget _logoInitial(String name) {
    final safeName = name.isNotEmpty ? name : '?';
    return Container(
      color: orgAvatarColor(safeName),
      alignment: Alignment.center,
      // web text-[3.5rem]=56 font-semibold（OrgProfileHeader.tsx:850）
      child: Text(orgInitials(safeName),
          style: const TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F1F1F))),
    );
  }

  /// 加入按钮状态机（对齐 web MembershipCta，OrgProfileHeader.tsx:726-826）：
  /// member→Invite（唤起邀请链接面板，web onInvite→InviteOrgModal）；
  /// pending→Requested(禁用+边框)；rejected→Request again + 提示；none→Join。
  Widget _ctaButton() {
    final status = _joinStatus;
    String label;
    IconData? icon;
    VoidCallback? onTap;
    bool disabled = false;
    switch (status) {
      case 'member':
        label = 'Invite';
        icon = Icons.person_add_alt;
        onTap = _showInviteSheet;
        break;
      case 'pending':
        label = 'Requested';
        disabled = true;
        break;
      case 'rejected':
        label = 'Request again';
        icon = Icons.person_add_alt;
        onTap = _requestJoin;
        break;
      default:
        label = 'Join';
        icon = Icons.person_add_alt;
        onTap = _requestJoin;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: disabled || _joining ? null : onTap,
          child: Container(
            height: 44,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color:
                  disabled ? const Color(0xFFF6F5F2) : const Color(0xFF171717),
              borderRadius: BorderRadius.circular(12),
              // web pending 态：border-[#EEEDE9] bg-[#F6F5F2]
              border: disabled
                  ? Border.all(color: const Color(0xFFEEEDE9))
                  : null,
            ),
            child: _joining
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 16, color: Colors.white),
                        const SizedBox(width: 8),
                      ],
                      Text(label,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: disabled
                                  ? const Color(0xFF6B6862)
                                  : Colors.white)),
                    ],
                  ),
          ),
        ),
        if (status == 'rejected')
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text('Your previous request was declined.',
                style: TextStyle(fontSize: 12, color: Color(0xFF9E9B93))),
          ),
      ],
    );
  }

  /// 成员 CTA「Invite」：唤起邀请面板（对齐 web InviteOrgModal：QR 码 +
  /// 邀请链接 + 复制 + Regenerate（仅 admin/owner，web canRefresh=canManage，
  /// layout.tsx:311）+ Download PNG）。
  Future<void> _showInviteSheet() async {
    if (_inviteCode.isEmpty) {
      _snack('Invite link is not ready yet');
      return;
    }
    await InviteOrgSheet.show(
      context,
      orgId: _id,
      slug: _slug,
      inviteCode: _inviteCode,
      canRefresh: _isManager,
      onInviteCodeChange: (code) {
        if (mounted) setState(() => _inviteCode = code);
      },
    );
  }

  // ── Tab 导航（SegmentedControl 风格）──────────────────────────
  Widget _tabBar() {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: DinqTokens.bgSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (var i = 0; i < _tabs.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() => _tab = i);
                  _loadTabData();
                },
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _tab == i ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(_tabs[i],
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              _tab == i ? FontWeight.w600 : FontWeight.w400,
                          color: _tab == i
                              ? const Color(0xFF171717)
                              : const Color(0xFF9E9B93))),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tabContent() {
    switch (_tab) {
      case 0:
        return _cardsTab();
      case 1:
        return _isMember
            ? _membersTab()
            : _lockedGate(
                'Members are only visible to organization members',
                'Join the organization to see all members');
      case 2:
        return _isMember
            ? _chatTab()
            : _lockedGate(
                'Chat is only visible to organization members',
                'Join the organization to join the conversation');
      default:
        return _isMember
            ? _teamTab()
            : _lockedGate(
                'Team recruits are only visible to organization members',
                'Join the organization to see team recruits');
    }
  }

  // ── Cards tab（公开）─────────────────────────────────────────
  Widget _cardsTab() {
    if (!_cardsLoaded) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (_cards.isEmpty) {
      return _emptyState(Icons.grid_view_rounded, 'No cards yet');
    }
    // 简版只读列表（完整卡片渲染复用个人主页卡片系统，后续迭代）
    return Column(
      children: [
        for (final c in _cards.whereType<Map>())
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: DinqTokens.bgCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: DinqTokens.borderLL),
            ),
            child: Row(
              children: [
                const Icon(Icons.crop_square_rounded,
                    size: 20, color: DinqTokens.textTertiary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    (c['title'] ??
                            (c['data'] is Map
                                ? ((c['data'] as Map)['type'] ?? 'Card')
                                : (c['type'] ?? 'Card')))
                        .toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 14, color: ColorUtil.textColor),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ── Members tab（成员）───────────────────────────────────────
  Widget _membersTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isManager) ...[
          Row(
            children: [
              Expanded(
                child: Text('${_members.length} members',
                    style: const TextStyle(
                        fontSize: 13, color: DinqTokens.textTertiary)),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _openReviewSheet,
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFEEEDE9)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.fact_check_outlined,
                          size: 16, color: Color(0xFF171717)),
                      const SizedBox(width: 6),
                      const Text('Review',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF171717))),
                      if (_requests.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          constraints: const BoxConstraints(minWidth: 16),
                          height: 16,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 4),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _requests.length > 99
                                ? '99+'
                                : '${_requests.length}',
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (_inviteCode.isNotEmpty) ...[
          _inviteCard(),
          const SizedBox(height: 12),
        ],
        for (final m in _members.whereType<Map>())
          _memberRow(Map<String, dynamic>.from(m)),
      ],
    );
  }

  Future<void> _openReviewSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: DinqTokens.bgPage,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Join requests (${_requests.length})',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF171717))),
                const SizedBox(height: 14),
                if (_requests.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: Center(
                      child: Text('No pending requests',
                          style: TextStyle(
                              fontSize: 13, color: DinqTokens.textTertiary)),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: BoxConstraints(
                        maxHeight:
                            MediaQuery.sizeOf(context).height * 0.55),
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final r in _requests.whereType<Map>())
                          _requestRow(Map<String, dynamic>.from(r),
                              onReviewed: () => setSheetState(() {})),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Widget _inviteCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: DinqTokens.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DinqTokens.borderLL),
      ),
      child: Row(
        children: [
          const Icon(Icons.link_rounded,
              size: 20, color: DinqTokens.textTertiary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(_inviteLink,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12, color: DinqTokens.textSecondary)),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _copyInvite,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child:
                  Icon(Icons.copy_rounded, size: 18, color: Color(0xFF171717)),
            ),
          ),
          if (_isManager)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _refreshInvite,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _refreshing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh_rounded,
                        size: 18, color: Color(0xFF171717)),
              ),
            ),
        ],
      ),
    );
  }

  // ── Chat tab（成员）──────────────────────────────────────────
  Widget _chatTab() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: DinqTokens.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DinqTokens.borderLL),
      ),
      child: Column(
        children: [
          const Icon(Icons.chat_bubble_outline_rounded,
              size: 32, color: DinqTokens.textTertiary),
          const SizedBox(height: 12),
          const Text('Organization group chat',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF171717))),
          const SizedBox(height: 6),
          const Text('Chat with all members in one place.',
              style: TextStyle(fontSize: 13, color: Color(0xFF9E9B93))),
          const SizedBox(height: 18),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _openChat,
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF171717),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _openingChat
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Open chat',
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

  // ── Team tab（成员）──────────────────────────────────────────
  /// 结构对齐 web OrgTeamView.tsx：
  /// 顶行 = My Team / All Teams 子筛选（仅当我参与了组队才显示，
  /// tsx:210-212）+ 右侧「+」发起组队按钮（web 在 tab 行右侧，
  /// layout.tsx:442-451；App 主 tab 为通栏分段控件，故与子筛选行同行
  /// 居右，对应 QA 标注位置）。
  /// My Team 视图 = 我参与的组队（tsx:224-238）；All Teams 视图 =
  /// My Team 分区 + Other teams 分区（tsx:240-301）。
  Widget _teamTab() {
    if (!_recruitsLoaded) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    final myTeam = _myTeamRecruit();
    final myTeamId = (myTeam?['message_id'] ?? '').toString();
    final otherTeams = _recruits
        .whereType<Map>()
        .where((r) =>
            myTeam == null || (r['message_id'] ?? '').toString() != myTeamId)
        .toList();
    // 未参与组队时强制 All Teams（web activeView 回退 "all"，tsx:147）
    final view = myTeam == null ? 1 : _teamView;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (myTeam != null) _teamViewSwitch() else const Spacer(),
            if (myTeam != null) const Spacer(),
            _createRecruitButton(),
          ],
        ),
        const SizedBox(height: 12),
        if (view == 0 && myTeam != null) ...[
          // My Team：未成团时带提示文案（web tsx:227-238 myTeamHint）
          _teamSectionHeader('My Team',
              hint: (myTeam['spawned_conv_id'] ?? '').toString().isEmpty
                  ? 'Team chat will appear once this team is assembled'
                  : null),
          _recruitRow(myTeam),
        ] else if (myTeam != null) ...[
          // All Teams：My Team 分区 + Other teams 分区（web tsx:240-301）
          _teamSectionHeader('My Team'),
          _recruitRow(myTeam),
          const SizedBox(height: 6),
          _teamSectionHeader('Other teams',
              hint: 'View only, leave your team first to join'),
          if (otherTeams.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD8D5CE)),
              ),
              child: const Text('No other teams yet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Color(0xFF9E9B93))),
            )
          else
            for (final r in otherTeams) _recruitRow(r),
        ] else if (_recruits.isEmpty)
          _emptyState(Icons.group_add_outlined, 'No team recruits yet')
        else
          for (final r in _recruits.whereType<Map>()) _recruitRow(r),
      ],
    );
  }

  /// 我参与的组队（对齐 web OrgTeamView joinedTeam，tsx:102-109：
  /// creator_id 为我或 team_members 含我，created_at 最新优先）。
  /// 接口无参与方过滤参数（types/api/teamRecruit.ts 仅 state/limit/offset），
  /// 与 web 一致走本地过滤。
  Map<String, dynamic>? _myTeamRecruit() {
    final uid = context.read<UserStore>().user?.user.id ?? '';
    if (uid.isEmpty) return null;
    Map<String, dynamic>? newest;
    var newestAt = '';
    for (final r in _recruits.whereType<Map>()) {
      final creatorId = (r['creator_id'] ?? '').toString();
      final memberIds =
          (r['team_members'] as List?)?.map((e) => e.toString()) ??
              const Iterable<String>.empty();
      if (creatorId != uid && !memberIds.contains(uid)) continue;
      final createdAt = (r['created_at'] ?? '').toString();
      if (newest == null || createdAt.compareTo(newestAt) > 0) {
        newest = Map<String, dynamic>.from(r);
        newestAt = createdAt;
      }
    }
    return newest;
  }

  /// My Team / All Teams 子筛选（对齐 web TeamViewSwitch，
  /// OrgTeamView.tsx:326-364：SegmentedControl，选项带图标）。
  Widget _teamViewSwitch() {
    return Container(
      height: 36,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: DinqTokens.bgSurface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _teamViewOption(0, Icons.chat_bubble_outline_rounded, 'My Team'),
          _teamViewOption(1, Icons.people_outline, 'All Teams'),
        ],
      ),
    );
  }

  Widget _teamViewOption(int value, IconData icon, String label) {
    final active = _teamView == value;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _teamView = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: active
                    ? const Color(0xFF171717)
                    : const Color(0xFF9E9B93)),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    color: active
                        ? const Color(0xFF171717)
                        : const Color(0xFF9E9B93))),
          ],
        ),
      ),
    );
  }

  /// 「+」发起组队按钮（对齐 web layout.tsx:442-451：h-9 rounded-lg
  /// border #EEEDE9 白底 + Plus 图标，移动端仅图标；可见性对齐 web
  /// showCreateRecruit = isMember && active==="team"，layout.tsx:405 ——
  /// 组织成员即可发起。main_conversation_id 缺失不隐藏按钮，点击时
  /// 重拉 /org/profile 兜底，仍拿不到才 toast）。
  Widget _createRecruitButton() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _openCreateRecruit,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFEEEDE9)),
        ),
        child: _creatingRecruit
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.add, size: 18, color: Color(0xFF171717)),
      ),
    );
  }

  /// 分区标题（对齐 web TeamListSection，OrgTeamView.tsx:366-384：
  /// 标题 12 semibold #6b6862，hint 前置「—」11 #9e9b93）。
  Widget _teamSectionHeader(String title, {String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B6862))),
          if (hint != null)
            Text('— $hint',
                style:
                    const TextStyle(fontSize: 11, color: Color(0xFF9E9B93))),
        ],
      ),
    );
  }

  /// 单条组队招募（对齐 web TeamRecruitSummaryCard 的 list 形态字段：
  /// team_title / team_description / team_state / team_members /
  /// team_max_members / spawned_conv_id）。已加入且已成团的可点击
  /// 直接进入 team 子群会话（web onOpenTeam → PinnedTeamChat 的 App 对应物）。
  Widget _recruitRow(Map r) {
    final title = (r['team_title'] ?? r['title'] ?? 'Team recruit').toString();
    final desc = (r['team_description'] ?? r['description'] ?? '').toString();
    final state = (r['team_state'] ?? r['state'] ?? '').toString();
    final maxMembers =
        (r['team_max_members'] is num) ? (r['team_max_members'] as num).toInt() : 0;
    final memberIds = (r['team_members'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        const <String>[];
    final spawnedConvId = (r['spawned_conv_id'] ?? '').toString();
    final currentUserId =
        context.read<UserStore>().user?.user.id ?? '';
    final hasJoined = memberIds.contains(currentUserId);
    final canOpenTeamChat = spawnedConvId.isNotEmpty &&
        hasJoined &&
        (state == 'full' || state == 'closed');

    // 状态徽章配色对齐 web：Full 绿 / Closed 灰 / open 蓝 x/y
    String badgeText;
    Color badgeBg;
    Color badgeFg;
    if (state == 'full') {
      badgeText = 'Full';
      badgeBg = const Color(0xFFF4F9F0);
      badgeFg = const Color(0xFF5C8840);
    } else if (state == 'closed') {
      badgeText = 'Closed';
      badgeBg = const Color(0xFFF7F6F2);
      badgeFg = const Color(0xFF9E9B93);
    } else {
      badgeText = '${memberIds.length} / $maxMembers';
      badgeBg = const Color(0xFFF0F4FB);
      badgeFg = const Color(0xFF5E81AC);
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: canOpenTeamChat
          ? () => context.push('/admin/inbox/$spawnedConvId')
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: DinqTokens.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: DinqTokens.borderLL),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.outlined_flag,
                    size: 16, color: Color(0xFF9E9B93)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: ColorUtil.textColor)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(badgeText,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: badgeFg)),
                ),
              ],
            ),
            if (desc.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(desc,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF9E9B93))),
            ],
            if (canOpenTeamChat) ...[
              const SizedBox(height: 8),
              const Text('Open team chat ›',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5E81AC))),
            ],
          ],
        ),
      ),
    );
  }

  // ── LockedGate（对齐 web OrgLockedGate）───────────────────────
  Widget _lockedGate(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F6F2),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFEEEDE9)),
            ),
            child: const Icon(Icons.lock_outline_rounded,
                size: 20, color: Color(0xFF6B6862)),
          ),
          const SizedBox(height: 14),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF171717))),
          const SizedBox(height: 6),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF9E9B93))),
          const SizedBox(height: 18),
          if (_joinStatus == 'pending')
            _gateButton('Requested', disabled: true)
          else if (_joinStatus == 'rejected') ...[
            _gateButton('Request again', onTap: _requestJoin),
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Your previous request was declined.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF9E9B93))),
            ),
          ] else
            _gateButton('Join Organization', onTap: _requestJoin),
        ],
      ),
    );
  }

  Widget _gateButton(String label,
      {VoidCallback? onTap, bool disabled = false}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: disabled || _joining ? null : onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: disabled ? const Color(0xFFF6F5F2) : const Color(0xFF171717),
          borderRadius: BorderRadius.circular(8),
          border:
              disabled ? Border.all(color: const Color(0xFFEEEDE9)) : null,
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: disabled ? const Color(0xFF6B6862) : Colors.white)),
      ),
    );
  }

  Widget _emptyState(IconData icon, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFEFEFED),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 22, color: const Color(0xFF9E9B93)),
          ),
          const SizedBox(height: 12),
          Text(text,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B6862))),
        ],
      ),
    );
  }

  // ── 成员/审批行（沿用原实现）─────────────────────────────────
  Widget _requestRow(Map<String, dynamic> r, {VoidCallback? onReviewed}) {
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
            onTap: () async {
              await _review(r, 'approved');
              onReviewed?.call();
            },
            child: const Icon(Icons.check_circle_outline,
                size: 24, color: Color(0xFF5C8840)),
          ),
          const SizedBox(width: 14),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () async {
              await _review(r, 'rejected');
              onReviewed?.call();
            },
            child: const Icon(Icons.cancel_outlined,
                size: 24, color: Color(0xFFE24B3C)),
          ),
        ],
      ),
    );
  }

  Widget _memberRow(Map<String, dynamic> m) {
    final user = (m['user'] as Map?)?.cast<String, dynamic>() ?? const {};
    final name = (user['name'] ?? m['user_id'] ?? 'Member').toString();
    final position =
        (user['full_position'] ?? user['full_degree'] ?? '').toString();
    final location = (user['location'] ?? '').toString();
    final sub = [
      if (position.isNotEmpty) position,
      if (location.isNotEmpty) location,
    ].join(' · ');
    final avatar = (user['avatar_url'] ?? '').toString();
    final domain = (user['domain'] ?? '').toString();
    final role = (m['role'] ?? '').toString();
    final uid = (m['user_id'] ?? '').toString();
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
                icon: const Icon(Icons.more_horiz_rounded,
                    size: 20, color: DinqTokens.textTertiary),
                onSelected: (v) => _manageMember(uid, name, v),
                itemBuilder: (_) => [
                  if (role != 'admin')
                    const PopupMenuItem(
                        value: 'admin', child: Text('Make admin')),
                  if (role == 'admin')
                    const PopupMenuItem(
                        value: 'member', child: Text('Make member')),
                  const PopupMenuItem(
                      value: 'remove',
                      child: Text('Remove member',
                          style: TextStyle(color: Color(0xFFE24B3C)))),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _roleBadge(String role) {
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
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(role[0].toUpperCase() + role.substring(1),
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
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
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel')),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Remove',
                      style: TextStyle(color: Color(0xFFE24B3C)))),
            ],
          ),
        );
        if (ok != true) return;
        await _service.removeOrgMember(_id, uid);
      } else {
        await _service.updateOrgMemberRole(_id, uid, action);
      }
      try {
        _members = await _service.getOrgMembers(_id);
      } catch (_) {}
      if (mounted) setState(() {});
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
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: ColorUtil.textColor)),
        if (sub.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(sub,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontSize: 12, color: DinqTokens.textTertiary)),
        ],
      ],
    );
  }

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
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: ColorUtil.textColor)),
    );
  }
}
