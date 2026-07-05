import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../services/search_service.dart';
import '../../../services/shortlist_service.dart';
import '../../../stores/user_store.dart';
import '../deep_search/deep_search_models.dart';
import '../deep_search/deep_search_results.dart';
import '../deep_search/deep_search_results_helpers.dart';
import '../deep_search/deep_search_results_strings.dart';
import '../enrich/shortlist_folder_modal.dart';

/// 与 TSX `AgenticChat` showMobileResultsWorkspace 对齐。
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
  final Map<String, String> _favoriteMap = {};

  List<Map<String, dynamic>> _visibleRows = [];
  List<Map<String, dynamic>> _selectedRows = [];
  var _resultsCopied = false;
  var _isSaving = false;
  var _isExportingPdf = false;
  final _searchService = SearchService();

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      final items = await _shortlistService.listFavorites();
      if (!mounted) return;
      final map = <String, String>{};
      for (final item in items) {
        final rowId = item.field['row_id']?.toString();
        if (rowId != null && rowId.isNotEmpty) map[rowId] = item.id;
      }
      setState(() => _favoriteMap.addAll(map));
    } catch (_) {}
  }

  List<Map<String, dynamic>> get _visibleRowsForActions =>
      _visibleRows.isNotEmpty ? _visibleRows : widget.candidates;

  List<Map<String, dynamic>> get _selectedUnsavedRows => _selectedRows
      .where((row) => !_favoriteMap.containsKey(row['row_id']?.toString()))
      .toList();

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleCopyResults() async {
    final rows = _visibleRowsForActions;
    if (rows.isEmpty) return;
    await Clipboard.setData(
      ClipboardData(text: buildSearchResultsMarkdown(rows)),
    );
    setState(() => _resultsCopied = true);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _resultsCopied = false);
    });
  }

  Future<void> _handleShare() async {
    _showToast(DeepSearchResultsStrings.toastComingSoon);
  }

  Future<void> _handleSaveCandidates() async {
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
    await _saveCandidatesToFolder(projectId);
  }

  Future<void> _saveCandidatesToFolder(String projectId) async {
    final rowsToSave = _selectedUnsavedRows;
    if (rowsToSave.isEmpty) return;
    setState(() => _isSaving = true);
    var savedCount = 0;
    try {
      for (final row in rowsToSave) {
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
      if (mounted) {
        _showToast('Failed to save candidates');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
    if (!mounted) return;
    _showToast(
      DeepSearchResultsStrings.toastSavedCandidates(
        savedCount > 0 ? savedCount : rowsToSave.length,
      ),
    );
  }

  Future<void> _exportCsv() async {
    await _shareAsFile(buildSearchResultsCsv(_visibleRowsForActions), 'csv');
  }

  Future<void> _exportMarkdown() async {
    await _shareAsFile(
      buildSearchResultsMarkdown(_visibleRowsForActions),
      'md',
    );
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
      await Share.shareXFiles([
        XFile(file.path),
      ], subject: 'deep-search-$sessionId.pdf');
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

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final hasSelection = _selectedRows.isNotEmpty;

    return Material(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFEAE8E3))),
            ),
            padding: EdgeInsets.only(top: topPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 48,
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: widget.onClose,
                        icon: const Icon(Icons.arrow_back, size: 20),
                        color: const Color(0xFF171717),
                        tooltip: DeepSearchResultsStrings.mobileBack,
                      ),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: DeepSearchResultsStrings.headerTitle,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF171717),
                                ),
                              ),
                              TextSpan(
                                text: ' (${widget.candidates.length})',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF8A8880),
                                ),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
                Container(
                  height: 48,
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0xFFF5F3EE))),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _SaveCandidatesButton(
                        hasSelection: hasSelection,
                        isSaving: _isSaving,
                        label: hasSelection
                            ? DeepSearchResultsStrings.headerSaveSelectedCandidates(
                                _selectedRows.length,
                              )
                            : DeepSearchResultsStrings.headerSaveCandidates,
                        onTap: _handleSaveCandidates,
                      ),
                      const Spacer(),
                      _ActionIconButton(
                        tooltip: DeepSearchResultsStrings.headerShare,
                        icon: Icons.ios_share_outlined,
                        onTap: _handleShare,
                      ),
                      const SizedBox(width: 6),
                      _ActionIconButton(
                        tooltip: DeepSearchResultsStrings.copyResults,
                        icon: _resultsCopied
                            ? Icons.check
                            : Icons.copy_outlined,
                        onTap: _handleCopyResults,
                      ),
                      const SizedBox(width: 6),
                      PopupMenuButton<String>(
                        tooltip: DeepSearchResultsStrings.exportButton,
                        offset: const Offset(0, 40),
                        color: Colors.white,
                        elevation: 4,
                        shadowColor: const Color(0x1A786E5A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Color(0xFFEAE8E3)),
                        ),
                        onSelected: (value) {
                          switch (value) {
                            case 'csv':
                              _exportCsv();
                            case 'markdown':
                              _exportMarkdown();
                            case 'pdf':
                              _handleExportPdf();
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'csv',
                            height: 36,
                            child: Text(
                              'CSV',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B6962),
                              ),
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'markdown',
                            height: 36,
                            child: Text(
                              'Markdown',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B6962),
                              ),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'pdf',
                            height: 36,
                            enabled: !_pdfExportDisabled,
                            child: Text(
                              'PDF',
                              style: TextStyle(
                                fontSize: 12,
                                color: _pdfExportDisabled
                                    ? const Color(0xFF9CA3AF)
                                    : const Color(0xFF6B6962),
                              ),
                            ),
                          ),
                        ],
                        child: const _ActionIconButtonShell(
                          child: Icon(
                            Icons.download_outlined,
                            size: 14,
                            color: Color(0xFF4F4C47),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: DeepSearchResults(
              candidates: widget.candidates,
              isSearching: widget.isSearching,
              isInterrupted: widget.isInterrupted,
              selectedRowId: widget.selectedRowId,
              variant: DeepSearchResultsVariant.mobile,
              showHeader: false,
              roundStatus: widget.roundStatus,
              contentBlocks: widget.contentBlocks,
              subAgents: widget.subAgents,
              sessionId: widget.sessionId,
              sseEventsId: widget.sseEventsId,
              onVisibleRowsChange: (rows) {
                if (!mounted) return;
                setState(() => _visibleRows = rows);
              },
              onSelectedRowsChange: (rows) {
                if (!mounted) return;
                setState(() => _selectedRows = rows);
              },
              onRowClick: (row) =>
                  widget.onRowClick(candidateRowToTabCandidate(row)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SaveCandidatesButton extends StatelessWidget {
  const _SaveCandidatesButton({
    required this.hasSelection,
    required this.isSaving,
    required this.label,
    required this.onTap,
  });

  final bool hasSelection;
  final bool isSaving;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isSaving ? null : onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: hasSelection ? const Color(0xFF171717) : Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: hasSelection
                  ? const Color(0xFF171717)
                  : const Color(0xFFE5E3DE),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSaving)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: hasSelection
                        ? Colors.white
                        : const Color(0xFF4F4C47),
                  ),
                )
              else
                SvgPicture.asset(
                  DeepSearchResultsAssets.bookmark,
                  width: 14,
                  height: 14,
                  colorFilter: ColorFilter.mode(
                    hasSelection ? Colors.white : const Color(0xFF4F4C47),
                    BlendMode.srcIn,
                  ),
                ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: hasSelection
                        ? Colors.white
                        : const Color(0xFF4F4C47),
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

class _ActionIconButton extends StatelessWidget {
  const _ActionIconButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: _ActionIconButtonShell(
            child: Icon(icon, size: 14, color: const Color(0xFF4F4C47)),
          ),
        ),
      ),
    );
  }
}

class _ActionIconButtonShell extends StatelessWidget {
  const _ActionIconButtonShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE5E3DE)),
      ),
      child: child,
    );
  }
}
