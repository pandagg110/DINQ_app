import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';

import 'deep_search_results_helpers.dart';
import 'deep_search_results_strings.dart';

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
    this.hasOpenedEnrichThisVisit = false,
    this.onVisibleRowsChange,
    this.onSelectedRowsChange,
  });

  final List<Map<String, dynamic>> candidates;
  final bool isSearching;
  final bool isInterrupted;
  final void Function(Map<String, dynamic> row)? onRowClick;
  final String? selectedRowId;
  final DeepSearchResultsVariant variant;
  final bool showHeader;
  final bool hasOpenedEnrichThisVisit;
  final void Function(List<Map<String, dynamic>> rows)? onVisibleRowsChange;
  final void Function(List<Map<String, dynamic>> rows)? onSelectedRowsChange;

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
  var _dismissedEnrichBanner = false;
  final _selectedRowIds = <String>{};

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncParentCallbacks());
  }

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
    await Share.share(buildSearchResultsCsv(_sortedRows));
  }

  Future<void> _exportMarkdown() async {
    setState(() => _showExportMenu = false);
    await Share.share(buildSearchResultsMarkdown(_sortedRows));
  }

  bool _canToggleExpanded(double collapsedMaxHeight) {
    if (_isRail || _isMobileResults) return false;
    var height = widget.showHeader ? _toolbarHeight : 0;
    if (_activeResultsBannerKind != null) height += _bannerHeight;
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

  String? get _activeResultsBannerKind {
    if (widget.isSearching && !_dismissedSearchingBanner) {
      return 'searching';
    }
    if (!widget.isSearching &&
        !widget.hasOpenedEnrichThisVisit &&
        _rows.isNotEmpty &&
        !_dismissedEnrichBanner) {
      return 'enrich';
    }
    return null;
  }

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
              onToggleSelectedRow: _toggleSelectedRow,
              onRowClick: widget.onRowClick,
            )
          : _TableResultsView(
              rows: sortedRows,
              sortColumn: _sortColumn,
              sortAscending: _sortAscending,
              selectedRowId: widget.selectedRowId,
              selectedRowIds: _selectedRowIds,
              isMobileResults: _isMobileResults,
              onToggleAll: _toggleAllVisibleRows,
              onToggleSelectedRow: _toggleSelectedRow,
              onSort: _toggleSort,
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
    final bannerKind = _activeResultsBannerKind;

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

    if (isEmpty && (_isRail || _isMobileResults)) {
      return const SizedBox.shrink();
    }

    if (isEmpty && widget.isSearching) {
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
          ),
        if (bannerKind != null)
          _ResultsNoticeBanner(
            kind: bannerKind,
            onDismiss: () => setState(() {
              if (bannerKind == 'searching') {
                _dismissedSearchingBanner = true;
              } else {
                _dismissedEnrichBanner = true;
              }
            }),
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
          Expanded(child: resultsContent)
        else
          resultsContent,
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
  const _ResultsNoticeBanner({
    required this.kind,
    required this.onDismiss,
  });

  final String kind;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final text = kind == 'searching'
        ? DeepSearchResultsStrings.searchingNotice
        : DeepSearchResultsStrings.enrichHintNotice;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F6EF),
        border: Border(bottom: BorderSide(color: Color(0xFFE5E3DE))),
      ),
      child: Row(
        children: [
          Icon(
            kind == 'searching' ? Icons.info_outline : Icons.lightbulb_outline,
            size: 16,
            color: const Color(0xFF7A6B52),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
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
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'csv',
                height: 36,
                child: Text(
                  'CSV',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B6962)),
                ),
              ),
              PopupMenuItem(
                value: 'markdown',
                height: 36,
                child: Text(
                  'Markdown',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B6962)),
                ),
              ),
              PopupMenuItem(
                enabled: false,
                height: 36,
                child: Text(
                  'PDF',
                  style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
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
    required this.onToggleSelectedRow,
    this.onRowClick,
  });

  final List<Map<String, dynamic>> rows;
  final String? selectedRowId;
  final Set<String> selectedRowIds;
  final bool showMobileSelection;
  final ValueChanged<String> onToggleSelectedRow;
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
            onToggleChecked: () {
              final rowId = rows[i]['row_id']?.toString();
              if (rowId != null && rowId.isNotEmpty) {
                onToggleSelectedRow(rowId);
              }
            },
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
    required this.onToggleChecked,
    this.onTap,
  });

  final Map<String, dynamic> row;
  final bool selected;
  final bool checked;
  final bool showMobileSelection;
  final VoidCallback onToggleChecked;
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
                _SelectCheckbox(checked: checked, onChanged: onToggleChecked),
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
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(8),
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
                        _DeepSearchSvgIcon(
                          DeepSearchResultsAssets.bookmark,
                          size: 14,
                          color: const Color(0xFF1F1F1F),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          DeepSearchResultsStrings.bookmarkAddShort,
                          style: TextStyle(
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
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectCheckbox extends StatelessWidget {
  const _SelectCheckbox({
    required this.checked,
    required this.onChanged,
  });

  final bool checked;
  final VoidCallback onChanged;

  static const _size = 16.0;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onChanged,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: _size,
        height: _size,
        decoration: BoxDecoration(
          color: checked ? const Color(0xFF171717) : Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: checked ? const Color(0xFF171717) : const Color(0xFFECE9E3),
          ),
        ),
        child: checked
            ? const Icon(Icons.check, size: 12, color: Colors.white)
            : null,
      ),
    );
  }
}

class _TableResultsView extends StatelessWidget {
  const _TableResultsView({
    required this.rows,
    required this.sortColumn,
    required this.sortAscending,
    this.selectedRowId,
    required this.selectedRowIds,
    required this.isMobileResults,
    required this.onToggleAll,
    required this.onToggleSelectedRow,
    required this.onSort,
    this.onRowClick,
  });

  final List<Map<String, dynamic>> rows;
  final DeepSearchResultsSortColumn sortColumn;
  final bool sortAscending;
  final String? selectedRowId;
  final Set<String> selectedRowIds;
  final bool isMobileResults;
  final VoidCallback onToggleAll;
  final ValueChanged<String> onToggleSelectedRow;
  final ValueChanged<DeepSearchResultsSortColumn> onSort;
  final void Function(Map<String, dynamic> row)? onRowClick;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();

    final hasDisplayConfidence =
        rows.any((row) => getDisplayMatch(row).confidence != null);
    final hasDisplayEvidence =
        rows.any((row) => getDisplayMatch(row).evidence.isNotEmpty);
    final hasCompany = rows.any((r) => (r['company']?.toString() ?? '').trim().isNotEmpty);
    final hasTitle = rows.any((r) => (r['title']?.toString() ?? '').trim().isNotEmpty);
    final allSelected = rows.isNotEmpty &&
        rows.every((row) => selectedRowIds.contains(row['row_id']?.toString()));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      primary: false,
      child: DataTable(
        showCheckboxColumn: false,
        headingRowHeight: 40,
        dataRowMinHeight: 44,
        dataRowMaxHeight: 56,
        columnSpacing: 16,
        headingTextStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFF8A8880),
        ),
        dataTextStyle: const TextStyle(fontSize: 12, color: Color(0xFF171717)),
        columns: [
          DataColumn(
            label: _SelectCheckbox(
              checked: allSelected,
              onChanged: onToggleAll,
            ),
          ),
          if (isMobileResults)
            const DataColumn(label: SizedBox(width: 40))
          else
            _SortableDataColumn(
              label: DeepSearchResultsStrings.columnCandidate,
              column: DeepSearchResultsSortColumn.name,
              active: sortColumn == DeepSearchResultsSortColumn.name,
              ascending: sortAscending,
              onSort: onSort,
            ),
          if (isMobileResults)
            _SortableDataColumn(
              label: DeepSearchResultsStrings.columnName,
              column: DeepSearchResultsSortColumn.name,
              active: sortColumn == DeepSearchResultsSortColumn.name,
              ascending: sortAscending,
              onSort: onSort,
            ),
          if (hasDisplayConfidence)
            _SortableDataColumn(
              label: DeepSearchResultsStrings.columnMatch,
              column: DeepSearchResultsSortColumn.confidence,
              active: sortColumn == DeepSearchResultsSortColumn.confidence,
              ascending: sortAscending,
              onSort: onSort,
            ),
          if (hasCompany)
            _SortableDataColumn(
              label: DeepSearchResultsStrings.columnCompany,
              column: DeepSearchResultsSortColumn.company,
              active: sortColumn == DeepSearchResultsSortColumn.company,
              ascending: sortAscending,
              onSort: onSort,
            ),
          if (hasTitle)
            _SortableDataColumn(
              label: DeepSearchResultsStrings.columnTitle,
              column: DeepSearchResultsSortColumn.title,
              active: sortColumn == DeepSearchResultsSortColumn.title,
              ascending: sortAscending,
              onSort: onSort,
            ),
          if (hasDisplayEvidence)
            const DataColumn(label: Text(DeepSearchResultsStrings.columnMatchReason)),
          const DataColumn(label: Text(DeepSearchResultsStrings.columnProfile)),
          const DataColumn(label: Text(DeepSearchResultsStrings.bookmarkAddShort)),
        ],
        rows: [for (var i = 0; i < rows.length; i++) _buildRow(context, rows[i])],
      ),
    );
  }

  DataRow _buildRow(BuildContext context, Map<String, dynamic> row) {
    final rowId = row['row_id']?.toString() ?? '';
    final selected = selectedRowId != null && selectedRowId == rowId;
    final checked = selectedRowIds.contains(rowId);
    final verified = isResultVerified(row);
    final displayMatch = getDisplayMatch(row);
    final confidence = displayMatch.confidence == null
        ? null
        : formatConfidence(displayMatch.confidence);
    final badge = confidence == null ? null : matchBadgeStyle(confidence);
    final rowTap = onRowClick == null ? null : () => onRowClick!(row);
    final nameColor =
        verified ? const Color(0xFF171717) : const Color(0xFF8A8880);
    final mutedColor =
        verified ? const Color(0xFF6B6962) : const Color(0xFF8A8880);
    final profileUrl = row['profile_url']?.toString() ?? '';
    final name = row['name']?.toString() ?? '';

    Widget cell(Widget child, {VoidCallback? onTap}) =>
        Opacity(opacity: verified ? 1 : 0.55, child: child);

    return DataRow(
      color: WidgetStateProperty.resolveWith((states) {
        if (selected) return const Color(0xFFF9F8F5);
        if (states.contains(WidgetState.hovered)) {
          return verified ? const Color(0xFFFDFCF9) : const Color(0xFFFBFAF7);
        }
        return Colors.white;
      }),
      cells: [
        DataCell(
          cell(
            _SelectCheckbox(
              checked: checked,
              onChanged: () => onToggleSelectedRow(rowId),
            ),
          ),
        ),
        DataCell(
          cell(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: nameToAvatarColor(name),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    toInitials(name),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1F1F1F),
                    ),
                  ),
                ),
                if (!isMobileResults) ...[
                  const SizedBox(width: 8),
                  Text(
                    name.isEmpty ? '—' : name,
                    style: TextStyle(fontWeight: FontWeight.w500, color: nameColor),
                  ),
                ],
              ],
            ),
          ),
          onTap: rowTap,
        ),
        if (isMobileResults)
          DataCell(
            cell(
              Text(
                name.isEmpty ? '—' : name,
                style: TextStyle(fontWeight: FontWeight.w500, color: nameColor),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            onTap: rowTap,
          ),
        if (confidence != null && badge != null)
          DataCell(
            cell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badge.background,
                  borderRadius: BorderRadius.circular(999),
                  border: Border(top: BorderSide(color: badge.border)),
                ),
                child: Text(
                  '$confidence%',
                  style: TextStyle(
                    color: badge.foreground,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            onTap: rowTap,
          )
        else if (rows.any((r) => getDisplayMatch(r).confidence != null))
          DataCell(cell(const SizedBox.shrink()), onTap: rowTap),
        if (rows.any((r) => (r['company']?.toString() ?? '').trim().isNotEmpty))
          DataCell(
            cell(Text(row['company']?.toString() ?? '—', style: TextStyle(color: mutedColor))),
            onTap: rowTap,
          ),
        if (rows.any((r) => (r['title']?.toString() ?? '').trim().isNotEmpty))
          DataCell(
            cell(Text(row['title']?.toString() ?? '—', style: TextStyle(color: mutedColor))),
            onTap: rowTap,
          ),
        if (rows.any((row) => getDisplayMatch(row).evidence.isNotEmpty))
          DataCell(
            cell(
              SizedBox(
                width: 180,
                child: Text(
                  displayMatch.evidence.isEmpty
                      ? (confidence == null ? '' : '—')
                      : displayMatch.evidence,
                  style: TextStyle(color: mutedColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            onTap: rowTap,
          ),
        DataCell(
          cell(
            profileUrl.isEmpty
                ? const Text('—', style: TextStyle(color: Color(0xFFD5D3CE)))
                : Text(
                    profileUrl.replaceFirst(RegExp(r'^https?://(www\.)?'), ''),
                    style: TextStyle(color: mutedColor),
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
          onTap: rowTap,
        ),
        DataCell(
          cell(
            IconButton(
              onPressed: () {},
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              icon: _DeepSearchSvgIcon(
                DeepSearchResultsAssets.bookmark,
                size: 16,
                color: const Color(0xFFB5B3AE),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SortableDataColumn extends DataColumn {
  _SortableDataColumn({
    required String label,
    required DeepSearchResultsSortColumn column,
    required bool active,
    required bool ascending,
    required ValueChanged<DeepSearchResultsSortColumn> onSort,
  }) : super(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label),
              const SizedBox(width: 4),
              Icon(
                active
                    ? (ascending
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down)
                    : Icons.swap_vert,
                size: 14,
                color: active
                    ? const Color(0xFF8A8880)
                    : const Color(0xFFD5D3CE),
              ),
            ],
          ),
          onSort: (index, ascending) => onSort(column),
        );
}
