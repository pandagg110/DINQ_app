import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/recommendation_models.dart' as rec;
import '../../pages/discover/paper_filters_page.dart'
    show getSelectedFilterItems;
import '../../services/recommendation_service.dart';

// ---------- RecommendedPapers 主组件 ----------

class RecommendedPapersWidget extends StatefulWidget {
  const RecommendedPapersWidget({
    super.key,
    this.userId,
    this.isFullView = false,
    this.initialFilters,
    this.onFiltersChanged,
    this.onBack,
    this.onPeekClick,
    this.onSearchAuthorAndBack,
  });

  final String? userId;
  final bool isFullView;

  /// 外部传入的筛选条件，变化时会同步并重新请求列表
  final rec.PaperFiltersState? initialFilters;

  /// 当用户在列表页通过标签移除某项筛选时回调，用于与 TSX ActiveFilterTags 行为一致
  final ValueChanged<rec.PaperFiltersState>? onFiltersChanged;
  final VoidCallback? onBack;
  final VoidCallback? onPeekClick;

  /// 点击 Find Authors 时调用并传入搜索文案，调用方负责 pop 并触发搜索
  final ValueChanged<String>? onSearchAuthorAndBack;

  @override
  State<RecommendedPapersWidget> createState() =>
      _RecommendedPapersWidgetState();
}

class _RecommendedPapersWidgetState extends State<RecommendedPapersWidget> {
  List<rec.RecommendedPaper> _papers = [];
  String _mode = 'recommend'; // 'recommend' | 'similar'
  rec.PaperFiltersState _filters = rec.PaperFiltersState();
  bool _loading = false;

  /// 点击 Similar 时选中的卡片（用于记录并展示）
  rec.RecommendedPaper? _similarSourcePaper;

  @override
  void initState() {
    super.initState();
    if (widget.initialFilters != null) {
      _filters = _copyFilters(widget.initialFilters!);
    }
    if (widget.userId != null && widget.userId!.isNotEmpty) {
      _loadRecommendations();
    }
  }

  @override
  void didUpdateWidget(RecommendedPapersWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialFilters != null &&
        _filters != widget.initialFilters &&
        !_filtersEqual(_filters, widget.initialFilters!)) {
      _filters = _copyFilters(widget.initialFilters!);
      if (widget.userId != null && widget.userId!.isNotEmpty) {
        _loadRecommendations();
      }
    }
  }

  static rec.PaperFiltersState _copyFilters(rec.PaperFiltersState f) {
    return rec.PaperFiltersState(
      conference: List.from(f.conference),
      year: List.from(f.year),
      status: List.from(f.status),
      group: List.from(f.group),
    );
  }

  static bool _filtersEqual(rec.PaperFiltersState a, rec.PaperFiltersState b) {
    if (a.conference.length != b.conference.length ||
        a.year.length != b.year.length ||
        a.status.length != b.status.length ||
        a.group.length != b.group.length)
      return false;
    for (final x in a.conference) if (!b.conference.contains(x)) return false;
    for (final x in a.year) if (!b.year.contains(x)) return false;
    for (final x in a.status) if (!b.status.contains(x)) return false;
    for (final x in a.group) if (!b.group.contains(x)) return false;
    return true;
  }

  final RecommendationService _recommendationService = RecommendationService();

  Future<void> _loadRecommendations() async {
    final userId = widget.userId;
    if (userId == null || userId.isEmpty) return;
    setState(() => _loading = true);
    try {
      final list = await _recommendationService.recommendPapers(
        userId: userId,
        limit: 20,
        conference: _filters.conference.isEmpty ? null : _filters.conference,
        year: _filters.year.isEmpty ? null : _filters.year,
        status: _filters.status.isEmpty ? null : _filters.status,
        group: _filters.group.isEmpty ? null : _filters.group,
      );
      if (!mounted) return;
      setState(() {
        _loading = false;
        _papers = list;
        _mode = 'recommend';
      });
    } catch (e, st) {
      debugPrint('RecommendPapers load error: $e $st');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _papers = [];
      });
    }
  }

  void _handleBackToRecommend() {
    setState(() => _mode = 'recommend');
    _loadRecommendations();
  }

  void _handleOpenPaper(rec.RecommendedPaper paper) {
    final userId = widget.userId;
    if (userId == null || userId.isEmpty) return;
    _recommendationService
        .updateInterest(userId: userId, paperUid: paper.paperUid)
        .catchError((e) {
          debugPrint('updateInterest error: $e');
        });
  }

  void _handleSearchAuthor(rec.RecommendedPaper paper) {
    final query = 'Find all authors from "${paper.data.title}"';
    if (widget.onSearchAuthorAndBack != null) {
      widget.onSearchAuthorAndBack!(query);
    } else {
      debugPrint('Search author: $query');
    }
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'PAPERS',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF171717),
            ),
          ),
          const SizedBox(height: 16),
          if (widget.onBack != null)
            TextButton(
              onPressed: widget.onBack,
              child: const Text('Back to Search'),
            ),
        ],
      ),
    );
  }

  Future<void> _handleSearchSimilar(rec.RecommendedPaper paper) async {
    _similarSourcePaper = paper;
    debugPrint('Similar source card title: ${paper.data.title}');
    setState(() {
        _loading = true;
        _mode = 'similar';
      });
    try {
      final list = await _recommendationService.matchPapers(
        paperUid: paper.paperUid,
        matchCount: 20,
      );
      if (!mounted) return;
      setState(() {
        _loading = false;
        _mode = 'similar';
        _papers = list;
      });
    } catch (e, st) {
      debugPrint('MatchPapers error: $e $st');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _papers = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.userId == null || widget.userId!.isEmpty) {
      return _buildPlaceholder();
    }

    // 仅移动端样式：Column 用 max 保证 header 始终占位，避免 loading 时被挤掉
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStickyHeader(),
              Expanded(child: _buildContent()),
            ],
          ),
          if (!widget.isFullView && widget.onPeekClick != null)
            _buildPeekOverlay(),
        ],
      ),
    );
  }

  Widget _buildPeekOverlay() {
    // 移动端：h-[8%]、pt-8、gap-2、w-8、text-xs
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final topHeight = constraints.maxHeight * 0.08; // 8%
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onPeekClick,
              child: Column(
                children: [
                  Container(
                    height: topHeight,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFFFBFBFA),
                          const Color(0xFFFBFBFA).withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 32), // pt-8
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 32,
                          height: 1,
                          color: const Color(0xFFE5E7EB),
                        ), // w-8
                        const SizedBox(width: 8), // gap-2
                        const Text(
                          'Try Finding Talent via Hot Research',
                          style: TextStyle(
                            fontSize: 12, // text-xs
                            fontWeight: FontWeight.w300,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 32,
                          height: 1,
                          color: const Color(0xFFE5E7EB),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStickyHeader() {
    // 移动端：pt-6 pb-4、px-4，与 TSX sticky header 一致
    if (!widget.isFullView) {
      return const SizedBox(height: 24); // 与 TSX h-6 占位一致
    }
    // 仅 recommend 模式显示已选筛选标签（与 TSX ActiveFilterTags 一致）
    final showFilterTags = _mode == 'recommend';
    final selectedItems = showFilterTags
        ? getSelectedFilterItems(_filters)
        : <({String key, dynamic value, String label})>[];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFBFA).withOpacity(0.95),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 无内容时也占位，避免 loading 时 header 区域塌陷为 0
            if (_mode != 'similar' && selectedItems.isEmpty)
              const SizedBox(height: 8),
            if (_mode == 'similar' && _similarSourcePaper != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: _handleBackToRecommend,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F4FD), // 浅蓝背景
                      borderRadius: BorderRadius.circular(20), // 胶囊形
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0D000000),
                          offset: Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(
                          child: RichText(
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              children: [
                                const TextSpan(
                                  text: 'Similar Paper: ',
                                  style: TextStyle(
                                    color: Color(0x991487FA), // #1487FA99
                                  ),
                                ),
                                TextSpan(
                                  text: _similarSourcePaper!.data.title,
                                  style: const TextStyle(
                                    color: Color(0xFF1487FA),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.close,
                          size: 16,
                          color: Color(0xFF171717),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (selectedItems.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: selectedItems.map((item) {
                  return _ActiveFilterChip(
                    label: item.label,
                    onRemove: () => _removeFilter(item.key, item.value),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  void _removeFilter(String key, dynamic value) {
    rec.PaperFiltersState next;
    switch (key) {
      case 'conference':
        next = _filters.copyWith(
          conference: _filters.conference.where((v) => v != value).toList(),
        );
        break;
      case 'year':
        next = _filters.copyWith(
          year: _filters.year.where((v) => v != value).toList(),
        );
        break;
      case 'status':
        next = _filters.copyWith(
          status: _filters.status.where((v) => v != value).toList(),
        );
        break;
      case 'group':
        next = _filters.copyWith(
          group: _filters.group.where((v) => v != value).toList(),
        );
        break;
      default:
        return;
    }
    widget.onFiltersChanged?.call(next);
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_loading) _buildLoadingGrid(),
          if (!_loading && _papers.isNotEmpty) _buildPapersGrid(),
          if (!_loading && _papers.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'No recommendations available',
                  style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingGrid() {
    // 移动端：单列
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return Wrap(
          spacing: 24,
          runSpacing: 24,
          children: List.generate(
            6,
            (_) => SizedBox(
              width: width,
              height: 280,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPapersGrid() {
    // 移动端：单列，gap-6
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 24.0; // gap-6
        final itemWidth = constraints.maxWidth;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: _papers.map((paper) {
            return SizedBox(
              width: itemWidth,
              child: _PaperCard(
                paper: paper,
                sourcePaper: _similarSourcePaper,
                onOpenPaper: _handleOpenPaper,
                onSearchSimilar: _handleSearchSimilar,
                onSearchAuthor: _handleSearchAuthor,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ---------- 已选筛选标签（与 TSX ActiveFilterTags 一致）----------

class _ActiveFilterChip extends StatelessWidget {
  const _ActiveFilterChip({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(Icons.close, size: 14, color: Color(0xFF4B5563)),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- 论文卡片（简化版）----------

class _PaperCard extends StatefulWidget {
  const _PaperCard({
    required this.paper,
    this.sourcePaper,
    required this.onOpenPaper,
    required this.onSearchSimilar,
    required this.onSearchAuthor,
  });

  final rec.RecommendedPaper paper;
  /// 当前「Similar」来源论文，匹配到的卡片边框高亮 #1487FA 2px
  final rec.RecommendedPaper? sourcePaper;
  final ValueChanged<rec.RecommendedPaper> onOpenPaper;
  final ValueChanged<rec.RecommendedPaper> onSearchSimilar;
  final ValueChanged<rec.RecommendedPaper> onSearchAuthor;

  @override
  State<_PaperCard> createState() => _PaperCardState();
}

class _PaperCardState extends State<_PaperCard> {
  static ({String venue, String? level}) _parseSubject(String? subject) {
    if (subject == null || subject.isEmpty) return (venue: '', level: null);
    final parts = subject.split(' - ');
    final venue = (parts.isNotEmpty
        ? parts[0].replaceAll('.', ' ').trim()
        : subject);
    final level = parts.length > 1 ? parts[1].trim() : null;
    return (venue: venue, level: level);
  }

  @override
  Widget build(BuildContext context) {
    final subject = widget.paper.data.subjects.isNotEmpty
        ? widget.paper.data.subjects.first
        : null;
    final parsed = _parseSubject(subject);
    final authors = widget.paper.data.authors;
    const maxAuthors = 3;
    final visible = authors.take(maxAuthors).toList();
    final remaining = authors.length - maxAuthors;
    final paperUrl = widget.paper.data.links.pdf?.isNotEmpty == true
        ? widget.paper.data.links.pdf!.first
        : (widget.paper.data.links.link?.isNotEmpty == true
              ? widget.paper.data.links.link!.first
              : null);

    final isSourcePaper = widget.sourcePaper != null &&
        widget.paper.paperUid == widget.sourcePaper!.paperUid;

    // 移动端：无 hover，固定阴影；匹配 sourcePaper 时边框高亮 #1487FA 2px
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSourcePaper ? const Color(0xFF1487FA) : const Color(0xFFF3F4F6),
          width: 2, // 统一 2px 避免高亮时布局偏移
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (parsed.venue.isNotEmpty || parsed.level != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  if (parsed.venue.isNotEmpty)
                    Text(
                      parsed.venue.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  if (parsed.venue.isNotEmpty && parsed.level != null)
                    const Text(
                      ' · ',
                      style: TextStyle(color: Color(0xFFD1D5DB)),
                    ),
                  if (parsed.level != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB).withOpacity(0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        parsed.level!,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          Text(
            widget.paper.data.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111111),
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (authors.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              visible.join(', ') + (remaining > 0 ? ' +$remaining' : ''),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (widget.paper.data.summary.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Abstract: ${widget.paper.data.summary}',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ActionChip(
                icon: Icons.person_search,
                label: 'Find Authors',
                onTap: () => widget.onSearchAuthor(widget.paper),
              ),
              _ActionChip(
                icon: Icons.search,
                label: 'Similar',
                onTap: () => widget.onSearchSimilar(widget.paper),
              ),
              if (paperUrl != null)
                _ActionChip(
                  icon: Icons.open_in_new,
                  label: 'PDF',
                  onTap: () async {
                    widget.onOpenPaper(widget.paper);
                    final url = paperUrl;
                    try {
                      final launched = await launchUrl(
                        Uri.parse(url),
                        mode: LaunchMode.externalApplication,
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(launched ? '下载完成' : '无法打开链接')),
                        );
                      }
                    } catch (_) {
                      if (mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(const SnackBar(content: Text('无法打开链接')));
                      }
                    }
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF3F4F6),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: const Color(0xFF6B7280)),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
