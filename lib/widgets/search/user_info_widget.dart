import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../common/asset_icon.dart';
import '../../constants/app_constants.dart';
import '../../services/search_service.dart';
import '../../stores/search_store.dart';
import '../../utils/top_toast_util.dart';
import 'network_loading_animation.dart';

/// 仅允许 http/https URL，避免 file:/// 或空串导致 "No host specified in URI"
bool _isValidHttpUrl(String? s) {
  if (s == null || s.trim().isEmpty) return false;
  final lower = s.trim().toLowerCase();
  if (lower.startsWith('file:')) return false;
  return lower.startsWith('http://') || lower.startsWith('https://');
}

/// 解析 **加粗** 语法，返回 TextSpan 列表（与 TSX renderBold 一致，供 match_reason、Contact 等复用）
/// 与 TSX renderMarkdownBold 一致：解析 **加粗**，可选 withBackground（#88C0D020 + padding + borderRadius）
List<InlineSpan> _renderBold(
  String text, {
  TextStyle? normalStyle,
  TextStyle? boldStyle,
  bool withBackground = true,
}) {
  const defaultNormal = TextStyle(
    fontSize: 14,
    color: Color(0xFF6B7280),
    height: 1.5,
  );
  // TSX: text-gray-800 font-medium
  const defaultBold = TextStyle(
    fontSize: 14,
    color: Color(0xFF1F2937),
    height: 1.5,
    fontWeight: FontWeight.w500,
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
    final boldText = text.substring(i + pattern.length, end);
    if (withBackground) {
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: const Color(0x2088C0D0),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(boldText, style: b),
        ),
      ));
    } else {
      spans.add(TextSpan(text: boldText, style: b));
    }
    start = end + pattern.length;
  }
  return spans;
}

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
  static final SearchService _searchService = SearchService();

  /// 与 TSX showProfile 一致：Contact 数据加载完成后是否展开内联区块
  bool _showProfile = false;
  int? _lastResetKey;

  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

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
      final result = await _searchService.getNetwork({'person': tab.candidate});
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
        enableDrag: false,
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
      final result = await _searchService.getNetwork({'person': widget.tabData.candidate});
      final network = (result['network'] as List<dynamic>? ?? []).take(6).toList();
      searchStore.updateTabNetwork(candidateId, network);

      // 仅在当前标签仍然是该用户时弹出
      if (searchStore.activeTabId == candidateId && network.isNotEmpty) {
        searchStore.setTabNetworkLoading(candidateId, false); // 先关 loading 再开弹层，避免弹层打开时仍显示 loading
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          enableDrag: false,
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
      final result = await _searchService.getProfile({'person': widget.tabData.candidate});
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

    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _scrollController,
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
                  backgroundImage: _isValidHttpUrl(imageUrl) ? NetworkImage(imageUrl!) : null,
                  child: !_isValidHttpUrl(imageUrl)
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
                    RichText(
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                          height: 1.5,
                        ),
                        children: _renderBold(matchReason, withBackground: false),
                      ),
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
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    height: 1.5,
                  ),
                  children: _renderBold(oneLiner),
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
                    iconAsset: 'icons/search/network.svg',
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
                    iconAsset: 'icons/search/enrich.svg',
                    label: 'Contact',
                    loading: widget.tabData.enrichLoading,
                    active: _showProfile,
                    done: widget.tabData.profile != null,
                    onTap: () => _handleProfileTap(context),
                    showArrow: true,
                  ),
                ),
                const SizedBox(width: 8),
                _AnalyzeButtonCardDropdown(candidate: candidate),
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
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    this.icon,
    this.iconAsset,
    required this.label,
    required this.loading,
    required this.active,
    required this.done,
    required this.onTap,
    this.showArrow = false,
  }) : assert(icon != null || iconAsset != null, 'Either icon or iconAsset must be provided');

  final Widget? icon;
  final String? iconAsset;
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
              else if (iconAsset != null)
                AssetIcon(
                  asset: iconAsset!,
                  size: 16,
                  color: textColor,
                )
              else
                icon!,
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

/// 通过 InheritedWidget 向下传递 onNodeTap/onCenterTap，避免 rebuild 时丢失
class _NetworkSheetScope extends InheritedWidget {
  const _NetworkSheetScope({
    required this.onNodeTap,
    required this.onCenterTap,
    required super.child,
  });

  final void Function(Map<String, dynamic> person) onNodeTap;
  final void Function(Map<String, dynamic> centerUser) onCenterTap;

  static _NetworkSheetScope? of(BuildContext context) {
    return context.findAncestorWidgetOfExactType<_NetworkSheetScope>();
  }

  @override
  bool updateShouldNotify(_NetworkSheetScope old) =>
      onNodeTap != old.onNodeTap || onCenterTap != old.onCenterTap;
}

/// 与 TSX NetworkModal 一致：径向图布局（中心节点 + 周围 6 节点 + 连线），上一版（无移动端 70dvh/阴影/Expanded）
class _NetworkSheet extends StatefulWidget {
  const _NetworkSheet({
    required this.candidateId,
    this.onRefresh,
  });

  final int candidateId;
  final VoidCallback? onRefresh;

  @override
  State<_NetworkSheet> createState() => _NetworkSheetState();
}

/// 与 TSX extractUserId 一致：从 URL 提取分析用 user id
String? _extractUserId(String type, String? url) {
  if (url == null || url.isEmpty) return null;
  try {
    if (type == 'github') {
      final match = RegExp(r'github\.com/([^/?]+)').firstMatch(url);
      return match?.group(1);
    }
    if (type == 'scholar') {
      final uri = Uri.tryParse(url);
      return uri?.queryParameters['user'];
    }
    if (type == 'linkedin') {
      final match = RegExp(r'linkedin\.com/in/([^/?]+)').firstMatch(url);
      return match?.group(1);
    }
  } catch (_) {}
  return null;
}

/// 与 TSX buildFullAnalysisUrl 一致
String _buildAnalysisUrl(String type, String userId) {
  return '$analysisBaseUrl/$type?user=${Uri.encodeComponent(userId)}';
}

/// 与 TSX getSocialLinkUrl 一致：从 candidate.social_links 数组中按 type 取 url（option id 与 social_links 的 type 一致，scholar 对应 google_scholar）
String? _getSocialLinkUrl(Map<String, dynamic> candidate, String optionId) {
  final links = candidate['social_links'] as List<dynamic>?;
  if (links == null || links.isEmpty) return null;
  final type = optionId == 'scholar' ? 'google_scholar' : optionId;
  for (final e in links) {
    final m = e is Map ? e as Map<String, dynamic> : null;
    if (m != null && m['type']?.toString() == type) {
      final u = m['url']?.toString();
      if (u != null && u.isNotEmpty) return u;
      return null;
    }
  }
  return null;
}

/// Analyze 下拉选项（与 TSX AnalyzeButton options 一致）
const List<({String id, String label, String icon})> _kAnalyzeOptions = [
  (id: 'github', label: 'GitHub', icon: 'icons/search/lineicons/github.svg'),
  (id: 'scholar', label: 'Google Scholar', icon: 'icons/search/lineicons/scholar.svg'),
  (id: 'linkedin', label: 'LinkedIn', icon: 'icons/search/lineicons/linkedin.svg'),
];

/// 主卡片 Analyze 按钮+下拉（与 TSX AnalyzeButton 一致）
class _AnalyzeButtonCardDropdown extends StatefulWidget {
  const _AnalyzeButtonCardDropdown({required this.candidate});

  final Map<String, dynamic> candidate;

  @override
  State<_AnalyzeButtonCardDropdown> createState() => _AnalyzeButtonCardDropdownState();
}

class _AnalyzeButtonCardDropdownState extends State<_AnalyzeButtonCardDropdown> {
  bool _open = false;

  static const Duration _duration = Duration(milliseconds: 200);

  void _showOverlayMenu(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final screen = MediaQuery.sizeOf(context);
    final topLeft = box.localToGlobal(Offset.zero);
    final position = RelativeRect.fromLTRB(
      topLeft.dx,
      topLeft.dy + box.size.height,
      screen.width - (topLeft.dx + box.size.width),
      screen.height - (topLeft.dy + box.size.height),
    );
    setState(() => _open = true);
    await showMenu<void>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: const Color(0xFFF3F4F6),
      items: _kAnalyzeOptions.map((option) {
        final url = _getSocialLinkUrl(widget.candidate, option.id);
        final hasUrl = _extractUserId(option.id, url) != null;
        return PopupMenuItem<void>(
          enabled: hasUrl,
          onTap: () {
            if (!hasUrl) return;
            final userId = _extractUserId(option.id, url);
            if (userId == null) return;
            final targetUrl = _buildAnalysisUrl(option.id, userId);
            if (!_isValidHttpUrl(targetUrl)) return;
            try {
              launchUrl(Uri.parse(targetUrl), mode: LaunchMode.externalApplication);
            } catch (e) {
              debugPrint('launchUrl failed: $e');
            }
          },
          child: Row(
            children: [
              AssetIcon(
                asset: option.icon,
                size: 16,
                color: hasUrl ? const Color(0xFF374151) : const Color(0xFFD1D5DB),
              ),
              const SizedBox(width: 10),
              Text(
                option.label,
                style: TextStyle(
                  fontSize: 13,
                  color: hasUrl ? const Color(0xFF374151) : const Color(0xFFD1D5DB),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
    if (mounted) setState(() => _open = false);
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Builder(
        builder: (context) {
          return Material(
            color: _open ? const Color(0xFFF5F5F5) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: () => _showOverlayMenu(context),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const AssetIcon(
                      asset: 'icons/search/analyze.svg',
                      size: 16,
                      color: Color(0xFF4B5563),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Analyze',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                    const SizedBox(width: 4),
                    AnimatedRotation(
                      turns: _open ? 0.5 : 0,
                      duration: _duration,
                      curve: Curves.easeOut,
                      child: const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF4B5563)),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NetworkSheetState extends State<_NetworkSheet> {
  /// 点击头像后显示的 tooltip 对应用户（与 TSX hoveredUser 一致）
  Map<String, dynamic>? _tooltipUser;

  static int _networkTabCounter = 0;
  /// 正在 enrich 的用户名集合（与 TSX enrichingUsers 一致）
  final Set<String> _enrichingUsers = {};

  /// 与 TSX 一致：点击 Network 只更新弹层内的“中心用户”，不修改 tab、不打开新卡片。
  /// 弹层内维护 sheet 自己的 center/network，不写回 SearchStore。
  Map<String, dynamic>? _sheetCenterUser;
  List<dynamic>? _sheetNetwork;
  bool _sheetNetworkLoading = false;

  /// 与 TSX fetchNetwork 的 personData 一致：构建发给 getNetwork 的 person 对象（含 useful_info、social_links）
  Map<String, dynamic> _personDataForNetwork(Map<String, dynamic> person) {
    final socialLinks = <Map<String, String>>[];
    final linkedin = person['linkedin_url']?.toString();
    if (linkedin != null && linkedin.isNotEmpty) socialLinks.add({'type': 'linkedin', 'url': linkedin});
    final scholar = person['scholar_url']?.toString();
    if (scholar != null && scholar.isNotEmpty) socialLinks.add({'type': 'google_scholar', 'url': scholar});
    final github = person['github_url']?.toString();
    if (github != null && github.isNotEmpty) socialLinks.add({'type': 'github', 'url': github});
    final openreview = person['openreview_url']?.toString();
    if (openreview != null && openreview.isNotEmpty) socialLinks.add({'type': 'openreview', 'url': openreview});
    return <String, dynamic>{
      'name': person['name']?.toString() ?? 'Unknown',
      'match_reason': '',
      'useful_info': '',
      'company': person['company'],
      'image_url': person['image_url'] ?? person['avatar_url'],
      'social_links': socialLinks,
    };
  }

  void _moveToCenter(Map<String, dynamic> person) {
    if (person['name']?.toString().trim().isEmpty ?? true) return;
    final candidate = _personDataForNetwork(person);
    setState(() {
      _tooltipUser = null;
      _sheetCenterUser = candidate;
      _sheetNetwork = null;
      _sheetNetworkLoading = true;
    });
    SearchService().getNetwork({'person': candidate}).then((result) {
      if (!mounted) return;
      final network = (result['network'] as List<dynamic>? ?? []).take(6).toList();
      setState(() {
        _sheetNetwork = network;
        _sheetNetworkLoading = false;
      });
    }).catchError((e) {
      debugPrint('NetworkNodeTap getNetwork error: $e');
      if (mounted) {
        setState(() => _sheetNetworkLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载 Network 失败：$e')),
        );
      }
    });
  }

  /// 将 network 用户转为 openTab 用的 candidate（与 TSX localUserToCandidate 一致）
  Map<String, dynamic> _localUserToCandidate(Map<String, dynamic> user, String centerUserName) {
    final reason = user['reason']?.toString() ?? '';
    final matchReason = reason.isNotEmpty
        ? '$reason (from $centerUserName\'s network)'
        : 'From $centerUserName\'s network';
    final socialLinks = <Map<String, String>>[];
    final linkedin = user['linkedin_url']?.toString();
    if (linkedin != null && linkedin.isNotEmpty) socialLinks.add({'type': 'linkedin', 'url': linkedin});
    final scholar = user['scholar_url']?.toString();
    if (scholar != null && scholar.isNotEmpty) socialLinks.add({'type': 'google_scholar', 'url': scholar});
    final github = user['github_url']?.toString();
    if (github != null && github.isNotEmpty) socialLinks.add({'type': 'github', 'url': github});
    final openreview = user['openreview_url']?.toString();
    if (openreview != null && openreview.isNotEmpty) socialLinks.add({'type': 'openreview', 'url': openreview});
    return {
      'name': user['name']?.toString() ?? 'Unknown',
      'match_reason': matchReason,
      'useful_info': '',
      'company': user['company'],
      'position': user['position'],
      'image_url': user['image_url'] ?? user['avatar_url'],
      'social_links': socialLinks,
    };
  }

  /// 构建 enrich 请求体（与 TSX localUserToEnrichRequest 一致）
  Map<String, dynamic> _localUserToEnrichRequest(Map<String, dynamic> user) {
    final raw = [
      user['position']?.toString(),
      user['company']?.toString(),
      user['affiliation']?.toString(),
    ];
    final infoParts = raw.whereType<String>().where((s) => s.trim().isNotEmpty).toList();
    final usefulInfo = infoParts.isEmpty ? (user['name']?.toString() ?? '') : infoParts.join(', ');
    final sources = <Map<String, String>>[];
    final scholar = user['scholar_url']?.toString();
    if (scholar != null && scholar.isNotEmpty) sources.add({'url': scholar, 'description': 'Google Scholar'});
    final linkedin = user['linkedin_url']?.toString();
    if (linkedin != null && linkedin.isNotEmpty) sources.add({'url': linkedin, 'description': 'LinkedIn'});
    final github = user['github_url']?.toString();
    if (github != null && github.isNotEmpty) sources.add({'url': github, 'description': 'GitHub'});
    final openreview = user['openreview_url']?.toString();
    if (openreview != null && openreview.isNotEmpty) sources.add({'url': openreview, 'description': 'OpenReview'});
    return {
      'name': user['name']?.toString() ?? 'Unknown',
      'match_reason': user['reason']?.toString() ?? '',
      'useful_info': usefulInfo,
      'sources': sources,
    };
  }

  /// 将 enrich 接口返回转为 candidate（与 TSX 一致）
  Map<String, dynamic> _enrichResultToCandidate(Map<String, dynamic> enrichResult, String centerUserName) {
    final networkSource = '(from $centerUserName\'s network)';
    final mr = enrichResult['match_reason']?.toString() ?? '';
    final matchReason = mr.isNotEmpty ? '$mr $networkSource' : networkSource;
    final pos = enrichResult['position']?.toString();
    final company = enrichResult['company']?.toString();
    final uni = enrichResult['university']?.toString();
    final usefulInfo = [pos, company, uni].whereType<String>().where((s) => s.isNotEmpty).join(', ');
    return {
      'name': enrichResult['name'],
      'match_reason': matchReason,
      'useful_info': usefulInfo,
      'company': company,
      'position': pos,
      'university': uni,
      'email': enrichResult['email'],
      'research_areas': enrichResult['research_areas'],
      'personal_homepage': enrichResult['personal_homepage'],
      'image_url': enrichResult['image_url'],
      'one_liner': enrichResult['one_liner'],
      'social_links': enrichResult['social_links'],
      'key_publications': enrichResult['key_publications'],
      'news': enrichResult['news'],
    };
  }

  Future<void> _executeProfileEnrich(Map<String, dynamic> user, int tabId, String centerUserName) async {
    final name = user['name']?.toString() ?? 'Unknown';
    if (!mounted) return;
    setState(() => _enrichingUsers.add(name));
    
    final searchStore = context.read<SearchStore>();
    searchStore.setTabLoading(tabId, true);
    try {
      final request = _localUserToEnrichRequest(user);
      final result = await SearchService().enrich(request);
      final candidate = _enrichResultToCandidate(Map<String, dynamic>.from(result), centerUserName);
      searchStore.updateTabCandidate(tabId, candidate);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已加载 $name 的 Profile')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile 加载失败：$e')),
        );
        searchStore.setTabError(tabId, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _enrichingUsers.remove(name));
        searchStore.setTabLoading(tabId, false);
      }
    }
  }

  void _handleProfileClick(Map<String, dynamic> user, String centerUserName) {
    final name = user['name']?.toString() ?? 'Unknown';
    if (mounted) {
      TopToastUtil.showInfo(context: context, title: "Enriching $name's profile...");
    }
    if (_enrichingUsers.contains(name)) return;
    final searchStore = context.read<SearchStore>();
    // 已存在同名且来自 Network 的 tab 则不再添加，只提示
    final existing = searchStore.openTabs.where((t) =>
        t.candidate['groupId'] == -1 && (t.candidate['name']?.toString() ?? '') == name).firstOrNull;
    if (existing != null) {
      
      return;
    }
    final candidate = _localUserToCandidate(user, centerUserName);
    final uniqueIndex = ++_networkTabCounter;
    final tabId = searchStore.openTab(candidate, index: uniqueIndex, groupId: -1, matchByName: true, switchTab: false);
    if (tabId == null) {
      
      return;
    }
    final tab = searchStore.openTabs.where((t) => t.id == tabId).firstOrNull;
    if (tab != null && tab.profile == null && !tab.isLoading) {
      _executeProfileEnrich(user, tabId, centerUserName);
    } else if (mounted) {
      
    }
  }

  /// 刷新：不请求接口，只重置弹层并直接渲染外层角色 card 的 network
  void _refreshCurrentNetwork() {
    setState(() {
      _sheetCenterUser = null;
      _sheetNetwork = null;
      _sheetNetworkLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchStore = context.watch<SearchStore>();
    final tab = searchStore.openTabs.where((t) => t.id == widget.candidateId).firstOrNull;
    // 与 TSX 一致：点击 Network 只改弹层内中心，不写 tab。有 sheet 本地中心时用本地，否则用 tab
    final centerUser = _sheetCenterUser ?? tab?.candidate ?? <String, dynamic>{};
    final tabOwnerName = tab?.candidate['name']?.toString() ?? ''; // Profile match_reason 用 tab 主人，与 TSX currentUser 一致
    final items = _sheetCenterUser != null
        ? (_sheetNetwork ?? const [])
        : (tab?.network ?? const []);
    final hasConnections = items.isNotEmpty;
    final isLoading = _sheetCenterUser != null
        ? _sheetNetworkLoading
        : (tab?.networkLoading ?? false);

    void onNodeTap(Map<String, dynamic> person) {
      setState(() => _tooltipUser = person);
    }

    void onCenterTap(Map<String, dynamic> user) {
      setState(() => _tooltipUser = user);
    }

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFBFBFA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Stack(
          children: [
            _NetworkSheetScope(
              onNodeTap: onNodeTap,
              onCenterTap: onCenterTap,
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
                  Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.onRefresh != null) ...[
                          _NetworkSheetRefreshButton(
                            onPressed: _refreshCurrentNetwork,
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
            if (_tooltipUser != null)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => setState(() => _tooltipUser = null),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    color: Colors.black26,
                    alignment: Alignment.center,
                    child: _NetworkTooltipCard(
                        user: _tooltipUser!,
                        centerUser: centerUser,
                        defaultAvatarUrl: _defaultAvatarUrlForTooltip,
                        isEnriching: _tooltipUser!['name'] != null && _enrichingUsers.contains(_tooltipUser!['name']?.toString()),
                        onClose: () => setState(() => _tooltipUser = null),
                        onNetwork: () {
                          _moveToCenter(_tooltipUser!);
                          setState(() => _tooltipUser = null);
                        },
                        onProfile: () {
                          _handleProfileClick(_tooltipUser!, tabOwnerName);
                          // 两秒后自动关闭点击头像打开的 tooltip 弹框
                          Future.delayed(const Duration(seconds: 2), () {
                            if (mounted) setState(() => _tooltipUser = null);
                          });
                        },
                        onAnalyzeOption: (type, url) {
                          final userId = _extractUserId(type, url);
                          if (userId == null || !mounted) return;
                          final targetUrl = _buildAnalysisUrl(type, userId);
                          if (!_isValidHttpUrl(targetUrl)) return;
                          try {
                            launchUrl(Uri.parse(targetUrl), mode: LaunchMode.externalApplication);
                          } catch (e) {
                            debugPrint('launchUrl failed: $e');
                          }
                        },
                      ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _defaultAvatarUrlForTooltip(String? name) {
  if (name != null && name.trim().isNotEmpty) {
    return 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name.trim())}&background=e5e7eb&color=6b7280&size=128';
  }
  return '';
}

/// 与 TSX network-tooltip 一致：布局与样式对齐（content 灰底、两行按钮、Profile 黑底白字、Analyze 下拉）
class _NetworkTooltipCard extends StatefulWidget {
  const _NetworkTooltipCard({
    required this.user,
    required this.centerUser,
    required this.defaultAvatarUrl,
    required this.isEnriching,
    required this.onClose,
    required this.onNetwork,
    required this.onProfile,
    required this.onAnalyzeOption,
  });

  final Map<String, dynamic> user;
  final Map<String, dynamic> centerUser;
  final String Function(String? name) defaultAvatarUrl;
  final bool isEnriching;
  final VoidCallback onClose;
  final VoidCallback onNetwork;
  final VoidCallback onProfile;
  final void Function(String type, String? url) onAnalyzeOption;

  @override
  State<_NetworkTooltipCard> createState() => _NetworkTooltipCardState();
}

class _NetworkTooltipCardState extends State<_NetworkTooltipCard> {
  bool _analyzeDropdownOpen = false;

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final centerUser = widget.centerUser;
    final name = user['name']?.toString() ?? 'Unknown';
    final centerName = centerUser['name']?.toString() ?? '';
    final isCenterUser = name == centerName;

    final avatarUrl = user['image_url']?.toString() ?? user['avatar_url']?.toString();
    final avatarSrc = (avatarUrl != null && avatarUrl.isNotEmpty)
        ? avatarUrl
        : widget.defaultAvatarUrl(name);
    final position = user['position']?.toString();
    final company = user['company']?.toString() ?? user['affiliation']?.toString();
    final descField = user['description']?.toString();
    final description = (descField != null && descField.trim().isNotEmpty)
        ? descField.trim()
        : [position, company].whereType<String>().where((s) => s.trim().isNotEmpty).join(' · ');
    final institutionLogoUrl = user['institution_logo_url']?.toString();

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(10),
      color: const Color(0xFFF8F8F8),
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE0E0E0)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // tooltip-content：灰底 #f0f0f0，与 TSX .tooltip-content 一致
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // tooltip-avatar 56px + 可选 institution 角标
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: 0,
                          top: 0,
                          child: CircleAvatar(
                            radius: 28,
                            backgroundColor: const Color(0xFFE5E7EB),
                            backgroundImage: _isValidHttpUrl(avatarSrc) ? NetworkImage(avatarSrc) : null,
                            child: !_isValidHttpUrl(avatarSrc)
                                ? Text(
                                    name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
                                    style: const TextStyle(fontSize: 20, color: Color(0xFF6B7280)),
                                  )
                                : null,
                          ),
                        ),
                        if (_isValidHttpUrl(institutionLogoUrl))
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                                shape: BoxShape.circle,
                              ),
                              child: ClipOval(
                                child: Image.network(
                                  institutionLogoUrl!,
                                  fit: BoxFit.contain,
                                  width: 14,
                                  height: 14,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.business, size: 14),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF171717),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9CA3AF),
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // tooltip-buttons：两行，与 TSX 一致
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 第一行：Network（非中心用户时显示）+ Profile
                Row(
                  children: [
                    if (!isCenterUser) ...[
                      Expanded(
                        child: _tooltipButton(
                          label: 'Network',
                          icon: 'icons/search/network.svg',
                          bgColor: const Color(0xFFF3F4F6),
                          fgColor: const Color(0xFF171717),
                          border: const BorderSide(color: Color(0xFFE5E7EB)),
                          onPressed: widget.onNetwork,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: _tooltipButton(
                        label: 'Profile',
                        icon: 'icons/search/enrich.svg',
                        bgColor: widget.isEnriching ? const Color(0xFF333333) : Colors.black,
                        fgColor: Colors.white,
                        border: const BorderSide(color: Colors.black, width: 2),
                        onPressed: widget.isEnriching ? null : widget.onProfile,
                        loading: widget.isEnriching,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // 第二行：Analyze 下拉
                _AnalyzeDropdownSection(
                  user: user,
                  isOpen: _analyzeDropdownOpen,
                  options: _kAnalyzeOptions,
                  onToggle: () => setState(() => _analyzeDropdownOpen = !_analyzeDropdownOpen),
                  onSelect: (id, url) {
                    widget.onAnalyzeOption(id, url);
                    setState(() => _analyzeDropdownOpen = false);
                  },
                  extractUserId: _extractUserId,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tooltipButton({
    required String label,
    required String icon,
    required Color bgColor,
    required Color fgColor,
    required BorderSide border,
    VoidCallback? onPressed,
    bool loading = false,
  }) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border.color, width: border.width),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              else
                AssetIcon(asset: icon, size: 14, color: fgColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: fgColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Analyze 下拉区域：主按钮 + 下拉项（与 TSX analyze-dropdown-container 一致），带展开/收起动画
class _AnalyzeDropdownSection extends StatelessWidget {
  const _AnalyzeDropdownSection({
    required this.user,
    required this.isOpen,
    required this.options,
    required this.onToggle,
    required this.onSelect,
    required this.extractUserId,
  });

  final Map<String, dynamic> user;
  final bool isOpen;
  final List<({String id, String label, String icon})> options;
  final VoidCallback onToggle;
  final void Function(String id, String? url) onSelect;
  final String? Function(String type, String? url) extractUserId;

  static const Duration _dropdownDuration = Duration(milliseconds: 200);
  static const Curve _dropdownCurve = Curves.easeOut;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: isOpen ? const Color(0xFFF5F5F5) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(10),
            topRight: const Radius.circular(10),
            bottomLeft: Radius.circular(isOpen ? 0 : 10),
            bottomRight: Radius.circular(isOpen ? 0 : 10),
          ),
          child: InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(10),
                  topRight: const Radius.circular(10),
                  bottomLeft: Radius.circular(isOpen ? 0 : 10),
                  bottomRight: Radius.circular(isOpen ? 0 : 10),
                ),
                border: Border.all(color: const Color(0xFF171717), width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const AssetIcon(asset: 'icons/search/analyze.svg', size: 14, color: Color(0xFF171717)),
                  const SizedBox(width: 8),
                  const Text(
                    'Analyze',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF171717)),
                  ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: isOpen ? 0.5 : 0,
                    duration: _dropdownDuration,
                    curve: _dropdownCurve,
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      size: 14,
                      color: Color(0xFF171717),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: _dropdownDuration,
          curve: _dropdownCurve,
          alignment: Alignment.topCenter,
          child: AnimatedOpacity(
            duration: _dropdownDuration,
            curve: _dropdownCurve,
            opacity: isOpen ? 1 : 0,
            child: isOpen
                ? Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        left: const BorderSide(color: Color(0xFF171717), width: 1.5),
                        right: const BorderSide(color: Color(0xFF171717), width: 1.5),
                        bottom: const BorderSide(color: Color(0xFF171717), width: 1.5),
                      ),
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final option in options) ...[
                          Builder(
                            builder: (context) {
                              final url = _getSocialLinkUrl(user, option.id);
                              final hasUrl = extractUserId(option.id, url) != null;
                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: hasUrl ? () => onSelect(option.id, url) : null,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    child: Row(
                                      children: [
                                        AssetIcon(
                                          asset: option.icon,
                                          size: 16,
                                          color: hasUrl ? const Color(0xFF171717) : const Color(0xFFD1D5DB),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          option.label,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: hasUrl ? const Color(0xFF171717) : const Color(0xFFD1D5DB),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
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
        onTap: onPressed,
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
    final scope = _NetworkSheetScope.of(context);
    final onNodeTap = scope?.onNodeTap;
    final onCenterTap = scope?.onCenterTap;

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

    final centerOffset = Offset(centerX, centerY);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: centerX - 200+100,
          top: centerY - 200+100,
          width: 200,
          height: 200,
          child: IgnorePointer(
            child: Opacity(
              opacity: 0.7,
              child: SvgPicture.asset(
                'assets/images/network_modal_bg.svg',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        IgnorePointer(
          child: CustomPaint(
            size: Size(w, 440),
            painter: _NetworkLinesPainter(
              center: centerOffset,
              nodePositions: nodePositions,
            ),
          ),
        ),
        Positioned(
          left: centerX - _centerRadius,
          top: centerY - _centerRadius,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onCenterTap != null ? () => onCenterTap(centerUser) : null,
            child: _CenterNode(
              name: centerUser['name']?.toString() ?? 'Unknown',
              avatarUrl: centerUser['image_url']?.toString() ?? centerUser['avatar_url']?.toString(),
            ),
          ),
        ),
        for (var i = 0; i < n; i++) ...[
          () {
            final index = i;
            final item = items[index] is Map<String, dynamic> ? items[index] as Map<String, dynamic> : <String, dynamic>{};
            return Positioned(
              left: nodePositions[index].dx - _nodeRadius,
              top: nodePositions[index].dy - _nodeRadius,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onNodeTap != null
                    ? () {
                        debugPrint('NetworkNode onTap: index=$index, name=${item['name']}');
                        try {
                          onNodeTap(item);
                          debugPrint('NetworkNode onTap: onNodeTap returned');
                        } catch (e, st) {
                          debugPrint('NetworkNode onTap: onNodeTap threw $e\n$st');
                        }
                      }
                    : () => debugPrint('NetworkNode onTap: onNodeTap is null'),
                child: _NetworkNode(item: item),
              ),
            );
          }(),
        ],
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
            backgroundImage: _isValidHttpUrl(avatarUrl) ? NetworkImage(avatarUrl!) : null,
            child: !_isValidHttpUrl(avatarUrl) ? Icon(Icons.school, size: 28, color: Colors.grey[400]) : null,
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
    final avatarSrc = (avatarUrl != null && avatarUrl.isNotEmpty) ? avatarUrl : _defaultAvatarUrlForTooltip(name);
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
            backgroundImage: _isValidHttpUrl(avatarSrc) ? NetworkImage(avatarSrc) : null,
            child: !_isValidHttpUrl(avatarSrc)
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
                      if (_isValidHttpUrl(url))
                        WidgetSpan(
                          alignment: PlaceholderAlignment.baseline,
                          baseline: TextBaseline.alphabetic,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: GestureDetector(
                              onTap: () {
                                try {
                                  launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                                } catch (e) {
                                  debugPrint('launchUrl failed: $e');
                                }
                              },
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
        onTap: _isValidHttpUrl(url)
            ? () {
                try {
                  launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                } catch (e) {
                  debugPrint('launchUrl failed: $e');
                }
              }
            : null,
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
                  children: _renderBold(
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
