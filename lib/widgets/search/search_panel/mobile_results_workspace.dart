import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../pages/shortlist/shortlist_strings.dart';
import '../../../pages/shortlist/widgets/shortlist_shared_widgets.dart';
import '../../../services/search_service.dart';
import '../../../services/shortlist_service.dart';
import '../../../stores/deep_search_enrich_store.dart';
import '../../../stores/user_store.dart';
import '../../../theme/dinq_icons.dart';
import '../../../theme/dinq_tokens.dart';
import '../../../widgets/common/dinq_svg_icon.dart';
import '../../../widgets/common/swipe_back_page.dart';
import '../deep_search/deep_search_models.dart';
import '../deep_search/deep_search_results_helpers.dart';
import '../deep_search/deep_search_results_strings.dart';
import '../enrich/shortlist_folder_modal.dart';

/// 移动端搜索结果全屏页：布局对齐 Figma，多选交互对齐 Shortlist。
class MobileResultsWorkspace extends StatefulWidget {
  const MobileResultsWorkspace({
    super.key,
    required this.candidates,
    required this.isSearching,
    required this.isInterrupted,
    required this.onClose,
    required this.onRowClick,
    this.selectedRowId,
    this.roundStatus = DeepSearchRoundStatus.idle,
    this.contentBlocks = const [],
    this.subAgents = const {},
    this.sessionId,
    this.sseEventsId,
  });

  final List<Map<String, dynamic>> candidates;
  final bool isSearching;
  final bool isInterrupted;
  final VoidCallback onClose;
  final void Function(Map<String, dynamic> row) onRowClick;
  final String? selectedRowId;
  final DeepSearchRoundStatus roundStatus;
  final List<MessagePart> contentBlocks;
  final Map<String, SubAgentInfo> subAgents;
  final String? sessionId;
  final String? sseEventsId;

  @override
  State<MobileResultsWorkspace> createState() => _MobileResultsWorkspaceState();
}

class _MobileResultsWorkspaceState extends State<MobileResultsWorkspace> {
  final _shortlistService = ShortlistService();
  final _searchService = SearchService();
  final _favoriteMap = <String, String>{};
  final _selectedIds = <String>{};
  final _moreKey = GlobalKey();
  final _listScrollController = ScrollController();

  var _selectionMode = false;
  var _isSaving = false;
  var _isExportingPdf = false;
  var _resultsCopied = false;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  @override
  void dispose() {
    _listScrollController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _rows => sortCandidateRows(
        widget.candidates,
        column: DeepSearchResultsSortColumn.confidence,
        ascending: false,
      );

  List<String> get _visibleIds => _rows
      .map((r) => r['row_id']?.toString() ?? '')
      .where((id) => id.isNotEmpty)
      .toList();

  List<Map<String, dynamic>> get _selectedRows => _rows
      .where((r) => _selectedIds.contains(r['row_id']?.toString()))
      .toList();

  List<Map<String, dynamic>> get _selectedUnsavedRows => _selectedRows
      .where((row) => !_favoriteMap.containsKey(row['row_id']?.toString()))
      .toList();

  bool get _allVisibleSelected =>
      _visibleIds.isNotEmpty &&
      _visibleIds.every(_selectedIds.contains);

  Future<void> _loadFavorites() async {
    try {
      final items = await _shortlistService.listFavorites();
      if (!mounted) return;
      final map = <String, String>{};
      for (final item in items) {
        final rowId = item.field['row_id']?.toString();
        if (rowId != null && rowId.isNotEmpty) map[rowId] = item.id;
      }
      setState(() {
        _favoriteMap
          ..clear()
          ..addAll(map);
      });
    } catch (_) {}
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _enterSelectionMode([String? initialId]) {
    setState(() {
      _selectionMode = true;
      if (initialId != null && initialId.isNotEmpty) {
        _selectedIds.add(initialId);
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  void _toggleSelected(String rowId) {
    if (rowId.isEmpty) return;
    setState(() {
      if (!_selectionMode) _selectionMode = true;
      if (_selectedIds.contains(rowId)) {
        _selectedIds.remove(rowId);
      } else {
        _selectedIds.add(rowId);
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_allVisibleSelected) {
        _selectedIds.removeAll(_visibleIds);
      } else {
        _selectedIds.addAll(_visibleIds);
      }
    });
  }

  Future<void> _handleCopyResults() async {
    final rows = _selectionMode && _selectedRows.isNotEmpty
        ? _selectedRows
        : _rows;
    if (rows.isEmpty) return;
    await Clipboard.setData(
      ClipboardData(text: buildSearchResultsMarkdown(rows)),
    );
    setState(() => _resultsCopied = true);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _resultsCopied = false);
    });
    _showToast('Copied');
  }

  Future<void> _handleShare() async {
    _showToast(DeepSearchResultsStrings.toastComingSoon);
  }

  Future<void> _showMoreMenu() async {
    final box = _moreKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        box.localToGlobal(Offset.zero, ancestor: overlay),
        box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );
    final value = await showMenu<String>(
      context: context,
      position: position,
      color: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFEAE8E3)),
      ),
      items: [
        PopupMenuItem(
          value: 'share',
          child: Row(
            children: [
              const Icon(Icons.ios_share_outlined, size: 18, color: Color(0xFF171717)),
              const SizedBox(width: 10),
              Text(
                DeepSearchResultsStrings.headerShare,
                style: const TextStyle(fontSize: 14, color: Color(0xFF171717)),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'copy',
          child: Row(
            children: [
              Icon(
                _resultsCopied ? Icons.check : Icons.copy_outlined,
                size: 18,
                color: const Color(0xFF171717),
              ),
              const SizedBox(width: 10),
              const Text(
                'Copy',
                style: TextStyle(fontSize: 14, color: Color(0xFF171717)),
              ),
            ],
          ),
        ),
      ],
    );
    if (value == 'share') await _handleShare();
    if (value == 'copy') await _handleCopyResults();
  }

  Future<void> _handleMoveToShortlist() async {
    if (_selectedRows.isEmpty) {
      _showToast(DeepSearchResultsStrings.toastSelectCandidatesFirst);
      return;
    }
    if (_selectedUnsavedRows.isEmpty) {
      _showToast(DeepSearchResultsStrings.toastAlreadySaved);
      return;
    }
    final projectId = await showShortlistFolderModal(context);
    if (projectId == null || !mounted) return;
    setState(() => _isSaving = true);
    var savedCount = 0;
    try {
      for (final row in _selectedUnsavedRows) {
        final payload = buildFavoritePayload(row);
        final item = await _shortlistService.createFavorite(
          projectId: projectId,
          title: payload['title']?.toString() ?? '',
          field: Map<String, dynamic>.from(
            payload['field'] as Map? ?? const {},
          ),
        );
        final rowId = row['row_id']?.toString();
        if (rowId != null && rowId.isNotEmpty) {
          _favoriteMap[rowId] = item.id;
        }
        savedCount++;
      }
    } catch (_) {
      if (mounted) _showToast('Failed to save candidates');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
    if (!mounted) return;
    _showToast(
      DeepSearchResultsStrings.toastSavedCandidates(
        savedCount > 0 ? savedCount : _selectedUnsavedRows.length,
      ),
    );
    _exitSelectionMode();
  }

  Future<void> _handleRemoveFromShortlist() async {
    final toRemove = _selectedRows
        .map((r) => r['row_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty && _favoriteMap.containsKey(id))
        .toList();
    if (toRemove.isEmpty) {
      _showToast('Selected candidates are not in shortlist');
      return;
    }
    var removed = 0;
    try {
      for (final rowId in toRemove) {
        final favId = _favoriteMap[rowId];
        if (favId == null) continue;
        await _shortlistService.removeFavorite(favId);
        _favoriteMap.remove(rowId);
        removed++;
      }
    } catch (_) {
      if (mounted) _showToast('Failed to remove from shortlist');
      return;
    }
    if (!mounted) return;
    setState(() {});
    _showToast(
      DeepSearchResultsStrings.toastRemovedFromShortlistCount(removed),
    );
    _exitSelectionMode();
  }

  Rect? _shareOrigin() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  Future<void> _shareAsFile(String content, String ext) async {
    try {
      final date = DateTime.now().toIso8601String().substring(0, 10);
      final filename = 'search-results-$date.$ext';
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsString(content);
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: filename,
        sharePositionOrigin: _shareOrigin(),
      );
    } catch (_) {
      if (mounted) _showToast(DeepSearchResultsStrings.exportFailed);
    }
  }

  Future<void> _exportCsv() async {
    final rows =
        _selectionMode && _selectedRows.isNotEmpty ? _selectedRows : _rows;
    await _shareAsFile(buildSearchResultsCsv(rows), 'csv');
  }

  Future<void> _exportMarkdown() async {
    final rows =
        _selectionMode && _selectedRows.isNotEmpty ? _selectedRows : _rows;
    await _shareAsFile(buildSearchResultsMarkdown(rows), 'md');
  }

  Future<void> _handleExportPdf() async {
    if (_isExportingPdf) return;
    if (widget.roundStatus != DeepSearchRoundStatus.done) {
      _showToast(DeepSearchResultsStrings.exportWaitForFinish);
      return;
    }
    final userId = context.read<UserStore>().user?.user.id;
    final sessionId = widget.sessionId;
    final sseEventsId = widget.sseEventsId;
    if (userId == null ||
        userId.isEmpty ||
        sessionId == null ||
        sessionId.isEmpty ||
        sseEventsId == null ||
        sseEventsId.isEmpty) {
      _showToast(DeepSearchResultsStrings.exportPdfUnavailable);
      return;
    }
    setState(() => _isExportingPdf = true);
    try {
      final bytes = await _searchService.exportDeepSearchPdf(
        userId: userId,
        sessionId: sessionId,
        sseEventsId: sseEventsId,
      );
      if (bytes.isEmpty) throw StateError('empty pdf');
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/deep-search-$sessionId.pdf');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'deep-search-$sessionId.pdf',
        sharePositionOrigin: _shareOrigin(),
      );
    } catch (e) {
      if (!mounted) return;
      _showToast(
        e is SearchExportException
            ? e.message
            : DeepSearchResultsStrings.exportFailed,
      );
    } finally {
      if (mounted) setState(() => _isExportingPdf = false);
    }
  }

  bool get _pdfExportDisabled =>
      _isExportingPdf ||
      widget.sseEventsId == null ||
      widget.sseEventsId!.isEmpty ||
      widget.roundStatus != DeepSearchRoundStatus.done;

  Future<void> _showExportMenu() async {
    final value = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('CSV'),
              onTap: () => Navigator.pop(ctx, 'csv'),
            ),
            ListTile(
              title: const Text('Markdown'),
              onTap: () => Navigator.pop(ctx, 'markdown'),
            ),
            ListTile(
              enabled: !_pdfExportDisabled,
              title: Text(
                'PDF',
                style: TextStyle(
                  color: _pdfExportDisabled
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF171717),
                ),
              ),
              onTap: _pdfExportDisabled ? null : () => Navigator.pop(ctx, 'pdf'),
            ),
          ],
        ),
      ),
    );
    switch (value) {
      case 'csv':
        await _exportCsv();
      case 'markdown':
        await _exportMarkdown();
      case 'pdf':
        await _handleExportPdf();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final showBatchBar = _selectionMode && _selectedIds.isNotEmpty;

    return SwipeBackPage(
      onBack: widget.onClose,
      // 详情（Enrich）打开时，优先让上层处理返回
      shouldHandlePop: () => !context.read<DeepSearchEnrichStore>().isOpen,
      child: Material(
        color: DinqTokens.bgPage,
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            DeepSearchResultsStrings.headerTitle,
                            style: TextStyle(
                              fontSize: 14,
                              height: 20 / 14,
                              fontWeight: FontWeight.w700,
                              color: DinqTokens.textPrimary,
                              fontFamily: 'Geist',
                            ),
                          ),
                        ),
                      Text(
                        '${_rows.length}',
                        style: const TextStyle(
                          fontSize: 14,
                          height: 20 / 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF8A8880),
                          fontFamily: 'Geist',
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _rows.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              widget.isSearching
                                  ? DeepSearchResultsStrings.searchingNotice
                                  : DeepSearchResultsStrings.empty,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                color: DinqTokens.textSecondary,
                              ),
                            ),
                          ),
                        )
                      : Scrollbar(
                          controller: _listScrollController,
                          thumbVisibility: true,
                          child: ListView.separated(
                            controller: _listScrollController,
                            padding: EdgeInsets.fromLTRB(
                              16,
                              0,
                              16,
                              showBatchBar
                                  ? 100 + bottomInset
                                  : 24 + bottomInset,
                            ),
                            itemCount: _rows.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final row = _rows[index];
                              final rowId = row['row_id']?.toString() ?? '';
                              final selected = _selectedIds.contains(rowId);
                              return _SearchResultCandidateCard(
                                row: row,
                                selectionMode: _selectionMode,
                                isSelected: selected,
                                onTap: () {
                                  if (_selectionMode) {
                                    _toggleSelected(rowId);
                                  } else {
                                    widget.onRowClick(
                                      candidateRowToTabCandidate(row),
                                    );
                                  }
                                },
                                onLongPress: () {
                                  if (_selectionMode) {
                                    _toggleSelected(rowId);
                                  } else {
                                    _enterSelectionMode(rowId);
                                  }
                                },
                                onToggleSelect: () => _toggleSelected(rowId),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
            if (showBatchBar)
              Positioned(
                left: 16,
                right: 16,
                bottom: 18 + bottomInset,
                child: _SearchResultsBatchBar(
                  busy: _isSaving,
                  onMove: _handleMoveToShortlist,
                  onExport: _showExportMenu,
                  onRemove: _handleRemoveFromShortlist,
                ),
              ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildHeader() {
    if (_selectionMode) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
        child: SizedBox(
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: _HeaderTextAction(
                  label: ShortlistStrings.selectionCancel,
                  onTap: _exitSelectionMode,
                ),
              ),
              Text(
                ShortlistStrings.selectionCount(_selectedIds.length),
                style: const TextStyle(
                  fontSize: 17,
                  height: 22 / 17,
                  fontWeight: FontWeight.w600,
                  color: DinqTokens.textPrimary,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: _HeaderTextAction(
                  label: _allVisibleSelected
                      ? ShortlistStrings.selectionDeselectAll
                      : ShortlistStrings.selectionSelectAll,
                  onTap: _toggleSelectAll,
                  color: _allVisibleSelected
                      ? const Color(0xFFE24B3C)
                      : const Color(0xFF2563EB),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            _CircleIconButton(
              onTap: widget.onClose,
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: Color(0xFF171717),
              ),
            ),
            const Spacer(),
            _CircleIconButton(
              onTap: _showExportMenu,
              child: DinqSvgIcon(
                assetName: DinqIcons.download,
                size: 18,
                color: const Color(0xFF171717),
              ),
            ),
            const SizedBox(width: 8),
            _CircleIconButton(
              onTap: () => _enterSelectionMode(),
              child: DinqSvgIcon(
                assetName: DinqIcons.listTodo,
                size: 18,
                color: const Color(0xFF171717),
              ),
            ),
            const SizedBox(width: 8),
            _CircleIconButton(
              key: _moreKey,
              onTap: _showMoreMenu,
              child: const Icon(
                Icons.more_horiz,
                size: 20,
                color: Color(0xFF171717),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderTextAction extends StatelessWidget {
  const _HeaderTextAction({
    required this.label,
    required this.onTap,
    this.color = const Color(0xFF2563EB),
  });

  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        minimumSize: const Size(0, 44),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    super.key,
    required this.onTap,
    required this.child,
  });

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(
        side: BorderSide(color: Color(0xFFEAE6E0)),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(child: child),
        ),
      ),
    );
  }
}

/// 对齐 Figma 搜索结果卡 + Shortlist 多选边框/勾选样式。
class _SearchResultCandidateCard extends StatelessWidget {
  const _SearchResultCandidateCard({
    required this.row,
    required this.selectionMode,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    required this.onToggleSelect,
  });

  final Map<String, dynamic> row;
  final bool selectionMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onToggleSelect;

  @override
  Widget build(BuildContext context) {
    final name = row['name']?.toString() ?? '';
    final title = row['title']?.toString() ?? '';
    final company = row['company']?.toString() ?? '';
    final roleLine = [
      title,
      company,
    ].where((s) => s.trim().isNotEmpty).join(' · ');
    final displayMatch = getDisplayMatch(row);
    final confidence = displayMatch.confidence == null
        ? null
        : formatConfidence(displayMatch.confidence);
    final badge = confidence == null ? null : matchBadgeStyle(confidence);
    final avatarColor = nameToAvatarColor(name);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF7FAFF) : DinqTokens.bgCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2F6FED)
                : const Color(0xFFEAE6E0),
            width: isSelected ? 1.5 : 0.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            if (selectionMode) ...[
              ShortlistSelectCheckbox(
                checked: isSelected,
                onChanged: onToggleSelect,
                size: ShortlistCheckboxSize.md,
              ),
              const SizedBox(width: 12),
            ],
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: avatarColor,
                shape: BoxShape.circle,
              ),
              child: Text(
                toInitials(name),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: DinqTokens.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty ? '—' : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 22 / 16,
                      fontWeight: FontWeight.w600,
                      color: DinqTokens.textPrimary,
                    ),
                  ),
                  if (roleLine.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        DinqSvgIcon(
                          assetName: DinqIcons.lucideBriefcase,
                          size: 14,
                          color: const Color(0xFFC9C5BD),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            roleLine,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              height: 18 / 13,
                              color: DinqTokens.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (badge != null && confidence != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badge.background,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: badge.border),
                ),
                child: Text(
                  '$confidence%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: badge.foreground,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SearchResultsBatchBar extends StatelessWidget {
  const _SearchResultsBatchBar({
    required this.busy,
    required this.onMove,
    required this.onExport,
    required this.onRemove,
  });

  final bool busy;
  final VoidCallback onMove;
  final VoidCallback onExport;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
      decoration: BoxDecoration(
        color: DinqTokens.textPrimary,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _BatchButton(
              label: ShortlistStrings.selectionMove,
              icon: Icons.drive_file_move_outlined,
              onTap: busy ? null : onMove,
            ),
          ),
          Expanded(
            child: _BatchButton(
              label: ShortlistStrings.exportLabel,
              icon: Icons.download_outlined,
              onTap: busy ? null : onExport,
            ),
          ),
          Expanded(
            child: _BatchButton(
              label: ShortlistStrings.cardRemove,
              icon: Icons.delete_outline_rounded,
              onTap: busy ? null : onRemove,
              color: const Color(0xFFFF7A66),
            ),
          ),
        ],
      ),
    );
  }
}

class _BatchButton extends StatelessWidget {
  const _BatchButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.color = const Color(0xFFE7E5E1),
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: 52,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
