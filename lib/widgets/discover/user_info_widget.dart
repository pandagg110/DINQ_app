import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../common/asset_icon.dart';
import '../../services/discover_service.dart';
import '../../stores/search_store.dart';
import 'network_loading_animation.dart';

class UserInfoWidget extends StatefulWidget {
  const UserInfoWidget({
    super.key,
    required this.tabData,
    this.onClose,
    this.resetKey,
  });

  final SearchTabData tabData;
  final VoidCallback? onClose;
  final int? resetKey;

  @override
  State<UserInfoWidget> createState() => _UserInfoWidgetState();
}

class _UserInfoWidgetState extends State<UserInfoWidget> {
  static final DiscoverService _discoverService = DiscoverService();

  /// 与 TSX showProfile 一致：Contact 数据加载完成后是否展开内联区块
  bool _showProfile = false;
  int? _lastResetKey;

  @override
  void didUpdateWidget(UserInfoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.resetKey != _lastResetKey) {
      _lastResetKey = widget.resetKey;
      _showProfile = false;
    }
  }

  /// 仅刷新 Network 数据（不关闭弹层，弹层通过 watch Store 自动更新）
  Future<void> _refreshNetworkOnly(BuildContext context, int candidateId) async {
    final searchStore = context.read<SearchStore>();
    searchStore.setTabNetworkLoading(candidateId, true);
    try {
      final tab = searchStore.openTabs.where((t) => t.id == candidateId).firstOrNull;
      if (tab == null) return;
      final result = await _discoverService.getNetwork({'person': tab.candidate});
      final network = (result['network'] as List<dynamic>? ?? []).take(6).toList();
      searchStore.updateTabNetwork(candidateId, network);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('刷新 Network 失败：$e')),
        );
      }
    } finally {
      searchStore.setTabNetworkLoading(candidateId, false);
    }
  }

  Future<void> _handleNetworkTap(BuildContext context) async {
    final searchStore = context.read<SearchStore>();
    final candidateId = widget.tabData.id;
    final existing = widget.tabData.network;

    // 已有数据：直接弹出网络关系列表
    if (existing != null && existing.isNotEmpty) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => _NetworkSheet(
          candidateId: candidateId,
          onRefresh: () => _refreshNetworkOnly(context, candidateId),
        ),
      );
      return;
    }

    // 加载 network 数据
    searchStore.setTabNetworkLoading(candidateId, true);
    try {
      final result = await _discoverService.getNetwork({'person': widget.tabData.candidate});
      final network = (result['network'] as List<dynamic>? ?? []).take(6).toList();
      searchStore.updateTabNetwork(candidateId, network);

      // 仅在当前标签仍然是该用户时弹出
      if (searchStore.activeTabId == candidateId && network.isNotEmpty) {
        searchStore.setTabNetworkLoading(candidateId, false); // 先关 loading 再开弹层，避免弹层打开时仍显示 loading
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (ctx) => _NetworkSheet(
            candidateId: candidateId,
            onRefresh: () => _refreshNetworkOnly(context, candidateId),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载 Network 失败：$e')),
      );
    } finally {
      searchStore.setTabNetworkLoading(candidateId, false);
    }
  }

  Future<void> _handleProfileTap(BuildContext context) async {
    final searchStore = context.read<SearchStore>();
    final candidateId = widget.tabData.id;
    final existing = widget.tabData.profile;

    // 已有 profile：与 TSX 一致，切换内联展开/收起
    if (existing != null) {
      setState(() => _showProfile = !_showProfile);
      return;
    }

    searchStore.setTabEnrichLoading(candidateId, true);
    try {
      final result = await _discoverService.getProfile({'person': widget.tabData.candidate});
      searchStore.updateTabProfile(candidateId, result);
      if (mounted && searchStore.activeTabId == candidateId) {
        setState(() => _showProfile = true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载 Profile 失败：$e')),
      );
    } finally {
      searchStore.setTabEnrichLoading(candidateId, false);
    }
  }

  void _handleAnalyzeTap(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Analyze 功能暂未实现')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final candidate = widget.tabData.candidate;
    final name = candidate['name']?.toString() ?? 'Unknown';
    final imageUrl = candidate['image_url']?.toString();
    final company = candidate['company']?.toString();
    final position = candidate['position']?.toString();
    final university = candidate['university']?.toString();
    final oneLiner = candidate['one_liner']?.toString() ?? '';
    final researchAreas = (candidate['research_areas'] as List<dynamic>?) ?? [];
    final matchReason = candidate['match_reason']?.toString() ?? '';
    final keyPublications = (candidate['key_publications'] as List<dynamic>?) ?? [];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: const Color(0xFFE5E5E5),
                  backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
                  child: imageUrl == null
                      ? const Icon(Icons.person, size: 32, color: Color(0xFF9CA3AF))
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF171717),
                        ),
                      ),
                      if (company != null || position != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.business, size: 14, color: Color(0xFF6B7280)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                [company, position].where((e) => e != null).join(' · '),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF6B7280),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (university != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.school, size: 14, color: Color(0xFF6B7280)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                university,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF6B7280),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Why this candidate
          if (matchReason.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF88C0D0).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Why this candidate?',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF5E81AC),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      matchReason,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                        height: 1.5,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),

          // Research Areas
          if (researchAreas.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: researchAreas.take(3).map((area) {
                  final index = researchAreas.indexOf(area);
                  final colors = [
                    const Color(0xFFF5D97A).withOpacity(0.5),
                    const Color(0xFFF5C4C4).withOpacity(0.5),
                    const Color(0xFFC8E6A0).withOpacity(0.5),
                  ];
                  final textColors = [
                    const Color(0xFF5E4A1E),
                    const Color(0xFF7A4A4A),
                    const Color(0xFF3D5E3D),
                  ];
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors[index % colors.length],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      area.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: textColors[index % textColors.length],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

          // Bio
          if (oneLiner.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(
                oneLiner,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
            ),

          // Divider
          const Divider(height: 32),

          // Action buttons (Network / Contact / Analyze)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: const AssetIcon(
                      asset: 'icons/search/network.svg',
                      size: 16,
                      color: Colors.black,
                    ),
                    label: 'Network',
                    loading: widget.tabData.networkLoading,
                    active: false,
                    done: (widget.tabData.network != null && widget.tabData.network!.isNotEmpty),
                    onTap: () => _handleNetworkTap(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionButton(
                    icon: const AssetIcon(
                      asset: 'icons/search/enrich.svg',
                      size: 16,
                      color: Colors.black,
                    ),
                    label: 'Contact',
                    loading: widget.tabData.enrichLoading,
                    active: _showProfile,
                    done: widget.tabData.profile != null,
                    onTap: () => _handleProfileTap(context),
                    showArrow: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionButton(
                    icon: const AssetIcon(
                      asset: 'icons/search/analyze.svg',
                      size: 16,
                      color: Colors.black,
                    ),
                    label: 'Analyze',
                    loading: false,
                    active: false,
                    done: false,
                    onTap: () => _handleAnalyzeTap(context),
                  ),
                ),
              ],
            ),
          ),

          // Profile data（与 TSX 858-871 一致：内联展开/收起，非弹框）
          if (widget.tabData.profile != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
              child: AnimatedOpacity(
                opacity: _showProfile ? 1 : 0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  alignment: Alignment.topCenter,
                  child: _showProfile
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: SizedBox(
                            width: double.infinity,
                            child: _ProfileContent(profile: widget.tabData.profile!),
                          ),
                        )
                      : const SizedBox(width: double.infinity, height: 0),
                ),
              ),
            ),

          // Publications
          if (keyPublications.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Publications',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF171717),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...keyPublications.take(3).map((pub) {
                    final title = pub['title']?.toString() ?? '';
                    final venue = pub['venue']?.toString();
                    final year = pub['year']?.toString();
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFF5F5F5)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF171717),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (venue != null || year != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                [venue, year].where((e) => e != null).join(' · '),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.loading,
    required this.active,
    required this.done,
    required this.onTap,
    this.showArrow = false,
  });

  final Widget icon;
  final String label;
  final bool loading;
  final bool active;
  final bool done;
  final VoidCallback onTap;
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;

    if (active) {
      bgColor = const Color(0xFF111827);
      textColor = Colors.white;
    } else if (done) {
      bgColor = const Color(0xFFF3F4F6);
      textColor = const Color(0xFF374151);
    } else {
      bgColor = const Color(0xFFF3F4F6);
      textColor = const Color(0xFF4B5563);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              if (loading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      textColor.withOpacity(0.8),
                    ),
                  ),
                )
              else if (done && !active)
                const Icon(
                  Icons.check,
                  size: 16,
                  color: Color(0xFF16A34A),
                )
              else
                icon,
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ),
              if (showArrow && done) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 16,
                  color: textColor,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Network 加载时轮播提示（与 TSX loading-tip / tips 一致），放在 user_info_widget 中供 Network 相关 UI 使用
const List<String> kNetworkLoadingTips = [
  'Hover over avatars to view talent profiles',
  'Click on an avatar to explore their network',
  'Use the refresh button to return to the initial network',
];

class _NetworkLoadingTips extends StatefulWidget {
  const _NetworkLoadingTips();

  @override
  State<_NetworkLoadingTips> createState() => _NetworkLoadingTipsState();
}

class _NetworkLoadingTipsState extends State<_NetworkLoadingTips>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tips = kNetworkLoadingTips;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        height: 24,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final index = (_controller.value * tips.length).floor() % tips.length;
            return Center(
              child: Text(
                tips[index],
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9CA3AF),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 与 TSX NetworkModal 一致：径向图布局（中心节点 + 周围 6 节点 + 连线），上一版（无移动端 70dvh/阴影/Expanded）
class _NetworkSheet extends StatelessWidget {
  const _NetworkSheet({
    required this.candidateId,
    this.onRefresh,
  });

  final int candidateId;
  /// 底部刷新按钮回调（与 TSX reset-button / resetToDefault 一致）
  final VoidCallback? onRefresh;

  static String _defaultAvatarUrl(String? name) {
    if (name != null && name.trim().isNotEmpty) {
      return 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name.trim())}&background=e5e7eb&color=6b7280&size=128';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final searchStore = context.watch<SearchStore>();
    final tab = searchStore.openTabs.where((t) => t.id == candidateId).firstOrNull;
    final centerUser = tab?.candidate ?? <String, dynamic>{};
    final items = tab?.network ?? const [];
    final hasConnections = items.isNotEmpty;
    final isLoading = tab?.networkLoading ?? false;
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFBFBFA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Text(
                    'Network',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF171717),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Opacity(
                      opacity: 0.32,
                      child: Text(
                        '×',
                        style: const TextStyle(
                          fontSize: 28,
                          height: 1,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!hasConnections && !isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Text(
                  'No connections found.',
                  style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
                ),
              )
            else
              Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: isLoading ? 0 : 1,
                    child: SizedBox(
                      height: 440,
                      child: _NetworkRadialGraph(
                        centerUser: centerUser,
                        items: items,
                      ),
                    ),
                  ),
                  if (isLoading)
                    Positioned.fill(
                      child: Container(
                        height: 440,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Center(
                          child: NetworkLoadingAnimation(size: 300),
                        ),
                      ),
                    ),
                ],
              ),
            // 与 TSX network-modal-actions、bottom-tip 一致：刷新按钮 + 底部轮播提示
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onRefresh != null) ...[
                    _NetworkSheetRefreshButton(
                      onPressed: onRefresh!,
                      loading: isLoading,
                    ),
                    const SizedBox(height: 16),
                  ],
                  const Center(child: _NetworkLoadingTips()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 与 TSX .reset-button、.refresh-icon 一致
class _NetworkSheetRefreshButton extends StatelessWidget {
  const _NetworkSheetRefreshButton({
    required this.onPressed,
    this.loading = false,
  });

  final VoidCallback onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: loading ? null : onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFE5E7EB),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(
                  child: AssetIcon(
                    asset: 'icons/search/refresh.svg',
                    size: 20,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
        ),
      ),
    );
  }
}

/// 径向图：中心 + 6 个周围节点 + 连线
class _NetworkRadialGraph extends StatelessWidget {
  const _NetworkRadialGraph({
    required this.centerUser,
    required this.items,
  });

  final Map<String, dynamic> centerUser;
  final List<dynamic> items;

  static const double _centerRadius = 42;  // 中心圆 84px
  static const double _nodeRadius = 28;   // 周围小圆 56px
  static const double _orbitRadius = 130;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final centerX = w / 2;
    const centerY = 220.0;

    final nodePositions = <Offset>[];
    final n = math.min(6, items.length);
    for (var i = 0; i < n; i++) {
      final angle = 2 * math.pi * i / n - math.pi / 2 + math.pi / 4;
      nodePositions.add(Offset(
        centerX + _orbitRadius * math.cos(angle),
        centerY + _orbitRadius * math.sin(angle),
      ));
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: centerX - 200+100,
          top: centerY - 200+100,
          width: 200,
          height: 200,
          child: Opacity(
            opacity: 0.7,
            child: SvgPicture.asset(
              'assets/images/network_modal_bg.svg',
              fit: BoxFit.contain,
            ),
          ),
        ),
        CustomPaint(
          size: Size(w, 440),
          painter: _NetworkLinesPainter(
            center: Offset(centerX, centerY),
            nodePositions: nodePositions,
          ),
        ),
        Positioned(
          left: centerX - _centerRadius,
          top: centerY - _centerRadius,
          child: _CenterNode(
            name: centerUser['name']?.toString() ?? 'Unknown',
            avatarUrl: centerUser['image_url']?.toString() ?? centerUser['avatar_url']?.toString(),
          ),
        ),
        for (var i = 0; i < n; i++)
          Positioned(
            left: nodePositions[i].dx - _nodeRadius,
            top: nodePositions[i].dy - _nodeRadius,
            child: _NetworkNode(
              item: items[i] is Map<String, dynamic> ? items[i] as Map<String, dynamic> : <String, dynamic>{},
            ),
          ),
      ],
    );
  }
}

class _NetworkLinesPainter extends CustomPainter {
  _NetworkLinesPainter({required this.center, required this.nodePositions});
  final Offset center;
  final List<Offset> nodePositions;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    for (final pos in nodePositions) {
      canvas.drawLine(center, pos, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

const _avatarGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color(0x006B7280),
    Color(0x006B7280),
    Color(0x406B7280),
    Color(0x996B7280),
    Color(0xE66B7280),
  ],
  stops: [0.0, 0.5, 0.7, 0.85, 1.0],
);

/// 与 TSX truncateNameToTwoLines 一致：按空格分词，首词一行、其余第二行，每行最多 maxCharsPerLine 字
List<String> _truncateNameToTwoLines(String name, [int maxCharsPerLine = 12]) {
  final words = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
  if (words.isEmpty) return [''];
  if (words.length == 1) {
    final w = words[0];
    return [w.length > maxCharsPerLine ? '${w.substring(0, maxCharsPerLine)}...' : w];
  }
  final line1 = words[0].length > maxCharsPerLine
      ? '${words[0].substring(0, maxCharsPerLine)}...'
      : words[0];
  final remaining = words.sublist(1).join(' ');
  final line2 = remaining.length > maxCharsPerLine
      ? '${remaining.substring(0, maxCharsPerLine)}...'
      : remaining;
  return [line1, line2];
}

class _CenterNode extends StatelessWidget {
  const _CenterNode({required this.name, this.avatarUrl});
  final String name;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    const size = _NetworkRadialGraph._centerRadius * 2;
    final lines = _truncateNameToTwoLines(name, 14);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          CircleAvatar(
            radius: _NetworkRadialGraph._centerRadius,
            backgroundColor: const Color(0xFF6B7280),
            backgroundImage: (avatarUrl != null && avatarUrl!.isNotEmpty) ? NetworkImage(avatarUrl!) : null,
            child: (avatarUrl == null || avatarUrl!.isEmpty) ? Icon(Icons.school, size: 28, color: Colors.grey[400]) : null,
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_NetworkRadialGraph._centerRadius),
                gradient: _avatarGradient,
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF9CA3AF), width: 6),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 16,
            child: Text(
              lines.join('\n'),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.2,
                shadows: [Shadow(color: Color(0xCC000000), blurRadius: 2, offset: Offset(1, 1))],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NetworkNode extends StatelessWidget {
  const _NetworkNode({required this.item});
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final name = item['name']?.toString() ?? 'Unknown';
    final avatarUrl = item['avatar_url']?.toString();
    final avatarSrc = (avatarUrl != null && avatarUrl.isNotEmpty) ? avatarUrl : _NetworkSheet._defaultAvatarUrl(name);
    const size = _NetworkRadialGraph._nodeRadius * 2;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: _NetworkRadialGraph._nodeRadius,
            backgroundColor: const Color(0xFFE5E7EB),
            backgroundImage: avatarSrc.isNotEmpty ? NetworkImage(avatarSrc) : null,
            child: avatarSrc.isEmpty
                ? Text(
                    _initials(name),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
                  )
                : null,
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: _avatarGradient),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 12,
            child: Text(
              _truncateNameToTwoLines(name, 10).join('\n'),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.2,
                shadows: [Shadow(color: Color(0xCC000000), blurRadius: 2, offset: Offset(1, 1))],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].isEmpty ? '?' : parts[0].substring(0, 1).toUpperCase();
    return '${parts[0].substring(0, 1)}${parts[1].substring(0, 1)}'.toUpperCase();
  }
}

/// 与 TSX Profile.tsx 一致：Contact 内联区块（圆角卡片、Possible Emails、Latest News）
class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.profile});

  final Map<String, dynamic> profile;

  /// 与 TSX renderBold 一致：解析 **加粗** 语法，返回 TextSpan 列表
  static List<InlineSpan> _renderBold(
    String text, {
    TextStyle? normalStyle,
    TextStyle? boldStyle,
  }) {
    const defaultNormal = TextStyle(
      fontSize: 14,
      color: Color(0xFF6B7280),
      height: 1.5,
    );
    const defaultBold = TextStyle(
      fontSize: 14,
      color: Color(0xFF6B7280),
      height: 1.5,
      fontWeight: FontWeight.w600,
    );
    final n = normalStyle ?? defaultNormal;
    final b = boldStyle ?? defaultBold;
    const pattern = '**';
    final spans = <InlineSpan>[];
    var start = 0;
    while (true) {
      final i = text.indexOf(pattern, start);
      if (i < 0) {
        if (start < text.length) {
          spans.add(TextSpan(text: text.substring(start), style: n));
        }
        break;
      }
      if (start < i) {
        spans.add(TextSpan(text: text.substring(start, i), style: n));
      }
      final end = text.indexOf(pattern, i + pattern.length);
      if (end < 0) {
        spans.add(TextSpan(text: text.substring(i), style: n));
        break;
      }
      spans.add(TextSpan(
        text: text.substring(i + pattern.length, end),
        style: b,
      ));
      start = end + pattern.length;
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final emails = profile['emails'] as List<dynamic>?;
    final news = profile['news'] as List<dynamic>?;
    debugPrint('news: $news');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Contact（与 TSX 一致：border-b border-gray-200 pb-4）
          const Text(
            'Contact',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 16, bottom: 16),
            child: Divider(height: 1, color: Color(0xFFE5E7EB)),
          ),
          // Possible Emails（与 TSX 一致：mt-4, icon + title gap-2 mb-3, flex-col gap-2）
          if (emails != null && emails.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.mail_outline, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                const Text(
                  'Possible Emails',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...emails.map((email) => _EmailRow(email: email.toString())),
            const SizedBox(height: 16),
          ],
          // Latest News（与 TSX 一致：mt-4, icon + title, 段落 renderBold + [i] 链接, 横向卡片 renderBold）
          if (news != null && news.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.article_outlined, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                const Text(
                  'Latest News',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 段落：renderBold(description 截断 100) + [i] 链接（与 TSX p.mb-2 last:mb-0 一致）
            ...List.generate(news.length, (i) {
              final fullDesc = _newsDescriptionRaw(news[i]);
              final desc = fullDesc.length > 100 ? '${fullDesc.substring(0, 100)}...' : fullDesc;
              final url = _newsUrl(news[i]);
              return Padding(
                padding: EdgeInsets.only(bottom: i < news.length - 1 ? 8 : 0),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                      height: 1.5,
                    ),
                    children: [
                      ..._renderBold(desc),
                      if (url.isNotEmpty)
                        WidgetSpan(
                          alignment: PlaceholderAlignment.baseline,
                          baseline: TextBaseline.alphabetic,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: GestureDetector(
                              onTap: () => launchUrl(
                                Uri.parse(url),
                                mode: LaunchMode.externalApplication,
                              ),
                              child: Text(
                                '[${i + 1}]',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF1487FA),
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
            // 横向滚动卡片（与 TSX 一致：width 280 height 80, renderBold(n.description), Source [i]）
            SizedBox(
              height: 88,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: news.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final n = news[index];
                  return _NewsCard(
                    description: _newsDescriptionRaw(n),
                    url: _newsUrl(n),
                    index: index,
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  static String _newsDescriptionRaw(dynamic n) {
    if (n is! Map) return n.toString();
    return n['description']?.toString() ?? '';
  }

  static String _newsUrl(dynamic n) {
    if (n is! Map) return '';
    return n['url']?.toString() ?? '';
  }
}

class _EmailRow extends StatefulWidget {
  const _EmailRow({required this.email});

  final String email;

  @override
  State<_EmailRow> createState() => _EmailRowState();
}

class _EmailRowState extends State<_EmailRow> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFFF3F4F6),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                bottomLeft: Radius.circular(8),
              ),
            ),
            child: Icon(Icons.mail_outline, size: 14, color: Colors.grey[600]),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Text(
                widget.email,
                style: const TextStyle(fontSize: 14, color: Color(0xFF4B5563)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: widget.email));
              if (mounted) {
                setState(() => _copied = true);
                Future.delayed(const Duration(seconds: 3), () {
                  if (mounted) setState(() => _copied = false);
                });
              }
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _copied ? Icons.check : Icons.content_copy,
                  size: 16,
                  color: const Color(0xFF6B7280),
                ),
                const SizedBox(width: 6),
                Text(
                  _copied ? 'Copied!' : 'Copy',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.description, required this.url, required this.index});

  final String description;
  final String url;
  final int index;

  static final _cardNormalStyle = const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: Color(0xFF374151),
  );
  static final _cardBoldStyle = const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: Color(0xFF374151),
  );

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: url.isEmpty
            ? null
            : () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  children: _ProfileContent._renderBold(
                    description,
                    normalStyle: _cardNormalStyle,
                    boldStyle: _cardBoldStyle,
                  ),
                ),
              ),
              Text(
                'Source [${index + 1}]',
                style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
