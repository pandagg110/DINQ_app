import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'deep_search_results_helpers.dart';
import 'deep_search_results_strings.dart';

// 与 TSX DeepSearchResults 表格常量对齐。
const _frozenSelectWidth = 38.0;
const _sourceGroupWidth = 38.0;
const _frozenCandidateWidth = 132.0;
const _mobileFrozenAvatarWidth = 48.0;
const _mobileNameWidth = 92.0;
const _resultSkeletonRowCount = 8;
const _pendingGroupSkeletonRowCount = 1;
const _tableBottomSpacerHeight = 72.0;
const _rowHeight = 44.0;
const _headerHeight = 40.0;
const _cellPaddingSmH = 12.0; // px-3
const _cellPaddingLgH = 20.0; // px-5
const _cellRowPaddingV = 10.0; // py-2.5
const _cellHeaderPaddingV = 12.0; // py-3

EdgeInsets _tableCellPadding({double horizontal = _cellPaddingLgH}) {
  return EdgeInsets.symmetric(horizontal: horizontal, vertical: _cellRowPaddingV);
}

EdgeInsets _tableHeaderPadding({double horizontal = _cellPaddingLgH}) {
  return EdgeInsets.symmetric(
    horizontal: horizontal,
    vertical: _cellHeaderPaddingV,
  );
}

Widget _buildSelectCell({required Widget? child}) {
  return SizedBox(
    width: _frozenSelectWidth,
    child: Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        widthFactor: 1,
        heightFactor: 1,
        child: child,
      ),
    ),
  );
}

/// 与 TSX Table View 对齐：sticky 冻结列、骨架屏、Source Group 列。
class DeepSearchResultsTable extends StatefulWidget {
  const DeepSearchResultsTable({
    super.key,
    required this.rows,
    required this.isSearching,
    required this.isMobileResults,
    required this.isRail,
    required this.sortColumn,
    required this.sortAscending,
    required this.selectedRowIds,
    required this.onToggleAll,
    required this.onToggleSelectedRow,
    required this.onSort,
    this.favoriteMap = const {},
    this.onBookmarkTap,
    this.selectedRowId,
    this.sourceGroupsByRowId,
    this.pendingSourceGroups,
    this.onRowClick,
    this.expandVertically = true,
  });

  final List<Map<String, dynamic>> rows;
  final bool isSearching;
  final bool isMobileResults;
  final bool isRail;
  final DeepSearchResultsSortColumn sortColumn;
  final bool sortAscending;
  final String? selectedRowId;
  final Set<String> selectedRowIds;
  final VoidCallback onToggleAll;
  final ValueChanged<String> onToggleSelectedRow;
  final ValueChanged<DeepSearchResultsSortColumn> onSort;
  final Map<String, String> favoriteMap;
  final void Function(Map<String, dynamic> row)? onBookmarkTap;
  final Map<String, ResultSourceGroup>? sourceGroupsByRowId;
  final List<ResultSourceGroup>? pendingSourceGroups;
  final void Function(Map<String, dynamic> row)? onRowClick;
  final bool expandVertically;

  @override
  State<DeepSearchResultsTable> createState() => _DeepSearchResultsTableState();
}

class _DeepSearchResultsTableState extends State<DeepSearchResultsTable> {
  final _leftVerticalController = ScrollController();
  final _rightVerticalController = ScrollController();
  final _headerHorizontalController = ScrollController();
  final _bodyHorizontalController = ScrollController();
  var _syncingVertical = false;
  var _syncingHorizontal = false;

  @override
  void initState() {
    super.initState();
    _leftVerticalController.addListener(() {
      _syncScroll(_leftVerticalController, _rightVerticalController, () {
        _syncingVertical = true;
      }, () {
        _syncingVertical = false;
      }, _syncingVertical);
    });
    _rightVerticalController.addListener(() {
      _syncScroll(_rightVerticalController, _leftVerticalController, () {
        _syncingVertical = true;
      }, () {
        _syncingVertical = false;
      }, _syncingVertical);
    });
    _bodyHorizontalController.addListener(() {
      _syncScroll(_bodyHorizontalController, _headerHorizontalController, () {
        _syncingHorizontal = true;
      }, () {
        _syncingHorizontal = false;
      }, _syncingHorizontal);
    });
    _headerHorizontalController.addListener(() {
      _syncScroll(_headerHorizontalController, _bodyHorizontalController, () {
        _syncingHorizontal = true;
      }, () {
        _syncingHorizontal = false;
      }, _syncingHorizontal);
    });
  }

  @override
  void dispose() {
    _leftVerticalController.dispose();
    _rightVerticalController.dispose();
    _headerHorizontalController.dispose();
    _bodyHorizontalController.dispose();
    super.dispose();
  }

  void _syncScroll(
    ScrollController source,
    ScrollController target,
    VoidCallback onStart,
    VoidCallback onEnd,
    bool syncing,
  ) {
    if (syncing || !source.hasClients || !target.hasClients) return;
    if (target.offset == source.offset) return;
    onStart();
    target.jumpTo(source.offset);
    onEnd();
  }

  @override
  Widget build(BuildContext context) {
    final pendingGroups = widget.pendingSourceGroups ?? const [];
    final sourceMap = widget.sourceGroupsByRowId ?? const {};
    final showSourceGroupColumn =
        sourceMap.isNotEmpty || pendingGroups.isNotEmpty;
    final showRailSkeleton = (widget.isRail || widget.isMobileResults) &&
        widget.rows.isEmpty &&
        widget.isSearching &&
        pendingGroups.isEmpty;
    final showPendingGroupSkeleton = (widget.isRail || widget.isMobileResults) &&
        widget.isSearching &&
        pendingGroups.isNotEmpty;
    final showLoadingSkeleton = showRailSkeleton || showPendingGroupSkeleton;
    final pendingSkeletonRows = pendingGroups
        .expand((group) => List.generate(
              _pendingGroupSkeletonRowCount,
              (index) => _PendingSkeletonRow(group: group, index: index),
            ))
        .toList();

    if (widget.rows.isEmpty && !showLoadingSkeleton) {
      return const SizedBox.shrink();
    }

    final hasDisplayConfidence =
        widget.rows.any((row) => getDisplayMatch(row).confidence != null);
    final hasDisplayEvidence =
        widget.rows.any((row) => getDisplayMatch(row).evidence.isNotEmpty);
    final hasCompany =
        widget.rows.any((r) => (r['company']?.toString() ?? '').trim().isNotEmpty);
    final hasTitle =
        widget.rows.any((r) => (r['title']?.toString() ?? '').trim().isNotEmpty);
    final showInitialFullSkeleton = widget.rows.isEmpty && showRailSkeleton;
    final showMatchColumn = hasDisplayConfidence || showInitialFullSkeleton;
    final showEvidenceColumn = hasDisplayEvidence || showInitialFullSkeleton;
    final showCompanyColumn = hasCompany || showLoadingSkeleton;
    final showTitleColumn = hasTitle || showLoadingSkeleton;
    final showSelectionControls = widget.rows.isNotEmpty || showLoadingSkeleton;
    final selectionDisabled = widget.rows.isEmpty || showLoadingSkeleton;
    final allSelected = widget.rows.isNotEmpty &&
        widget.rows.every(
          (row) => widget.selectedRowIds.contains(row['row_id']?.toString()),
        );

    final frozenIdentityWidth =
        widget.isMobileResults ? _mobileFrozenAvatarWidth : _frozenCandidateWidth;
    final frozenWidth = _frozenSelectWidth +
        (showSourceGroupColumn ? _sourceGroupWidth : 0) +
        frozenIdentityWidth;

    final scrollableWidth = _computeScrollableWidth(
      showMatchColumn: showMatchColumn,
      showCompanyColumn: showCompanyColumn,
      showTitleColumn: showTitleColumn,
      showEvidenceColumn: showEvidenceColumn,
      isMobile: widget.isMobileResults,
    );

    final bodyRowCount = showRailSkeleton
        ? _resultSkeletonRowCount
        : showPendingGroupSkeleton
            ? pendingSkeletonRows.length
            : widget.rows.length;
    final showBottomSpacer =
        widget.rows.isNotEmpty && !(widget.isRail || widget.isMobileResults);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(right: BorderSide(color: Color(0xFFF0EFEB))),
              ),
              child: _FrozenHeader(
                width: frozenWidth,
                showSourceGroupColumn: showSourceGroupColumn,
                isMobileResults: widget.isMobileResults,
                frozenIdentityWidth: frozenIdentityWidth,
                showSelectionControls: showSelectionControls,
                selectionDisabled: selectionDisabled,
                allSelected: allSelected,
                onToggleAll: widget.onToggleAll,
                sortColumn: widget.sortColumn,
                sortAscending: widget.sortAscending,
                onSort: widget.onSort,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: _headerHorizontalController,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: scrollableWidth,
                  height: _headerHeight,
                  child: _ScrollableHeader(
                    width: scrollableWidth,
                    isMobileResults: widget.isMobileResults,
                    showMatchColumn: showMatchColumn,
                    showCompanyColumn: showCompanyColumn,
                    showTitleColumn: showTitleColumn,
                    showEvidenceColumn: showEvidenceColumn,
                    sortColumn: widget.sortColumn,
                    sortAscending: widget.sortAscending,
                    onSort: widget.onSort,
                  ),
                ),
              ),
            ),
          ],
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFFEAE8E3)),
        if (widget.expandVertically)
          Expanded(
            child: _buildBody(
              bodyRowCount: bodyRowCount,
              showBottomSpacer: showBottomSpacer,
              showRailSkeleton: showRailSkeleton,
              showPendingGroupSkeleton: showPendingGroupSkeleton,
              pendingSkeletonRows: pendingSkeletonRows,
              frozenWidth: frozenWidth,
              scrollableWidth: scrollableWidth,
              showSourceGroupColumn: showSourceGroupColumn,
              frozenIdentityWidth: frozenIdentityWidth,
              showMatchColumn: showMatchColumn,
              showCompanyColumn: showCompanyColumn,
              showTitleColumn: showTitleColumn,
              showEvidenceColumn: showEvidenceColumn,
              sourceMap: sourceMap,
            ),
          )
        else
          _buildBody(
            bodyRowCount: bodyRowCount,
            showBottomSpacer: showBottomSpacer,
            showRailSkeleton: showRailSkeleton,
            showPendingGroupSkeleton: showPendingGroupSkeleton,
            pendingSkeletonRows: pendingSkeletonRows,
            frozenWidth: frozenWidth,
            scrollableWidth: scrollableWidth,
            showSourceGroupColumn: showSourceGroupColumn,
            frozenIdentityWidth: frozenIdentityWidth,
            showMatchColumn: showMatchColumn,
            showCompanyColumn: showCompanyColumn,
            showTitleColumn: showTitleColumn,
            showEvidenceColumn: showEvidenceColumn,
            sourceMap: sourceMap,
          ),
      ],
    );
  }

  Widget _buildBody({
    required int bodyRowCount,
    required bool showBottomSpacer,
    required bool showRailSkeleton,
    required bool showPendingGroupSkeleton,
    required List<_PendingSkeletonRow> pendingSkeletonRows,
    required double frozenWidth,
    required double scrollableWidth,
    required bool showSourceGroupColumn,
    required double frozenIdentityWidth,
    required bool showMatchColumn,
    required bool showCompanyColumn,
    required bool showTitleColumn,
    required bool showEvidenceColumn,
    required Map<String, ResultSourceGroup> sourceMap,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(right: BorderSide(color: Color(0xFFF0EFEB))),
          ),
          child: SizedBox(
            width: frozenWidth,
            child: _buildFrozenList(
              bodyRowCount: bodyRowCount,
              showBottomSpacer: showBottomSpacer,
              showRailSkeleton: showRailSkeleton,
              showPendingGroupSkeleton: showPendingGroupSkeleton,
              pendingSkeletonRows: pendingSkeletonRows,
              showSourceGroupColumn: showSourceGroupColumn,
              frozenIdentityWidth: frozenIdentityWidth,
              sourceMap: sourceMap,
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            controller: _bodyHorizontalController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: scrollableWidth,
              child: _buildScrollableList(
                bodyRowCount: bodyRowCount,
                showBottomSpacer: showBottomSpacer,
                showRailSkeleton: showRailSkeleton,
                showPendingGroupSkeleton: showPendingGroupSkeleton,
                pendingSkeletonRows: pendingSkeletonRows,
                scrollableWidth: scrollableWidth,
                showMatchColumn: showMatchColumn,
                showCompanyColumn: showCompanyColumn,
                showTitleColumn: showTitleColumn,
                showEvidenceColumn: showEvidenceColumn,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFrozenList({
    required int bodyRowCount,
    required bool showBottomSpacer,
    required bool showRailSkeleton,
    required bool showPendingGroupSkeleton,
    required List<_PendingSkeletonRow> pendingSkeletonRows,
    required bool showSourceGroupColumn,
    required double frozenIdentityWidth,
    required Map<String, ResultSourceGroup> sourceMap,
  }) {
    final list = ListView.builder(
      controller: _leftVerticalController,
      shrinkWrap: !widget.expandVertically,
      physics: widget.expandVertically
          ? const ClampingScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: bodyRowCount + (showBottomSpacer ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= bodyRowCount) {
          return const SizedBox(height: _tableBottomSpacerHeight);
        }
        if (showRailSkeleton) {
          return _FrozenSkeletonRow(
            index: index,
            showSourceGroupColumn: showSourceGroupColumn,
            isMobileResults: widget.isMobileResults,
            frozenIdentityWidth: frozenIdentityWidth,
          );
        }
        if (showPendingGroupSkeleton) {
          final skeleton = pendingSkeletonRows[index];
          return _FrozenPendingSkeletonRow(
            skeleton: skeleton,
            showSourceGroupColumn: showSourceGroupColumn,
            isMobileResults: widget.isMobileResults,
            frozenIdentityWidth: frozenIdentityWidth,
          );
        }
        final row = widget.rows[index];
        return _FrozenDataRow(
          row: row,
          showSourceGroupColumn: showSourceGroupColumn,
          isMobileResults: widget.isMobileResults,
          frozenIdentityWidth: frozenIdentityWidth,
          sourceGroup: sourceMap[row['row_id']?.toString() ?? ''],
          selectedRowId: widget.selectedRowId,
          selectedRowIds: widget.selectedRowIds,
          onToggleSelectedRow: widget.onToggleSelectedRow,
          onRowClick: widget.onRowClick,
        );
      },
    );
    return list;
  }

  Widget _buildScrollableList({
    required int bodyRowCount,
    required bool showBottomSpacer,
    required bool showRailSkeleton,
    required bool showPendingGroupSkeleton,
    required List<_PendingSkeletonRow> pendingSkeletonRows,
    required double scrollableWidth,
    required bool showMatchColumn,
    required bool showCompanyColumn,
    required bool showTitleColumn,
    required bool showEvidenceColumn,
  }) {
    return ListView.builder(
      controller: _rightVerticalController,
      shrinkWrap: !widget.expandVertically,
      physics: widget.expandVertically
          ? const ClampingScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: bodyRowCount + (showBottomSpacer ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= bodyRowCount) {
          return const SizedBox(height: _tableBottomSpacerHeight);
        }
        if (showRailSkeleton) {
          return _ScrollableSkeletonRow(
            index: index,
            width: scrollableWidth,
            showMatchColumn: showMatchColumn,
            showCompanyColumn: showCompanyColumn,
            showTitleColumn: showTitleColumn,
            showEvidenceColumn: showEvidenceColumn,
            isMobileResults: widget.isMobileResults,
          );
        }
        if (showPendingGroupSkeleton) {
          final skeleton = pendingSkeletonRows[index];
          return _ScrollablePendingSkeletonRow(
            skeleton: skeleton,
            width: scrollableWidth,
            showMatchColumn: showMatchColumn,
            showCompanyColumn: showCompanyColumn,
            showTitleColumn: showTitleColumn,
            showEvidenceColumn: showEvidenceColumn,
            isMobileResults: widget.isMobileResults,
          );
        }
        final row = widget.rows[index];
        return _ScrollableDataRow(
          row: row,
          width: scrollableWidth,
          showMatchColumn: showMatchColumn,
          showCompanyColumn: showCompanyColumn,
          showTitleColumn: showTitleColumn,
          showEvidenceColumn: showEvidenceColumn,
          isMobileResults: widget.isMobileResults,
          selectedRowId: widget.selectedRowId,
          onRowClick: widget.onRowClick,
          favoriteMap: widget.favoriteMap,
          onBookmarkTap: widget.onBookmarkTap,
        );
      },
    );
  }

  double _computeScrollableWidth({
    required bool showMatchColumn,
    required bool showCompanyColumn,
    required bool showTitleColumn,
    required bool showEvidenceColumn,
    required bool isMobile,
  }) {
    var width = 0.0;
    if (isMobile) width += _mobileNameWidth;
    if (showMatchColumn) width += 96;
    if (showCompanyColumn) width += 160;
    if (showTitleColumn) width += 180;
    if (showEvidenceColumn) width += 400;
    width += 192; // profile
    width += 48; // bookmark
    return width;
  }
}

class _PendingSkeletonRow {
  const _PendingSkeletonRow({required this.group, required this.index});
  final ResultSourceGroup group;
  final int index;
}

class _FrozenHeader extends StatelessWidget {
  const _FrozenHeader({
    required this.width,
    required this.showSourceGroupColumn,
    required this.isMobileResults,
    required this.frozenIdentityWidth,
    required this.showSelectionControls,
    required this.selectionDisabled,
    required this.allSelected,
    required this.onToggleAll,
    required this.sortColumn,
    required this.sortAscending,
    required this.onSort,
  });

  final double width;
  final bool showSourceGroupColumn;
  final bool isMobileResults;
  final double frozenIdentityWidth;
  final bool showSelectionControls;
  final bool selectionDisabled;
  final bool allSelected;
  final VoidCallback onToggleAll;
  final DeepSearchResultsSortColumn sortColumn;
  final bool sortAscending;
  final ValueChanged<DeepSearchResultsSortColumn> onSort;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: _headerHeight,
      color: Colors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildSelectCell(
            child: showSelectionControls
                ? DeepSearchSelectCheckbox(
                    checked: allSelected,
                    onChanged: selectionDisabled ? null : onToggleAll,
                    disabled: selectionDisabled,
                  )
                : null,
          ),
          if (showSourceGroupColumn)
            SizedBox(
              width: _sourceGroupWidth,
              child: Center(
                child: isMobileResults
                    ? Icon(Icons.layers_outlined, size: 14, color: Color(0xFF9A978F))
                    : Text(
                        DeepSearchResultsStrings.columnGroup,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF8A8880),
                        ),
                      ),
              ),
            ),
          SizedBox(
            width: frozenIdentityWidth,
            child: isMobileResults
                ? Center(
                    child: Icon(
                      Icons.person_outline,
                      size: 14,
                      color: Color(0xFFB5B3AE),
                    ),
                  )
                : _SortableHeaderLabel(
                    label: DeepSearchResultsStrings.columnCandidate,
                    column: DeepSearchResultsSortColumn.name,
                    active: sortColumn == DeepSearchResultsSortColumn.name,
                    ascending: sortAscending,
                    onSort: onSort,
                  ),
          ),
        ],
      ),
    );
  }
}

class _ScrollableHeader extends StatelessWidget {
  const _ScrollableHeader({
    required this.width,
    required this.isMobileResults,
    required this.showMatchColumn,
    required this.showCompanyColumn,
    required this.showTitleColumn,
    required this.showEvidenceColumn,
    required this.sortColumn,
    required this.sortAscending,
    required this.onSort,
  });

  final double width;
  final bool isMobileResults;
  final bool showMatchColumn;
  final bool showCompanyColumn;
  final bool showTitleColumn;
  final bool showEvidenceColumn;
  final DeepSearchResultsSortColumn sortColumn;
  final bool sortAscending;
  final ValueChanged<DeepSearchResultsSortColumn> onSort;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Row(
        children: [
          if (isMobileResults)
            SizedBox(
              width: _mobileNameWidth,
              child: _SortableHeaderLabel(
                label: DeepSearchResultsStrings.columnName,
                column: DeepSearchResultsSortColumn.name,
                active: sortColumn == DeepSearchResultsSortColumn.name,
                ascending: sortAscending,
                onSort: onSort,
                horizontalPadding: _cellPaddingSmH,
              ),
            ),
          if (showMatchColumn)
            SizedBox(
              width: 96,
              child: _SortableHeaderLabel(
                label: DeepSearchResultsStrings.columnMatch,
                column: DeepSearchResultsSortColumn.confidence,
                active: sortColumn == DeepSearchResultsSortColumn.confidence,
                ascending: sortAscending,
                onSort: onSort,
                horizontalPadding: _cellPaddingSmH,
              ),
            ),
          if (showCompanyColumn)
            Expanded(
              flex: 160,
              child: _SortableHeaderLabel(
                label: DeepSearchResultsStrings.columnCompany,
                column: DeepSearchResultsSortColumn.company,
                active: sortColumn == DeepSearchResultsSortColumn.company,
                ascending: sortAscending,
                onSort: onSort,
              ),
            ),
          if (showTitleColumn)
            Expanded(
              flex: 180,
              child: _SortableHeaderLabel(
                label: DeepSearchResultsStrings.columnTitle,
                column: DeepSearchResultsSortColumn.title,
                active: sortColumn == DeepSearchResultsSortColumn.title,
                ascending: sortAscending,
                onSort: onSort,
              ),
            ),
          if (showEvidenceColumn)
            Expanded(
              flex: 400,
              child: Padding(
                padding: _tableHeaderPadding(),
                child: Text(
                  DeepSearchResultsStrings.columnMatchReason,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF8A8880),
                  ),
                ),
              ),
            ),
          SizedBox(
            width: 192,
            child: Padding(
              padding: _tableHeaderPadding(),
              child: Text(
                DeepSearchResultsStrings.columnProfile,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF8A8880),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 48,
            child: Padding(
              padding: _tableHeaderPadding(horizontal: _cellPaddingSmH),
              child: Center(
                child: Text(
                  DeepSearchResultsStrings.bookmarkAddShort,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF8A8880),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SortableHeaderLabel extends StatelessWidget {
  const _SortableHeaderLabel({
    required this.label,
    required this.column,
    required this.active,
    required this.ascending,
    required this.onSort,
    this.horizontalPadding = _cellPaddingLgH,
  });

  final String label;
  final DeepSearchResultsSortColumn column;
  final bool active;
  final bool ascending;
  final ValueChanged<DeepSearchResultsSortColumn> onSort;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onSort(column),
      child: Padding(
        padding: _tableHeaderPadding(horizontal: horizontalPadding),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF8A8880),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              active
                  ? (ascending
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down)
                  : Icons.swap_vert,
              size: 14,
              color: active ? const Color(0xFF8A8880) : const Color(0xFFD5D3CE),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchBadge extends StatelessWidget {
  const _MatchBadge({required this.confidence, required this.badge});

  final int confidence;
  final MatchBadgeStyle badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badge.background,
        borderRadius: BorderRadius.circular(999),
        border: Border(top: BorderSide(color: badge.border)),
      ),
      child: Text(
        '$confidence%',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: badge.foreground,
        ),
      ),
    );
  }
}

class _ProfileFavicon extends StatelessWidget {
  const _ProfileFavicon({required this.domain});

  final String domain;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: Image.network(
        'https://icons.duckduckgo.com/ip3/$domain.ico',
        width: 16,
        height: 16,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.language,
          size: 16,
          color: Color(0xFFA5A39E),
        ),
      ),
    );
  }
}

class _ProfileLinkCell extends StatelessWidget {
  const _ProfileLinkCell({required this.profileUrl});

  final String profileUrl;

  @override
  Widget build(BuildContext context) {
    if (profileUrl.isEmpty) {
      return const Text(
        '—',
        style: TextStyle(fontSize: 12, color: Color(0xFFD5D3CE)),
      );
    }

    final domain = profileHostFromUrl(profileUrl);
    return Row(
      children: [
        if (domain != null) ...[
          _ProfileFavicon(domain: domain),
          const SizedBox(width: 6),
        ],
        Expanded(
          child: Text(
            formatProfileUrlLabel(profileUrl),
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Color(0xFFA5A39E)),
          ),
        ),
      ],
    );
  }
}

class _BookmarkIconButton extends StatelessWidget {
  const _BookmarkIconButton({
    this.onPressed,
    this.isBookmarked = false,
  });

  final VoidCallback? onPressed;
  final bool isBookmarked;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: isBookmarked
              ? const Icon(Icons.bookmark, size: 16, color: Color(0xFF1F1F1F))
              : SvgPicture.asset(
                  DeepSearchResultsAssets.bookmark,
                  width: 16,
                  height: 16,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFFB5B3AE),
                    BlendMode.srcIn,
                  ),
                ),
        ),
      ),
    );
  }
}

class _SourceGroupBadge extends StatelessWidget {
  const _SourceGroupBadge({required this.group});

  final ResultSourceGroup group;

  @override
  Widget build(BuildContext context) {
    final label = group.index > 99 ? '99+' : '${group.index}';
    final colors = sourceGroupColor(group.index);
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${group.title} · ${group.count} candidates'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      borderRadius: BorderRadius.circular(4),
      child: Container(
        height: 20,
        constraints: const BoxConstraints(minWidth: 20),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: colors.bg,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: colors.border),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: colors.text,
          ),
        ),
      ),
    );
  }
}

class _SkeletonBar extends StatelessWidget {
  const _SkeletonBar({required this.width, this.height = 12});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return _ShimmerBox(
      width: width,
      height: height,
      borderRadius: height / 2,
    );
  }
}

class _ShimmerBox extends StatefulWidget {
  const _ShimmerBox({
    required this.width,
    required this.height,
    this.borderRadius = 4,
    this.color,
  });

  final double width;
  final double height;
  final double borderRadius;
  final Color? color;

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.color ?? const Color(0xFFE3DED4);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1 + _controller.value * 2, 0),
              end: Alignment(_controller.value * 2, 0),
              colors: [base, base.withValues(alpha: 0.55), base],
            ),
          ),
        );
      },
    );
  }
}

// --- Frozen row cells ---

class _FrozenSkeletonRow extends StatelessWidget {
  const _FrozenSkeletonRow({
    required this.index,
    required this.showSourceGroupColumn,
    required this.isMobileResults,
    required this.frozenIdentityWidth,
  });

  final int index;
  final bool showSourceGroupColumn;
  final bool isMobileResults;
  final double frozenIdentityWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _rowHeight,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0EFEB))),
        color: Colors.white,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildSelectCell(
            child: DeepSearchSelectCheckbox(
              checked: false,
              onChanged: null,
              disabled: true,
            ),
          ),
          if (showSourceGroupColumn)
            const SizedBox(width: _sourceGroupWidth),
          SizedBox(
            width: frozenIdentityWidth,
            child: isMobileResults
                ? Center(
                    child: _ShimmerBox(
                      width: 28,
                      height: 28,
                      borderRadius: 14,
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        _ShimmerBox(width: 28, height: 28, borderRadius: 14),
                        const SizedBox(width: 8),
                        _SkeletonBar(
                          width: index % 3 == 0 ? 64 : 80,
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FrozenPendingSkeletonRow extends StatelessWidget {
  const _FrozenPendingSkeletonRow({
    required this.skeleton,
    required this.showSourceGroupColumn,
    required this.isMobileResults,
    required this.frozenIdentityWidth,
  });

  final _PendingSkeletonRow skeleton;
  final bool showSourceGroupColumn;
  final bool isMobileResults;
  final double frozenIdentityWidth;

  @override
  Widget build(BuildContext context) {
    final avatarStyle = sourceGroupColor(skeleton.group.index);
    return Container(
      height: _rowHeight,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0EFEB))),
        color: Colors.white,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildSelectCell(
            child: DeepSearchSelectCheckbox(
              checked: false,
              onChanged: null,
              disabled: true,
            ),
          ),
          if (showSourceGroupColumn)
            SizedBox(
              width: _sourceGroupWidth,
              child: Center(child: _SourceGroupBadge(group: skeleton.group)),
            ),
          SizedBox(
            width: frozenIdentityWidth,
            child: isMobileResults
                ? Center(
                    child: _ShimmerBox(
                      width: 28,
                      height: 28,
                      borderRadius: 14,
                      color: avatarStyle.bg,
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        _ShimmerBox(
                          width: 28,
                          height: 28,
                          borderRadius: 14,
                          color: avatarStyle.bg,
                        ),
                        const SizedBox(width: 8),
                        _SkeletonBar(
                          width: skeleton.index % 3 == 0 ? 64 : 80,
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FrozenDataRow extends StatelessWidget {
  const _FrozenDataRow({
    required this.row,
    required this.showSourceGroupColumn,
    required this.isMobileResults,
    required this.frozenIdentityWidth,
    required this.sourceGroup,
    required this.selectedRowId,
    required this.selectedRowIds,
    required this.onToggleSelectedRow,
    this.onRowClick,
  });

  final Map<String, dynamic> row;
  final bool showSourceGroupColumn;
  final bool isMobileResults;
  final double frozenIdentityWidth;
  final ResultSourceGroup? sourceGroup;
  final String? selectedRowId;
  final Set<String> selectedRowIds;
  final ValueChanged<String> onToggleSelectedRow;
  final void Function(Map<String, dynamic> row)? onRowClick;

  @override
  Widget build(BuildContext context) {
    final rowId = row['row_id']?.toString() ?? '';
    final name = row['name']?.toString() ?? '';
    final verified = isResultVerified(row);
    final selected = selectedRowId != null && selectedRowId == rowId;
    final checked = selectedRowIds.contains(rowId);
    final nameColor =
        verified ? const Color(0xFF171717) : const Color(0xFF8A8880);
    final bg = selected
        ? const Color(0xFFF9F8F5)
        : checked
            ? const Color(0xFFF8F7F4)
            : Colors.white;

    return Material(
      color: bg,
      child: InkWell(
        onTap: onRowClick == null ? null : () => onRowClick!(row),
        child: Container(
          height: _rowHeight,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFF0EFEB))),
          ),
          child: Opacity(
            opacity: verified ? 1 : 0.55,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildSelectCell(
                  child: DeepSearchSelectCheckbox(
                    checked: checked,
                    onChanged: () => onToggleSelectedRow(rowId),
                  ),
                ),
                if (showSourceGroupColumn)
                  SizedBox(
                    width: _sourceGroupWidth,
                    child: Center(
                      child: sourceGroup != null
                          ? _SourceGroupBadge(group: sourceGroup!)
                          : null,
                    ),
                  ),
                SizedBox(
                  width: frozenIdentityWidth,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobileResults ? 4 : 12,
                    ),
                    child: Row(
                      mainAxisAlignment: isMobileResults
                          ? MainAxisAlignment.center
                          : MainAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: sourceGroup != null
                                ? sourceGroupColor(sourceGroup!.index).bg
                                : nameToAvatarColor(name),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            toInitials(name),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: sourceGroup != null
                                  ? sourceGroupColor(sourceGroup!.index).text
                                  : const Color(0xFF1F1F1F),
                            ),
                          ),
                        ),
                        if (!isMobileResults) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              name.isEmpty ? '—' : name,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: nameColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- Scrollable row cells ---

class _ScrollableSkeletonRow extends StatelessWidget {
  const _ScrollableSkeletonRow({
    required this.index,
    required this.width,
    required this.showMatchColumn,
    required this.showCompanyColumn,
    required this.showTitleColumn,
    required this.showEvidenceColumn,
    required this.isMobileResults,
  });

  final int index;
  final double width;
  final bool showMatchColumn;
  final bool showCompanyColumn;
  final bool showTitleColumn;
  final bool showEvidenceColumn;
  final bool isMobileResults;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: _rowHeight,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0EFEB))),
        color: Colors.white,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (isMobileResults)
            SizedBox(
              width: _mobileNameWidth,
              child: Padding(
                padding: _tableCellPadding(horizontal: _cellPaddingSmH),
                child: _SkeletonBar(width: index % 3 == 0 ? 64 : 80),
              ),
            ),
          if (showMatchColumn)
            SizedBox(
              width: 96,
              child: Padding(
                padding: _tableCellPadding(horizontal: _cellPaddingSmH),
                child: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: 1,
                  heightFactor: 1,
                  child: _SkeletonBar(width: 48, height: 20),
                ),
              ),
            ),
          if (showCompanyColumn)
            Expanded(
              flex: 160,
              child: Padding(
                padding: _tableCellPadding(),
                child: _SkeletonBar(width: index % 2 == 0 ? 112 : 144),
              ),
            ),
          if (showTitleColumn)
            Expanded(
              flex: 180,
              child: Padding(
                padding: _tableCellPadding(),
                child: _SkeletonBar(width: index % 2 == 0 ? 128 : 160),
              ),
            ),
          if (showEvidenceColumn)
            Expanded(
              flex: 400,
              child: Padding(
                padding: _tableCellPadding(),
                child: _SkeletonBar(width: index % 2 == 0 ? 320 : 256),
              ),
            ),
          SizedBox(
            width: 192,
            child: Padding(
              padding: _tableCellPadding(),
              child: _SkeletonBar(width: 112),
            ),
          ),
          SizedBox(
            width: 48,
            child: Padding(
              padding: _tableCellPadding(horizontal: _cellPaddingSmH),
              child: Center(
                child: _SkeletonBar(width: 16, height: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScrollablePendingSkeletonRow extends StatelessWidget {
  const _ScrollablePendingSkeletonRow({
    required this.skeleton,
    required this.width,
    required this.showMatchColumn,
    required this.showCompanyColumn,
    required this.showTitleColumn,
    required this.showEvidenceColumn,
    required this.isMobileResults,
  });

  final _PendingSkeletonRow skeleton;
  final double width;
  final bool showMatchColumn;
  final bool showCompanyColumn;
  final bool showTitleColumn;
  final bool showEvidenceColumn;
  final bool isMobileResults;

  @override
  Widget build(BuildContext context) {
    return _ScrollableSkeletonRow(
      index: skeleton.index,
      width: width,
      showMatchColumn: showMatchColumn,
      showCompanyColumn: showCompanyColumn,
      showTitleColumn: showTitleColumn,
      showEvidenceColumn: showEvidenceColumn,
      isMobileResults: isMobileResults,
    );
  }
}

class _ScrollableDataRow extends StatelessWidget {
  const _ScrollableDataRow({
    required this.row,
    required this.width,
    required this.showMatchColumn,
    required this.showCompanyColumn,
    required this.showTitleColumn,
    required this.showEvidenceColumn,
    required this.isMobileResults,
    required this.favoriteMap,
    this.selectedRowId,
    this.onRowClick,
    this.onBookmarkTap,
  });

  final Map<String, dynamic> row;
  final double width;
  final bool showMatchColumn;
  final bool showCompanyColumn;
  final bool showTitleColumn;
  final bool showEvidenceColumn;
  final bool isMobileResults;
  final Map<String, String> favoriteMap;
  final String? selectedRowId;
  final void Function(Map<String, dynamic> row)? onRowClick;
  final void Function(Map<String, dynamic> row)? onBookmarkTap;

  @override
  Widget build(BuildContext context) {
    final rowId = row['row_id']?.toString() ?? '';
    final verified = isResultVerified(row);
    final displayMatch = getDisplayMatch(row);
    final confidence = displayMatch.confidence == null
        ? null
        : formatConfidence(displayMatch.confidence);
    final badge = confidence == null ? null : matchBadgeStyle(confidence);
    final name = row['name']?.toString() ?? '';
    final profileUrl = row['profile_url']?.toString() ?? '';
    final nameColor =
        verified ? const Color(0xFF171717) : const Color(0xFF8A8880);
    final mutedColor =
        verified ? const Color(0xFF6B6962) : const Color(0xFF8A8880);
    final selected = selectedRowId != null && selectedRowId == rowId;
    final nextRowVerified = false; // boundary handled in frozen side

    return Material(
      color: selected ? const Color(0xFFF9F8F5) : Colors.white,
      child: InkWell(
        onTap: onRowClick == null ? null : () => onRowClick!(row),
        hoverColor: verified ? const Color(0xFFFDFCF9) : const Color(0xFFFBFAF7),
        child: Opacity(
          opacity: verified ? 1 : 0.55,
          child: Container(
            width: width,
            height: _rowHeight,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: verified && !nextRowVerified
                      ? const Color(0xFFF0EFEB)
                      : const Color(0xFFF0EFEB),
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (isMobileResults)
                  SizedBox(
                    width: _mobileNameWidth,
                    child: Padding(
                      padding: _tableCellPadding(horizontal: _cellPaddingSmH),
                      child: Text(
                        name.isEmpty ? '—' : name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: nameColor,
                        ),
                      ),
                    ),
                  ),
                if (showMatchColumn)
                  SizedBox(
                    width: 96,
                    child: Padding(
                      padding: _tableCellPadding(horizontal: _cellPaddingSmH),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        widthFactor: 1,
                        heightFactor: 1,
                        child: confidence != null && badge != null
                            ? _MatchBadge(
                                confidence: confidence,
                                badge: badge,
                              )
                            : null,
                      ),
                    ),
                  ),
                if (showCompanyColumn)
                  Expanded(
                    flex: 160,
                    child: Padding(
                      padding: _tableCellPadding(),
                      child: Text(
                        row['company']?.toString() ?? '—',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: mutedColor),
                      ),
                    ),
                  ),
                if (showTitleColumn)
                  Expanded(
                    flex: 180,
                    child: Padding(
                      padding: _tableCellPadding(),
                      child: Text(
                        row['title']?.toString() ?? '—',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: mutedColor),
                      ),
                    ),
                  ),
                if (showEvidenceColumn)
                  Expanded(
                    flex: 400,
                    child: Padding(
                      padding: _tableCellPadding(),
                      child: Text(
                        displayMatch.evidence.isEmpty
                            ? (confidence == null ? '' : '—')
                            : displayMatch.evidence,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: mutedColor),
                      ),
                    ),
                  ),
                SizedBox(
                  width: 192,
                  child: Padding(
                    padding: _tableCellPadding(),
                    child: _ProfileLinkCell(profileUrl: profileUrl),
                  ),
                ),
                SizedBox(
                  width: 48,
                  child: Padding(
                    padding: _tableCellPadding(horizontal: _cellPaddingSmH),
                    child: Center(
                      child: _BookmarkIconButton(
                        isBookmarked: favoriteMap.containsKey(rowId),
                        onPressed: onBookmarkTap == null
                            ? null
                            : () => onBookmarkTap!(row),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
