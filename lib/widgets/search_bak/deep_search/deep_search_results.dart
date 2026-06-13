import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';

import 'deep_search_results_helpers.dart';

/// 与 TSX `DeepSearchResults` 对齐（移动端默认 Card 视图）。
class DeepSearchResults extends StatefulWidget {
  const DeepSearchResults({
    super.key,
    required this.candidates,
    required this.isSearching,
    this.isInterrupted = false,
    this.onRowClick,
    this.selectedRowId,
  });

  final List<Map<String, dynamic>> candidates;
  final bool isSearching;
  final bool isInterrupted;
  final void Function(Map<String, dynamic> row)? onRowClick;
  final String? selectedRowId;

  @override
  State<DeepSearchResults> createState() => _DeepSearchResultsState();
}

class _DeepSearchResultsState extends State<DeepSearchResults> {
  static const _scrollSlack = 16.0;
  static const _toolbarHeight = 41.0;
  static const _filterBarHeight = 44.0;
  static const _interruptedBannerHeight = 45.0;
  static const _cardRowHeight = 72.0;

  var _viewModeCard = true;
  var _sortColumn = DeepSearchResultsSortColumn.confidence;
  var _sortAscending = false;
  final _activeSourceFilters = <String>{};
  var _filtersExpanded = false;
  var _showExportMenu = false;
  var _copiedResults = false;
  var _isExpanded = true;
  var _isOverflowing = false;

  List<Map<String, dynamic>> get _rows =>
      dedupeCandidateRows(List<Map<String, dynamic>>.from(widget.candidates));

  List<String> get _rowSourceLabels {
    return _rows.map(getRowSourceLabel).toSet().toList()..sort();
  }

  List<Map<String, dynamic>> get _sortedFilteredRows {
    var rows = _rows;
    if (_activeSourceFilters.isNotEmpty) {
      rows = rows
          .where((r) => _activeSourceFilters.contains(getRowSourceLabel(r)))
          .toList();
    }
    return sortCandidateRows(
      rows,
      column: _sortColumn,
      ascending: _sortAscending,
    );
  }

  void _toggleSort(DeepSearchResultsSortColumn column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = column != DeepSearchResultsSortColumn.confidence;
      }
    });
  }

  void _toggleSourceFilter(String label) {
    setState(() {
      if (_activeSourceFilters.contains(label)) {
        _activeSourceFilters.remove(label);
      } else {
        _activeSourceFilters.add(label);
      }
    });
  }

  Future<void> _copyResults() async {
    await Clipboard.setData(
      ClipboardData(text: buildSearchResultsMarkdown(_sortedFilteredRows)),
    );
    setState(() => _copiedResults = true);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _copiedResults = false);
    });
  }

  Future<void> _exportCsv() async {
    setState(() => _showExportMenu = false);
    await Share.share(buildSearchResultsCsv(_sortedFilteredRows));
  }

  Future<void> _exportMarkdown() async {
    setState(() => _showExportMenu = false);
    await Share.share(buildSearchResultsMarkdown(_sortedFilteredRows));
  }

  bool _canToggleExpanded(double collapsedMaxHeight) {
    var height = _toolbarHeight;
    if (_rowSourceLabels.length > 1) height += _filterBarHeight;
    if (widget.isInterrupted) height += _interruptedBannerHeight;
    final rowCount = _sortedFilteredRows.length;
    if (rowCount > 0) {
      height += rowCount * _cardRowHeight;
      if (rowCount > 1) height += rowCount - 1;
    }
    return height > collapsedMaxHeight + _scrollSlack;
  }

  double _collapsedMaxHeight(BuildContext context) {
    // App 端有底部 Tab，可用高度比 Web 小，折叠态用 50vh（Web 为 70vh）。
    return math.max(420.0, MediaQuery.sizeOf(context).height * 0.5);
  }

  Widget _buildResultsContent({
    required List<Map<String, dynamic>> sortedRows,
    required bool isFiltered,
  }) {
    return ColoredBox(
      color: DeepSearchResultsColors.scrollBg,
      child: _viewModeCard
          ? _CardResultsList(
              rows: sortedRows,
              allRowsCount: _rows.length,
              isFiltered: isFiltered,
              selectedRowId: widget.selectedRowId,
              onRowClick: widget.onRowClick,
            )
          : _TableResultsView(
              rows: sortedRows,
              allRowsCount: _rows.length,
              isFiltered: isFiltered,
              sortColumn: _sortColumn,
              sortAscending: _sortAscending,
              selectedRowId: widget.selectedRowId,
              onSort: _toggleSort,
              onRowClick: widget.onRowClick,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_rows.isEmpty) return const SizedBox.shrink();

    final sortedRows = _sortedFilteredRows;
    final isFiltered = _activeSourceFilters.isNotEmpty;
    final sourceLabels = _rowSourceLabels;
    final collapsedMaxHeight = _collapsedMaxHeight(context);
    final canToggleExpanded = _canToggleExpanded(collapsedMaxHeight);

    final resultsContent = _buildResultsContent(
      sortedRows: sortedRows,
      isFiltered: isFiltered,
    );

    final panelBody = Column(
      mainAxisSize: _isExpanded ? MainAxisSize.min : MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ResultsToolbar(
          viewModeCard: _viewModeCard,
          copiedResults: _copiedResults,
          showExportMenu: _showExportMenu,
          onViewModeCard: () => setState(() => _viewModeCard = true),
          onViewModeTable: () => setState(() => _viewModeCard = false),
          onToggleExportMenu: () =>
              setState(() => _showExportMenu = !_showExportMenu),
          onDismissExportMenu: () => setState(() => _showExportMenu = false),
          onCopy: _copyResults,
          onExportCsv: _exportCsv,
          onExportMarkdown: _exportMarkdown,
        ),
        if (sourceLabels.length > 1)
          _SourceFilterBar(
            labels: sourceLabels,
            rows: _rows,
            activeFilters: _activeSourceFilters,
            expanded: _filtersExpanded,
            onToggle: _toggleSourceFilter,
            onClear: () => setState(_activeSourceFilters.clear),
            onExpandToggle: () =>
                setState(() => _filtersExpanded = !_filtersExpanded),
          ),
        if (widget.isInterrupted)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFFFFBEB),
              border: Border(bottom: BorderSide(color: Color(0xFFFEF3C7))),
            ),
            child: const Text(
              'Search stopped. Partial results are preserved.',
              style: TextStyle(fontSize: 14, color: Color(0xFFB45309)),
            ),
          ),
        if (!_isExpanded)
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
                      _isExpanded ? 'Show less' : 'Show more',
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

class _ResultsToolbar extends StatelessWidget {
  const _ResultsToolbar({
    required this.viewModeCard,
    required this.copiedResults,
    required this.showExportMenu,
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
            tooltip: 'Card view',
            onTap: onViewModeCard,
          ),
          const SizedBox(width: 4),
          _ToolbarIconButton(
            asset: DeepSearchResultsAssets.listView,
            selected: !viewModeCard,
            tooltip: 'Table view',
            onTap: onViewModeTable,
          ),
          const Spacer(),
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
                    'Export',
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

class _SourceFilterBar extends StatelessWidget {
  const _SourceFilterBar({
    required this.labels,
    required this.rows,
    required this.activeFilters,
    required this.expanded,
    required this.onToggle,
    required this.onClear,
    required this.onExpandToggle,
  });

  final List<String> labels;
  final List<Map<String, dynamic>> rows;
  final Set<String> activeFilters;
  final bool expanded;
  final ValueChanged<String> onToggle;
  final VoidCallback onClear;
  final VoidCallback onExpandToggle;

  @override
  Widget build(BuildContext context) {
    final filtersOverflow = labels.length > 3;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(
        color: DeepSearchResultsColors.filterBg,
        border: Border(bottom: BorderSide(color: DeepSearchResultsColors.filterBorder)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRect(
              child: Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: expanded ? double.infinity : 24,
                  ),
                  child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                  for (final label in labels)
                    _SourceFilterChip(
                      label: label,
                      count: rows
                          .where((r) => getRowSourceLabel(r) == label)
                          .length,
                      active: activeFilters.contains(label),
                      icon: findSourceCategory(
                            rows
                                    .firstWhere(
                                      (r) => getRowSourceLabel(r) == label,
                                      orElse: () => rows.first,
                                    )['source']
                                    ?.toString() ??
                                '',
                          )?.icon ??
                          Icons.language,
                      onTap: () => onToggle(label),
                    ),
                  if (activeFilters.isNotEmpty)
                    TextButton(
                      onPressed: onClear,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Clear',
                        style: TextStyle(fontSize: 12, color: Color(0xFFA5A39E)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ),
          if (filtersOverflow)
            IconButton(
              onPressed: onExpandToggle,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              icon: Icon(
                expanded ? Icons.expand_less : Icons.expand_more,
                size: 16,
                color: const Color(0xFFA5A39E),
              ),
            ),
        ],
      ),
    );
  }
}

class _SourceFilterChip extends StatelessWidget {
  const _SourceFilterChip({
    required this.label,
    required this.count,
    required this.active,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool active;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF6B6962) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? const Color(0xFF6B6962) : const Color(0xFFD5D3CE),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: active ? Colors.white : const Color(0xFF6B6B6B),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: active ? Colors.white : const Color(0xFF6B6B6B),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                color: active
                    ? Colors.white.withValues(alpha: 0.7)
                    : const Color(0xFFA5A39E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardResultsList extends StatelessWidget {
  const _CardResultsList({
    required this.rows,
    required this.allRowsCount,
    required this.isFiltered,
    this.selectedRowId,
    this.onRowClick,
  });

  final List<Map<String, dynamic>> rows;
  final int allRowsCount;
  final bool isFiltered;
  final String? selectedRowId;
  final void Function(Map<String, dynamic> row)? onRowClick;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty && isFiltered && allRowsCount > 0) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            'No candidates match the selected source filters.',
            style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
          ),
        ),
      );
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
            ),
          _CandidateResultCard(
            row: rows[i],
            selected: selectedRowId != null &&
                selectedRowId == rows[i]['row_id']?.toString(),
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
  });

  final Map<String, dynamic> row;
  final Map<String, dynamic> prevRow;
  final String? selectedRowId;

  @override
  Widget build(BuildContext context) {
    final rowId = row['row_id']?.toString();
    final prevId = prevRow['row_id']?.toString();
    final fullWidth = selectedRowId != null &&
        (selectedRowId == rowId || selectedRowId == prevId);
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
    this.onTap,
  });

  final Map<String, dynamic> row;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final name = row['name']?.toString() ?? '';
    final title = row['title']?.toString() ?? '';
    final company = row['company']?.toString() ?? '';
    final evidence = row['evidence']?.toString() ?? '';
    final confidence = formatConfidence(row['confidence']);
    final badge = matchBadgeStyle(confidence);
    final subtitle =
        [title, company].where((s) => s.trim().isNotEmpty).join(' · ');

    return Material(
      color: selected ? const Color(0xFFF0EFE9) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: const Color(0xFFF5F4EF),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
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
                    const SizedBox(height: 4),
                    Row(
                      children: [
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
                        Expanded(
                          child: Text(
                            evidence.isEmpty ? '—' : evidence,
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
                          'Add',
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

class _TableResultsView extends StatelessWidget {
  const _TableResultsView({
    required this.rows,
    required this.allRowsCount,
    required this.isFiltered,
    required this.sortColumn,
    required this.sortAscending,
    this.selectedRowId,
    required this.onSort,
    this.onRowClick,
  });

  final List<Map<String, dynamic>> rows;
  final int allRowsCount;
  final bool isFiltered;
  final DeepSearchResultsSortColumn sortColumn;
  final bool sortAscending;
  final String? selectedRowId;
  final ValueChanged<DeepSearchResultsSortColumn> onSort;
  final void Function(Map<String, dynamic> row)? onRowClick;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty && isFiltered && allRowsCount > 0) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            'No candidates match the selected source filters.',
            style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
          ),
        ),
      );
    }

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
          const DataColumn(label: Text('#')),
          _SortableDataColumn(
            label: 'Candidate',
            column: DeepSearchResultsSortColumn.name,
            active: sortColumn == DeepSearchResultsSortColumn.name,
            ascending: sortAscending,
            onSort: onSort,
          ),
          _SortableDataColumn(
            label: 'Match',
            column: DeepSearchResultsSortColumn.confidence,
            active: sortColumn == DeepSearchResultsSortColumn.confidence,
            ascending: sortAscending,
            onSort: onSort,
          ),
          _SortableDataColumn(
            label: 'Company',
            column: DeepSearchResultsSortColumn.company,
            active: sortColumn == DeepSearchResultsSortColumn.company,
            ascending: sortAscending,
            onSort: onSort,
          ),
          _SortableDataColumn(
            label: 'Title',
            column: DeepSearchResultsSortColumn.title,
            active: sortColumn == DeepSearchResultsSortColumn.title,
            ascending: sortAscending,
            onSort: onSort,
          ),
          const DataColumn(label: Text('Match Reason')),
        ],
        rows: [
          for (var i = 0; i < rows.length; i++)
            _buildRow(context, rows[i], i + 1),
        ],
      ),
    );
  }

  DataRow _buildRow(
    BuildContext context,
    Map<String, dynamic> row,
    int index,
  ) {
    final rowId = row['row_id']?.toString();
    final selected = selectedRowId != null && selectedRowId == rowId;
    final confidence = formatConfidence(row['confidence']);
    final badge = matchBadgeStyle(confidence);
    final rowTap = onRowClick == null ? null : () => onRowClick!(row);
    return DataRow(
      color: WidgetStateProperty.resolveWith((states) {
        if (selected) return const Color(0xFFF9F8F5);
        if (states.contains(WidgetState.hovered)) {
          return const Color(0xFFFDFCF9);
        }
        return Colors.white;
      }),
      cells: [
        DataCell(Text('$index'), onTap: rowTap),
        DataCell(Text(row['name']?.toString() ?? ''), onTap: rowTap),
        DataCell(
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
          onTap: rowTap,
        ),
        DataCell(Text(row['company']?.toString() ?? ''), onTap: rowTap),
        DataCell(Text(row['title']?.toString() ?? ''), onTap: rowTap),
        DataCell(
          SizedBox(
            width: 180,
            child: Text(
              row['evidence']?.toString() ?? '—',
              overflow: TextOverflow.ellipsis,
            ),
          ),
          onTap: rowTap,
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
