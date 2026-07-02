import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../services/search_service.dart';
import '../../../services/shortlist_service.dart';
import '../../../stores/user_store.dart';
import '../enrich/shortlist_folder_modal.dart';
import 'deep_search_models.dart';
import 'deep_search_results_helpers.dart';
import 'deep_search_results_strings.dart';
import 'deep_search_results_table.dart';
import 'search_activity_line.dart';
import 'trace_status.dart';

enum DeepSearchResultsVariant { inline, rail, mobile }

/// 与 TSX `DeepSearchResults` 对齐。
class DeepSearchResults extends StatefulWidget {
  const DeepSearchResults({
    super.key,
    required this.candidates,
    required this.isSearching,
    this.isInterrupted = false,
    this.onRowClick,
    this.selectedRowId,
    this.variant = DeepSearchResultsVariant.inline,
    this.showHeader = true,
    this.onVisibleRowsChange,
    this.onSelectedRowsChange,
    this.sourceGroupsByRowId,
    this.pendingSourceGroups,
    this.roundStatus = DeepSearchRoundStatus.idle,
    this.contentBlocks = const [],
    this.subAgents = const {},
    this.sessionId,
    this.sseEventsId,
  });

  final List<Map<String, dynamic>> candidates;
  final bool isSearching;
  final bool isInterrupted;
  final void Function(Map<String, dynamic> row)? onRowClick;
  final String? selectedRowId;
  final DeepSearchResultsVariant variant;
  final bool showHeader;
  final void Function(List<Map<String, dynamic>> rows)? onVisibleRowsChange;
  final void Function(List<Map<String, dynamic>> rows)? onSelectedRowsChange;
  final Map<String, ResultSourceGroup>? sourceGroupsByRowId;
  final List<ResultSourceGroup>? pendingSourceGroups;
  final DeepSearchRoundStatus roundStatus;
  final List<MessagePart> contentBlocks;
  final Map<String, SubAgentInfo> subAgents;
  final String? sessionId;
  final String? sseEventsId;

  @override
  State<DeepSearchResults> createState() => _DeepSearchResultsState();
}

class _DeepSearchResultsState extends State<DeepSearchResults> {
  static const _scrollSlack = 16.0;
  static const _toolbarHeight = 41.0;
  static const _bannerHeight = 48.0;
  static const _interruptedBannerHeight = 45.0;
  static const _cardRowHeight = 72.0;

  late var _viewModeCard = widget.variant == DeepSearchResultsVariant.inline;
  var _sortColumn = DeepSearchResultsSortColumn.confidence;
  var _sortAscending = false;
  var _showExportMenu = false;
  var _copiedResults = false;
  var _isExpanded = true;
  var _isOverflowing = false;
  var _dismissedSearchingBanner = false;
  final _selectedRowIds = <String>{};
  final _shortlistService = ShortlistService();
  final _searchService = SearchService();
  final _favoriteMap = <String, String>{};
  var _isExportingPdf = false;
  Map<String, dynamic>? _pendingBookmarkRow;

  bool get _isRail => widget.variant == DeepSearchResultsVariant.rail;
  bool get _isMobileResults => widget.variant == DeepSearchResultsVariant.mobile;

  List<Map<String, dynamic>> get _rows =>
      List<Map<String, dynamic>>.from(widget.candidates);

  List<Map<String, dynamic>> get _sortedRows => sortCandidateRows(
        _rows,
        column: _sortColumn,
        ascending: _sortAscending,
      );

  List<Map<String, dynamic>> get _selectedRows => _sortedRows
      .where((row) => _selectedRowIds.contains(row['row_id']?.toString()))
      .toList();

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncParentCallbacks());
  }

  Future<void> _loadFavorites() async {
    try {
      final items = await _shortlistService.listFavorites();
      if (!mounted) return;
      setState(() {
        _favoriteMap.clear();
        for (final item in items) {
          final rowId = item.field['row_id']?.toString();
          if (rowId != null && rowId.isNotEmpty) {
            _favoriteMap[rowId] = item.id;
          }
        }
      });
    } catch (_) {}
  }

  void _showToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleBookmarkClick(Map<String, dynamic> row) async {
    final rowId = row['row_id']?.toString() ?? '';
    if (rowId.isEmpty) return;
    final favoriteId = _favoriteMap[rowId];
    if (favoriteId != null) {
      try {
        await _shortlistService.removeFavorite(favoriteId);
        if (!mounted) return;
        setState(() => _favoriteMap.remove(rowId));
        _showToast(DeepSearchResultsStrings.toastRemovedFromShortlist);
      } catch (_) {
        _showToast(DeepSearchResultsStrings.exportFailed);
      }
      return;
    }
    _pendingBookmarkRow = row;
    final projectId = await showShortlistFolderModal(context);
    if (projectId == null || !mounted) {
      _pendingBookmarkRow = null;
      return;
    }
    await _saveBookmarkToFolder(projectId);
  }

  Future<void> _saveBookmarkToFolder(String projectId) async {
    final row = _pendingBookmarkRow;
    _pendingBookmarkRow = null;
    if (row == null) return;
    final payload = buildFavoritePayload(row);
    try {
      final item = await _shortlistService.createFavorite(
        projectId: projectId,
        title: payload['title']?.toString() ?? '',
        field: Map<String, dynamic>.from(
          payload['field'] as Map? ?? const {},
        ),
      );
      final rowId = row['row_id']?.toString();
      if (!mounted) return;
      if (rowId != null && rowId.isNotEmpty) {
        setState(() => _favoriteMap[rowId] = item.id);
      }
      _showToast(DeepSearchResultsStrings.toastAddedToFolder);
    } catch (_) {
      if (mounted) _showToast(DeepSearchResultsStrings.exportFailed);
    }
  }

  bool get _pdfExportDisabled =>
      _isExportingPdf ||
      widget.sseEventsId == null ||
      widget.sseEventsId!.isEmpty ||
      widget.isSearching;

  Future<void> _handleExportPdf() async {
    if (_isExportingPdf) return;
    if (widget.isSearching) {
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
    setState(() {
      _isExportingPdf = true;
      _showExportMenu = false;
    });
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
      );
    } catch (_) {
      if (mounted) _showToast(DeepSearchResultsStrings.exportFailed);
    } finally {
      if (mounted) setState(() => _isExportingPdf = false);
    }
  }

  LatestTraceStatus? get _activityStatus => resolveSearchActivityStatus(
        roundStatus: widget.roundStatus,
        contentBlocks: widget.contentBlocks,
        subAgents: widget.subAgents,
      );

  bool get _showActivityLine =>
      widget.isSearching || _activityStatus != null;

  @override
  void didUpdateWidget(covariant DeepSearchResults oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.candidates != widget.candidates) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncParentCallbacks());
    }
  }

  void _syncParentCallbacks() {
    widget.onVisibleRowsChange?.call(_sortedRows);
    widget.onSelectedRowsChange?.call(_selectedRows);
  }
  void _toggleSort(DeepSearchResultsSortColumn column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = column != DeepSearchResultsSortColumn.confidence;
      }
      _syncParentCallbacks();
    });
  }

  void _toggleSelectedRow(String rowId) {
    setState(() {
      if (_selectedRowIds.contains(rowId)) {
        _selectedRowIds.remove(rowId);
      } else {
        _selectedRowIds.add(rowId);
      }
      _syncParentCallbacks();
    });
  }

  void _toggleAllVisibleRows() {
    setState(() {
      final visibleIds =
          _sortedRows.map((r) => r['row_id']?.toString() ?? '').where((id) => id.isNotEmpty);
      final allSelected = _sortedRows.isNotEmpty &&
          _sortedRows.every(
            (row) => _selectedRowIds.contains(row['row_id']?.toString()),
          );
      if (allSelected) {
        _selectedRowIds.removeAll(visibleIds);
      } else {
        _selectedRowIds.addAll(visibleIds);
      }
      _syncParentCallbacks();
    });
  }

  Future<void> _copyResults() async {
    await Clipboard.setData(
      ClipboardData(text: buildSearchResultsMarkdown(_sortedRows)),
    );
    setState(() => _copiedResults = true);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _copiedResults = false);
    });
  }

  Future<void> _exportCsv() async {
    setState(() => _showExportMenu = false);
    await _shareAsFile(buildSearchResultsCsv(_sortedRows), 'csv');
  }

  Future<void> _exportMarkdown() async {
    setState(() => _showExportMenu = false);
    await _shareAsFile(buildSearchResultsMarkdown(_sortedRows), 'md');
  }

  /// 导出必须是文件而不是纯文本分享，否则收不到 .csv/.md 文件（导出"不能正常使用"）。
  Future<void> _shareAsFile(String content, String ext) async {
    try {
      final date = DateTime.now().toIso8601String().substring(0, 10);
      final filename = 'search-results-$date.$ext';
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsString(content);
      await Share.shareXFiles([XFile(file.path)], subject: filename);
    } catch (_) {
      if (mounted) _showToast(DeepSearchResultsStrings.exportFailed);
    }
  }

  bool _canToggleExpanded(double collapsedMaxHeight) {
    if (_isRail || _isMobileResults) return false;
    var height = widget.showHeader ? _toolbarHeight : 0;
    if (_showSearchingBanner) height += _bannerHeight;
    if (widget.isInterrupted) height += _interruptedBannerHeight;
    final rowCount = _sortedRows.length;
    if (rowCount > 0) {
      height += rowCount * _cardRowHeight;
      if (rowCount > 1) height += rowCount - 1;
    }
    return height > collapsedMaxHeight + _scrollSlack;
  }

  double _collapsedMaxHeight(BuildContext context) {
    return math.max(420.0, MediaQuery.sizeOf(context).height * 0.7);
  }

  bool get _showSearchingBanner =>
      widget.isSearching && !_dismissedSearchingBanner;

  Widget _buildResultsContent({
    required List<Map<String, dynamic>> sortedRows,
  }) {
    final contentColor =
        _isRail || _isMobileResults ? Colors.white : DeepSearchResultsColors.scrollBg;
    return ColoredBox(
      color: contentColor,
      child: _viewModeCard
          ? _CardResultsList(
              rows: sortedRows,
              selectedRowId: widget.selectedRowId,
              selectedRowIds: _selectedRowIds,
              showMobileSelection: _isMobileResults,
              favoriteMap: _favoriteMap,
              onToggleSelectedRow: _toggleSelectedRow,
              onBookmarkTap: _handleBookmarkClick,
              onRowClick: widget.onRowClick,
            )
          : DeepSearchResultsTable(
              rows: sortedRows,
              isSearching: widget.isSearching,
              isMobileResults: _isMobileResults,
              isRail: _isRail,
              sortColumn: _sortColumn,
              sortAscending: _sortAscending,
              selectedRowId: widget.selectedRowId,
              selectedRowIds: _selectedRowIds,
              favoriteMap: _favoriteMap,
              sourceGroupsByRowId: widget.sourceGroupsByRowId,
              pendingSourceGroups: widget.pendingSourceGroups,
              expandVertically: _isRail || _isMobileResults || !_isExpanded,
              onToggleAll: _toggleAllVisibleRows,
              onToggleSelectedRow: _toggleSelectedRow,
              onSort: _toggleSort,
              onBookmarkTap: _handleBookmarkClick,
              onRowClick: widget.onRowClick,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sortedRows = _sortedRows;
    final collapsedMaxHeight = _collapsedMaxHeight(context);
    final canToggleExpanded = _canToggleExpanded(collapsedMaxHeight);
    final isEmpty = _rows.isEmpty;
    final bannerKind = _showSearchingBanner;

    if (isEmpty && !widget.isSearching && !_isRail && !_isMobileResults) {
      return Container(
        decoration: BoxDecoration(
          color: DeepSearchResultsColors.pageBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DeepSearchResultsColors.border),
        ),
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Center(
          child: Text(
            DeepSearchResultsStrings.empty,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Color(0xFFA5A39E)),
          ),
        ),
      );
    }

    if (isEmpty && (_isRail || _isMobileResults) && !widget.isSearching) {
      return const SizedBox.shrink();
    }

    if (isEmpty && widget.isSearching && !_isRail && !_isMobileResults) {
      return const SizedBox.shrink();
    }

    final resultsContent = _buildResultsContent(sortedRows: sortedRows);

    final panelBody = Column(
      mainAxisSize: _isExpanded ? MainAxisSize.min : MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showHeader)
          _ResultsToolbar(
            viewModeCard: _viewModeCard,
            copiedResults: _copiedResults,
            showExportMenu: _showExportMenu,
            hasRows: _rows.isNotEmpty,
            onViewModeCard: () => setState(() => _viewModeCard = true),
            onViewModeTable: () => setState(() => _viewModeCard = false),
            onToggleExportMenu: () =>
                setState(() => _showExportMenu = !_showExportMenu),
            onDismissExportMenu: () => setState(() => _showExportMenu = false),
            onCopy: _copyResults,
            onExportCsv: _exportCsv,
            onExportMarkdown: _exportMarkdown,
            onExportPdf: _handleExportPdf,
            isExportingPdf: _isExportingPdf,
            pdfExportDisabled: _pdfExportDisabled,
          ),
        if (bannerKind)
          _ResultsNoticeBanner(
            onDismiss: () => setState(() => _dismissedSearchingBanner = true),
          ),
        if (widget.isInterrupted)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFFFFBEB),
              border: Border(bottom: BorderSide(color: Color(0xFFFEF3C7))),
            ),
            child: Text(
              DeepSearchResultsStrings.interrupted,
              style: const TextStyle(fontSize: 14, color: Color(0xFFB45309)),
            ),
          ),
        if (!_isExpanded && !_isRail && !_isMobileResults)
          Expanded(
            child: _ResultsScrollArea(
              onOverflowChanged: (value) {
                if (value != _isOverflowing && mounted) {
                  setState(() => _isOverflowing = value);
                }
              },
              child: resultsContent,
            ),
          )
        else if (_isRail || _isMobileResults)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: resultsContent),
                if (_showActivityLine)
                  SearchActivityLine(
                    status: _activityStatus,
                    isSearching: widget.isSearching,
                  ),
              ],
            ),
          )
        else
          resultsContent,
        if (_showActivityLine && !_isRail && !_isMobileResults)
          SearchActivityLine(
            status: _activityStatus,
            isSearching: widget.isSearching,
          ),
        if (canToggleExpanded)
          Material(
            color: DeepSearchResultsColors.toolbarBg,
            child: InkWell(
              onTap: () => setState(() {
                _isExpanded = !_isExpanded;
                if (_isExpanded) _isOverflowing = false;
              }),
              hoverColor: const Color(0xFFF1F0EA),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: DeepSearchResultsColors.border),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isExpanded
                          ? DeepSearchResultsStrings.showLess
                          : DeepSearchResultsStrings.showMore,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8A8880),
                      ),
                    ),
                    if (_isOverflowing || _isExpanded) ...[
                      const SizedBox(width: 6),
                      Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 12,
                        color: const Color(0xFF8A8880),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );

    if (_isRail || _isMobileResults) {
      return ColoredBox(
        color: Colors.white,
        child: panelBody,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: DeepSearchResultsColors.pageBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DeepSearchResultsColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F786E5A),
            blurRadius: 40,
            offset: Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: !_isExpanded
          ? ConstrainedBox(
              constraints: BoxConstraints(maxHeight: collapsedMaxHeight),
              child: panelBody,
            )
          : panelBody,
    );
  }
}

class _DeepSearchSvgIcon extends StatelessWidget {
  const _DeepSearchSvgIcon(
    this.asset, {
    this.size = 16,
    this.color = const Color(0xFF171717),
  });

  final String asset;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}

class _ResultsScrollArea extends StatefulWidget {
  const _ResultsScrollArea({
    required this.child,
    this.onOverflowChanged,
  });

  final Widget child;
  final ValueChanged<bool>? onOverflowChanged;

  @override
  State<_ResultsScrollArea> createState() => _ResultsScrollAreaState();
}

class _ResultsScrollAreaState extends State<_ResultsScrollArea> {
  final _controller = ScrollController();
  var _showGradient = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_syncGradient);
  }

  @override
  void didUpdateWidget(covariant _ResultsScrollArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncGradient());
  }

  void _syncGradient() {
    if (!_controller.hasClients) return;
    const slack = 16.0;
    final position = _controller.position;
    final overflowing =
        position.maxScrollExtent > position.viewportDimension + slack;
    final show = position.maxScrollExtent > 0 &&
        position.pixels < position.maxScrollExtent - 4;
    widget.onOverflowChanged?.call(overflowing);
    if (show != _showGradient && mounted) {
      setState(() => _showGradient = show);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_syncGradient);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          controller: _controller,
          primary: false,
          child: widget.child,
        ),
        if (_showGradient)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 48,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      DeepSearchResultsColors.scrollBg.withValues(alpha: 0),
                      DeepSearchResultsColors.scrollBg.withValues(alpha: 0.6),
                      DeepSearchResultsColors.scrollBg,
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ResultsNoticeBanner extends StatelessWidget {
  const _ResultsNoticeBanner({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F6EF),
        border: Border(bottom: BorderSide(color: Color(0xFFE5E3DE))),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            size: 16,
            color: Color(0xFF7A6B52),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              DeepSearchResultsStrings.searchingNotice,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF7A6B52),
              ),
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            tooltip: DeepSearchResultsStrings.dismissNotice,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            icon: const Icon(Icons.close, size: 14, color: Color(0xFF9B8D72)),
          ),
        ],
      ),
    );
  }
}

class _ResultsToolbar extends StatelessWidget {
  const _ResultsToolbar({
    required this.viewModeCard,
    required this.copiedResults,
    required this.showExportMenu,
    required this.hasRows,
    required this.onViewModeCard,
    required this.onViewModeTable,
    required this.onToggleExportMenu,
    required this.onDismissExportMenu,
    required this.onCopy,
    required this.onExportCsv,
    required this.onExportMarkdown,
    required this.onExportPdf,
    required this.isExportingPdf,
    required this.pdfExportDisabled,
  });

  final bool viewModeCard;
  final bool copiedResults;
  final bool showExportMenu;
  final bool hasRows;
  final VoidCallback onViewModeCard;
  final VoidCallback onViewModeTable;
  final VoidCallback onToggleExportMenu;
  final VoidCallback onDismissExportMenu;
  final VoidCallback onCopy;
  final VoidCallback onExportCsv;
  final VoidCallback onExportMarkdown;
  final VoidCallback onExportPdf;
  final bool isExportingPdf;
  final bool pdfExportDisabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(
        color: DeepSearchResultsColors.toolbarBg,
        border: Border(bottom: BorderSide(color: DeepSearchResultsColors.border)),
      ),
      child: Row(
        children: [
          _ToolbarIconButton(
            asset: DeepSearchResultsAssets.gridView,
            selected: viewModeCard,
            tooltip: DeepSearchResultsStrings.viewToggleCard,
            onTap: onViewModeCard,
          ),
          const SizedBox(width: 4),
          _ToolbarIconButton(
            asset: DeepSearchResultsAssets.listView,
            selected: !viewModeCard,
            tooltip: DeepSearchResultsStrings.viewToggleTable,
            onTap: onViewModeTable,
          ),
          const Spacer(),
          if (hasRows) ...[
            PopupMenuButton<String>(
            onOpened: onToggleExportMenu,
            onCanceled: onDismissExportMenu,
            offset: const Offset(0, 36),
            color: Colors.white,
            elevation: 4,
            shadowColor: const Color(0x1A786E5A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Color(0xFFEAE8E3)),
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'csv',
                height: 36,
                child: Text(
                  'CSV',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B6962)),
                ),
              ),
              const PopupMenuItem(
                value: 'markdown',
                height: 36,
                child: Text(
                  'Markdown',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B6962)),
                ),
              ),
              PopupMenuItem(
                value: 'pdf',
                enabled: !pdfExportDisabled,
                height: 36,
                child: Text(
                  isExportingPdf
                      ? DeepSearchResultsStrings.exportExporting
                      : 'PDF',
                  style: TextStyle(
                    fontSize: 12,
                    color: pdfExportDisabled
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF6B6962),
                  ),
                ),
              ),
            ],
            onSelected: (value) {
              onDismissExportMenu();
              switch (value) {
                case 'csv':
                  onExportCsv();
                case 'markdown':
                  onExportMarkdown();
                case 'pdf':
                  onExportPdf();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: showExportMenu
                    ? const Color(0xFFF3F1EC)
                    : Colors.transparent,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _DeepSearchSvgIcon(
                    DeepSearchResultsAssets.download,
                    size: 12,
                    color: const Color(0xFF171717),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    DeepSearchResultsStrings.exportButton,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF171717),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onCopy,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(6),
                child: copiedResults
                    ? const Icon(Icons.check, size: 14, color: Color(0xFF171717))
                    : _DeepSearchSvgIcon(
                        DeepSearchResultsAssets.copy,
                        size: 14,
                        color: const Color(0xFF171717),
                      ),
              ),
            ),
          ),
          ],
        ],
      ),
    );
  }
}

class _ToolbarIconButton extends StatelessWidget {
  const _ToolbarIconButton({
    required this.asset,
    required this.selected,
    required this.tooltip,
    required this.onTap,
  });

  final String asset;
  final bool selected;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color =
        selected ? const Color(0xFF171717) : const Color(0xFFB5B3AE);
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEFEFE9) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: _DeepSearchSvgIcon(asset, size: 16, color: color),
        ),
      ),
    );
  }
}

class _CardResultsList extends StatelessWidget {
  const _CardResultsList({
    required this.rows,
    this.selectedRowId,
    required this.selectedRowIds,
    required this.showMobileSelection,
    required this.favoriteMap,
    required this.onToggleSelectedRow,
    required this.onBookmarkTap,
    this.onRowClick,
  });

  final List<Map<String, dynamic>> rows;
  final String? selectedRowId;
  final Set<String> selectedRowIds;
  final bool showMobileSelection;
  final Map<String, String> favoriteMap;
  final ValueChanged<String> onToggleSelectedRow;
  final ValueChanged<Map<String, dynamic>> onBookmarkTap;
  final void Function(Map<String, dynamic> row)? onRowClick;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0)
            _CardDivider(
              row: rows[i],
              prevRow: rows[i - 1],
              selectedRowId: selectedRowId,
              selectedRowIds: selectedRowIds,
            ),
          _CandidateResultCard(
            row: rows[i],
            selected: selectedRowId != null &&
                selectedRowId == rows[i]['row_id']?.toString(),
            checked: selectedRowIds.contains(rows[i]['row_id']?.toString()),
            showMobileSelection: showMobileSelection,
            isBookmarked: favoriteMap.containsKey(rows[i]['row_id']?.toString()),
            onToggleChecked: () {
              final rowId = rows[i]['row_id']?.toString();
              if (rowId != null && rowId.isNotEmpty) {
                onToggleSelectedRow(rowId);
              }
            },
            onBookmarkTap: () => onBookmarkTap(rows[i]),
            onTap: onRowClick == null ? null : () => onRowClick!(rows[i]),
          ),
        ],
      ],
    );
  }
}

class _CardDivider extends StatelessWidget {
  const _CardDivider({
    required this.row,
    required this.prevRow,
    required this.selectedRowId,
    required this.selectedRowIds,
  });

  final Map<String, dynamic> row;
  final Map<String, dynamic> prevRow;
  final String? selectedRowId;
  final Set<String> selectedRowIds;

  @override
  Widget build(BuildContext context) {
    final rowId = row['row_id']?.toString();
    final prevId = prevRow['row_id']?.toString();
    final fullWidth = selectedRowId != null &&
            (selectedRowId == rowId || selectedRowId == prevId) ||
        selectedRowIds.contains(rowId) ||
        selectedRowIds.contains(prevId);
    return Divider(
      height: 1,
      thickness: 1,
      indent: fullWidth ? 0 : 20,
      endIndent: fullWidth ? 0 : 20,
      color: DeepSearchResultsColors.divider,
    );
  }
}

class _CandidateResultCard extends StatelessWidget {
  const _CandidateResultCard({
    required this.row,
    required this.selected,
    required this.checked,
    required this.showMobileSelection,
    required this.isBookmarked,
    required this.onToggleChecked,
    required this.onBookmarkTap,
    this.onTap,
  });

  final Map<String, dynamic> row;
  final bool selected;
  final bool checked;
  final bool showMobileSelection;
  final bool isBookmarked;
  final VoidCallback onToggleChecked;
  final VoidCallback onBookmarkTap;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final name = row['name']?.toString() ?? '';
    final title = row['title']?.toString() ?? '';
    final company = row['company']?.toString() ?? '';
    final displayMatch = getDisplayMatch(row);
    final confidence = displayMatch.confidence == null
        ? null
        : formatConfidence(displayMatch.confidence);
    final badge = confidence == null ? null : matchBadgeStyle(confidence);
    final evidence = displayMatch.evidence;
    final subtitle =
        [title, company].where((s) => s.trim().isNotEmpty).join(' · ');
    final showMatchRow = confidence != null || evidence.isNotEmpty;

    return Material(
      color: selected
          ? const Color(0xFFF0EFE9)
          : checked
              ? const Color(0xFFF8F7F4)
              : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: const Color(0xFFF5F4EF),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (showMobileSelection) ...[
                Align(
                  widthFactor: 1,
                  heightFactor: 1,
                  child: DeepSearchSelectCheckbox(
                    checked: checked,
                    onChanged: onToggleChecked,
                    size: DeepSearchSelectCheckboxSize.md,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: nameToAvatarColor(name),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  toInitials(name),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1F1F1F),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Flexible(
                          fit: FlexFit.loose,
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF171717),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              subtitle,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w300,
                                color: Color(0xFF6B6B6B),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (showMatchRow) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (badge != null && confidence != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: badge.background,
                                borderRadius: BorderRadius.circular(999),
                                border: Border(
                                  top: BorderSide(color: badge.border),
                                ),
                              ),
                              child: Text(
                                '$confidence%',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: badge.foreground,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (evidence.isNotEmpty)
                            Expanded(
                              child: Text(
                                evidence,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B6962),
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
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onBookmarkTap,
                behavior: HitTestBehavior.opaque,
                child: Tooltip(
                  message: isBookmarked
                      ? DeepSearchResultsStrings.bookmarkRemove
                      : DeepSearchResultsStrings.bookmarkAdd,
                  child: Material(
                    color: isBookmarked
                        ? const Color(0xFFF3F1EC)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: onBookmarkTap,
                      borderRadius: BorderRadius.circular(8),
                      hoverColor: isBookmarked
                          ? const Color(0xFFF3F1EC)
                          : const Color(0xFFF9F9F7),
                      child: Container(
                        width: 68,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFEAEAEA)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            isBookmarked
                                ? const Icon(
                                    Icons.check,
                                    size: 14,
                                    color: Color(0xFF1F1F1F),
                                  )
                                : SvgPicture.asset(
                                    DeepSearchResultsAssets.bookmark,
                                    width: 14,
                                    height: 14,
                                    colorFilter: const ColorFilter.mode(
                                      Color(0xFF1F1F1F),
                                      BlendMode.srcIn,
                                    ),
                                  ),
                            const SizedBox(width: 4),
                            Text(
                              isBookmarked
                                  ? DeepSearchResultsStrings.bookmarkAdded
                                  : DeepSearchResultsStrings.bookmarkAddShort,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1F1F1F),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
