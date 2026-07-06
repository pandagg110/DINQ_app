import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../constants/shortlist_constants.dart';
import '../../models/deep_search_enrich_models.dart';
import '../../models/shortlist_models.dart';
import '../../services/search_service.dart';
import '../../services/shortlist_service.dart';
import '../../stores/deep_search_enrich_store.dart';
import '../../stores/main_store.dart';
import '../../stores/search_store.dart';
import '../../stores/shortlist_store.dart';
import '../../stores/user_store.dart';
import '../../theme/dinq_icons.dart';
import '../../theme/dinq_tokens.dart';
import '../../utils/top_toast_util.dart';
import '../../widgets/common/dinq_svg_icon.dart';
import '../../widgets/search/enrich/enrich_profile_view.dart';
import '../../widgets/search/enrich/enrich_stream_controller.dart';
import 'shortlist_strings.dart';
import 'widgets/shortlist_candidate_card.dart';
import 'widgets/shortlist_export_modal.dart';
import 'widgets/shortlist_move_folder_sheet.dart';
import 'widgets/shortlist_project_sidebar.dart';
import 'widgets/shortlist_shared_widgets.dart';

/// Shortlist Tab — 对齐 `my_first_app` `_ShortlistPage` 视觉样式。
class ShortlistPage extends StatefulWidget {
  const ShortlistPage({super.key});

  @override
  State<ShortlistPage> createState() => _ShortlistPageState();
}

class _ShortlistPageState extends State<ShortlistPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;
  EnrichStreamController? _enrichController;
  bool _controllerReady = false;
  bool _isExporting = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadWhenReady();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controllerReady) return;
    _controllerReady = true;
    _enrichController = EnrichStreamController(
      enrichStore: context.read<DeepSearchEnrichStore>(),
      searchService: SearchService(),
      sessionIdProvider: () =>
          context.read<SearchStore>().deepSearchSessionId ?? '',
    );
    context.read<DeepSearchEnrichStore>().addListener(_syncBottomNav);
    _syncBottomNav();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    context.read<DeepSearchEnrichStore>().removeListener(_syncBottomNav);
    _enrichController?.close();
    super.dispose();
  }

  void _syncBottomNav() {
    if (!mounted) return;
    final enrichOpen = context.read<DeepSearchEnrichStore>().isOpen;
    context.read<MainStore>().setShowBottomNav(!enrichOpen);
  }

  Future<void> _loadWhenReady() async {
    for (int i = 0; i < 25; i++) {
      if (!mounted) return;
      if (context.read<UserStore>().isLoggedIn()) {
        await context.read<ShortlistStore>().initialize();
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      final store = context.read<ShortlistStore>();
      store.setNameQuery(value);
      store.loadFavorites(clear: true);
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final store = context.read<ShortlistStore>();
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!store.isLoading && store.hasMore) {
        store.loadMore();
      }
    }
  }

  Future<void> _handleRowClick(FavoriteItem item) async {
    final store = context.read<ShortlistStore>();
    if (store.selectionMode) {
      store.toggleSelected(item.id);
      return;
    }
    final row = item.toEnrichRow();
    await _enrichController?.openEnrich(row);
    _syncBottomNav();
  }

  Future<void> _openBulkDeleteConfirm() async {
    final store = context.read<ShortlistStore>();
    final ids = store.selectedIds.toList();
    if (ids.isEmpty) return;
    await ShortlistConfirmModal.show(
      context,
      title: ShortlistStrings.bulkRemoveTitle(ids.length),
      message: ShortlistStrings.bulkRemoveMessage,
      confirmLabel: ShortlistStrings.bulkRemoveConfirm,
      variant: ShortlistConfirmVariant.destructive,
      onConfirm: () async {
        final result = await store.bulkRemove(ids);
        if (!mounted) return;
        if (result.fail > 0) {
          TopToastUtil.showError(
            context: context,
            title: ShortlistStrings.bulkRemovePartial(
              result.ok,
              ids.length,
              result.fail,
            ),
            description: '',
          );
        } else {
          TopToastUtil.showSuccess(
            context: context,
            title: ShortlistStrings.bulkRemoveSuccess(result.ok),
            description: '',
          );
        }
        store.clearSelected();
      },
    );
  }

  Future<void> _openMoveSheet() async {
    final store = context.read<ShortlistStore>();
    final target = await showShortlistMoveFolderSheet(
      context,
      currentFolderName: store.activeProjectName,
      selectedCount: store.selectedIds.length,
      targetProjects: store.moveTargetProjects,
    );
    if (target == null || !mounted) return;
    final targetName = target.isDefault
        ? ShortlistStrings.foldersDefaultName
        : target.name;
    final ids = store.selectedIds.toList();
    if (!mounted) return;
    await ShortlistConfirmModal.show(
      context,
      title: ShortlistStrings.bulkMoveTitle(ids.length, targetName),
      confirmLabel: ShortlistStrings.bulkMoveConfirm,
      onConfirm: () async {
        final result = await store.bulkMove(ids, target.id);
        if (!mounted) return;
        if (result.fail > 0) {
          TopToastUtil.showError(
            context: context,
            title: ShortlistStrings.bulkMovePartial(
              result.ok,
              ids.length,
              result.fail,
            ),
            description: '',
          );
        } else {
          TopToastUtil.showSuccess(
            context: context,
            title: ShortlistStrings.bulkMoveSuccess(result.ok, targetName),
            description: '',
          );
        }
        store.clearSelected();
      },
    );
  }

  Future<void> _handleExport(ShortlistExportFormat format) async {
    if (_isExporting) return;
    final store = context.read<ShortlistStore>();
    final projectId = store.activeProjectId;
    if (projectId == null) {
      TopToastUtil.showError(
        context: context,
        title: ShortlistStrings.exportNoFolder,
        description: '',
      );
      return;
    }

    setState(() => _isExporting = true);
    final service = ShortlistService();
    try {
      List<FavoriteItem> rows;
      if (store.selectedIds.isNotEmpty) {
        rows = store.favorites
            .where((item) => store.selectedIds.contains(item.id))
            .toList();
      } else {
        rows = [];
        for (var offset = 0; ; offset += shortlistExportPageSize) {
          final page = await service.listFavorites(
            projectId: projectId,
            name: store.nameQuery,
            status: store.statusFilter,
            limit: shortlistExportPageSize,
            offset: offset,
          );
          rows.addAll(page);
          if (page.length < shortlistExportPageSize) break;
        }
      }

      if (rows.isEmpty) {
        if (!mounted) return;
        TopToastUtil.showError(
          context: context,
          title: ShortlistStrings.exportEmpty,
          description: '',
        );
        return;
      }

      final folder = store.activeProject;
      final folderName = folder?.isDefault == true
          ? 'Default'
          : (folder?.name ?? 'shortlist');
      final date = DateTime.now().toIso8601String().substring(0, 10);
      final slug = service.safeFilenamePart(folderName);

      if (format == ShortlistExportFormat.pdf) {
        if (rows.length > shortlistMaxPdfExportRows) {
          if (!mounted) return;
          TopToastUtil.showError(
            context: context,
            title: ShortlistStrings.exportPdfLimit(shortlistMaxPdfExportRows),
            description: '',
          );
          return;
        }
        final result = await service.exportPdf(rows.map((r) => r.id).toList());
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/${result.filename}');
        await file.writeAsBytes(result.bytes);
        await Share.shareXFiles([XFile(file.path)], subject: result.filename);
      } else {
        final csv = service.buildCsvContent(rows);
        final dir = await getTemporaryDirectory();
        final filename = '$slug-$date.csv';
        final file = File('${dir.path}/$filename');
        await file.writeAsString(csv);
        await Share.shareXFiles([XFile(file.path)], subject: filename);
      }

      if (mounted) {
        TopToastUtil.showSuccess(
          context: context,
          title: ShortlistStrings.exportSuccess(rows.length),
          description: '',
        );
      }
    } catch (e) {
      if (mounted) {
        TopToastUtil.showError(
          context: context,
          title: ShortlistStrings.exportError,
          description: e.toString(),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _openExportSheet({bool selectedOnly = false}) async {
    if (_isExporting) return;
    if (selectedOnly) {
      final count = context.read<ShortlistStore>().selectedIds.length;
      if (count == 0) return;
    }
    await ShortlistExportModal.show(
      context,
      onSelect: (format) async {
        await _handleExport(format);
        if (!mounted) return;
        if (selectedOnly) {
          context.read<ShortlistStore>().exitSelectionMode();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ShortlistStore>();
    final enrichStore = context.watch<DeepSearchEnrichStore>();
    final waitingForProject =
        store.activeProjectId == null &&
        !store.projectsLoaded &&
        store.projectsLoadError == null;
    final hasSearchOrStatus =
        _searchQuery.isNotEmpty || store.statusFilter != null;
    final visibleIds = store.favorites.map((item) => item.id);
    final allVisibleSelected =
        visibleIds.isNotEmpty && visibleIds.every(store.selectedIds.contains);

    return Scaffold(
      backgroundColor: DinqTokens.bgPage,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                _ShortlistHeader(
                  selectionMode: store.selectionMode,
                  selectedCount: store.selectedIds.length,
                  folderName: store.activeProjectName,
                  isExporting: _isExporting,
                  allVisibleSelected: allVisibleSelected,
                  onFolderTap: () => showShortlistFoldersDrawer(context),
                  onExport: () => _openExportSheet(),
                  onEnterSelection: store.enterSelectionMode,
                  onCloseSelection: store.exitSelectionMode,
                  onToggleSelectAll: () =>
                      store.toggleSelectAllVisible(visibleIds),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Column(
                    children: [
                      _ShortlistSearchField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                      ),
                      const SizedBox(height: 12),
                      _ShortlistStatusPillFilter(
                        statusFilter: store.statusFilter,
                        onStatusChanged: (status) {
                          if (status == store.statusFilter) return;
                          store.setStatusFilter(status);
                          store.loadFavorites(clear: true);
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _buildBody(
                    store,
                    waitingForProject: waitingForProject,
                    hasSearchOrStatus: hasSearchOrStatus,
                  ),
                ),
              ],
            ),
            if (store.selectedIds.isNotEmpty)
              Positioned(
                left: 16,
                right: 16,
                bottom: 18,
                child: _ShortlistBatchBar(
                  onMove: _openMoveSheet,
                  onExport: () => _openExportSheet(selectedOnly: true),
                  onRemove: _openBulkDeleteConfirm,
                ),
              ),
            if (enrichStore.isOpen)
              _EnrichOverlay(
                entry: enrichStore.selectedEntry,
                selectedRowId: enrichStore.selectedRowId,
                confidencePct: enrichStore.confidenceFor(
                  enrichStore.selectedRowId,
                ),
                onClose: () {
                  _enrichController?.close();
                  _syncBottomNav();
                },
                onRefresh: () =>
                    _enrichController?.refreshEnrich() ?? Future.value(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    ShortlistStore store, {
    required bool waitingForProject,
    required bool hasSearchOrStatus,
  }) {
    if (waitingForProject) {
      return const _ShortlistLoadingState(
        label: ShortlistStrings.loadingFolders,
      );
    }
    if (store.activeProjectId == null && store.projectsLoadError != null) {
      return _FolderLoadErrorState(onRetry: store.loadProjects);
    }
    if (store.isLoading && store.favorites.isEmpty) {
      return _CardSkeletonList();
    }
    if (store.activeProjectId == null) {
      return _EmptyCenter(
        title: ShortlistStrings.emptyNoFoldersTitle,
        description: ShortlistStrings.emptyNoFoldersDescription,
      );
    }
    if (store.favorites.isEmpty) {
      if (hasSearchOrStatus) {
        return _EmptyCenter(
          title: ShortlistStrings.emptyNoMatchesTitle,
          description: ShortlistStrings.emptyNoMatchesDescription,
          actionLabel: ShortlistStrings.emptyNoMatchesReset,
          onAction: () {
            _searchController.clear();
            setState(() => _searchQuery = '');
            store.clearFilters();
            store.loadFavorites(clear: true);
          },
        );
      }
      return const _EmptyCenter(
        title: ShortlistStrings.emptyNoFavoritesTitle,
        description: ShortlistStrings.emptyNoFavoritesDescription,
      );
    }

    return ListView.separated(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        store.selectedIds.isEmpty ? 120 : 112,
      ),
      itemCount: store.favorites.length + (store.hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index >= store.favorites.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final item = store.favorites[index];
        return ShortlistCandidateCard(
          item: item,
          store: store,
          selectionMode: store.selectionMode,
          isSelected: store.selectedIds.contains(item.id),
          onTap: () => _handleRowClick(item),
          onLongPress: () {
            store.enterSelectionMode();
            store.toggleSelected(item.id);
          },
          onToggleSelect: () => store.toggleSelected(item.id),
        );
      },
    );
  }
}

class _ShortlistHeader extends StatelessWidget {
  const _ShortlistHeader({
    required this.selectionMode,
    required this.selectedCount,
    required this.folderName,
    required this.isExporting,
    required this.allVisibleSelected,
    required this.onFolderTap,
    required this.onExport,
    required this.onEnterSelection,
    required this.onCloseSelection,
    required this.onToggleSelectAll,
  });

  final bool selectionMode;
  final int selectedCount;
  final String folderName;
  final bool isExporting;
  final bool allVisibleSelected;
  final VoidCallback onFolderTap;
  final VoidCallback onExport;
  final VoidCallback onEnterSelection;
  final VoidCallback onCloseSelection;
  final VoidCallback onToggleSelectAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: selectionMode
                ? _ShortlistHeaderTextAction(
                    label: ShortlistStrings.selectionCancel,
                    onTap: onCloseSelection,
                  )
                : _ShortlistFolderPill(
                    folderName: folderName,
                    onTap: onFolderTap,
                  ),
          ),
          if (selectionMode)
            Text(
              ShortlistStrings.selectionCount(selectedCount),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                height: 22 / 17,
                fontWeight: FontWeight.w600,
                color: DinqTokens.textPrimary,
              ),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: selectionMode
                  ? _ShortlistHeaderTextAction(
                      label: allVisibleSelected
                          ? ShortlistStrings.selectionDeselectAll
                          : ShortlistStrings.selectionSelectAll,
                      onTap: onToggleSelectAll,
                      color: allVisibleSelected
                          ? const Color(0xFFE24B3C)
                          : const Color(0xFF2563EB),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ShortlistHeaderIconButton(
                          iconAsset: DinqIcons.download,
                          onTap: isExporting ? null : onExport,
                        ),
                        const SizedBox(width: 8),
                        _ShortlistHeaderIconButton(
                          iconAsset: DinqIcons.listTodo,
                          onTap: onEnterSelection,
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

class _ShortlistHeaderIconButton extends StatelessWidget {
  const _ShortlistHeaderIconButton({
    required this.iconAsset,
    required this.onTap,
  });

  final String iconAsset;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 42,
        width: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: DinqTokens.bgCard,
          borderRadius: BorderRadius.circular(999),
          boxShadow: const [
            BoxShadow(
              color: DinqTokens.shadow,
              blurRadius: 16,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: DinqSvgIcon(
          assetName: iconAsset,
          size: 18,
          color: DinqTokens.textPrimary,
        ),
      ),
    );
  }
}

class _ShortlistHeaderTextAction extends StatelessWidget {
  const _ShortlistHeaderTextAction({
    required this.label,
    required this.onTap,
    this.color = const Color(0xFF2563EB),
  });

  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 14,
            height: 18 / 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ShortlistFolderPill extends StatelessWidget {
  const _ShortlistFolderPill({required this.folderName, required this.onTap});

  final String folderName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 188),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 42,
          padding: const EdgeInsets.fromLTRB(14, 0, 13, 0),
          decoration: BoxDecoration(
            color: DinqTokens.bgCard,
            borderRadius: BorderRadius.circular(999),
            boxShadow: const [
              BoxShadow(
                color: DinqTokens.shadow,
                blurRadius: 16,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.folder_outlined,
                size: 19,
                color: DinqTokens.textPrimary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  folderName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: DinqTokens.textPrimary,
                    fontSize: 14,
                    height: 18 / 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const DinqSvgIcon(
                assetName: DinqIcons.caretDown,
                size: 14,
                color: DinqTokens.textPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShortlistSearchField extends StatelessWidget {
  const _ShortlistSearchField({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: DinqTokens.bgCard,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const DinqSvgIcon(
            assetName: DinqIcons.searchShortlist,
            size: 18,
            color: DinqTokens.textTertiary,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: const InputDecoration(
                hintText: ShortlistStrings.searchPlaceholder,
                hintStyle: TextStyle(
                  color: DinqTokens.textTertiary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
              ),
              style: const TextStyle(
                color: DinqTokens.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShortlistStatusPillFilter extends StatelessWidget {
  const _ShortlistStatusPillFilter({
    required this.statusFilter,
    required this.onStatusChanged,
  });

  final String? statusFilter;
  final ValueChanged<String?> onStatusChanged;

  static const _options = <String?>[null, ...favoriteStatuses];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final option = _options[index];
          final label = option == null
              ? ShortlistStrings.statusAll
              : ShortlistStrings.statusLabelFor(option);
          final selected = option == statusFilter;
          return _ShortlistStatusChoicePill(
            label: label,
            selected: selected,
            onTap: () => onStatusChanged(option),
          );
        },
      ),
    );
  }
}

class _ShortlistStatusChoicePill extends StatelessWidget {
  const _ShortlistStatusChoicePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = selected
        ? const Color(0xFF2563EB)
        : DinqTokens.textPrimary;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 40,
        constraints: const BoxConstraints(minWidth: 60),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEAF1FF) : DinqTokens.bgCard,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? Colors.transparent : DinqTokens.borderL,
            width: 0.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: DinqTokens.shadow,
              blurRadius: 16,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: textColor,
            fontSize: 13,
            height: 18 / 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _ShortlistBatchBar extends StatelessWidget {
  const _ShortlistBatchBar({
    required this.onMove,
    required this.onExport,
    required this.onRemove,
  });

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
            child: _ShortlistBatchButton(
              label: ShortlistStrings.selectionMove,
              icon: Icons.drive_file_move_outlined,
              onTap: onMove,
            ),
          ),
          Expanded(
            child: _ShortlistBatchButton(
              label: ShortlistStrings.exportLabel,
              icon: Icons.download_outlined,
              onTap: onExport,
            ),
          ),
          Expanded(
            child: _ShortlistBatchButton(
              label: ShortlistStrings.cardRemove,
              icon: Icons.delete_outline_rounded,
              onTap: onRemove,
              color: const Color(0xFFFF7A66),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShortlistBatchButton extends StatelessWidget {
  const _ShortlistBatchButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.color = const Color(0xFFE7E5E1),
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShortlistLoadingState extends StatelessWidget {
  const _ShortlistLoadingState({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Color(0xFF8A8880)),
          ),
        ],
      ),
    );
  }
}

class _FolderLoadErrorState extends StatelessWidget {
  const _FolderLoadErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            ShortlistStrings.loadFoldersTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF171717),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            ShortlistStrings.loadFoldersDescription,
            style: const TextStyle(fontSize: 14, color: Color(0xFF8A8880)),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onRetry,
            child: Text(ShortlistStrings.loadFoldersRetry),
          ),
        ],
      ),
    );
  }
}

class _EmptyCenter extends StatelessWidget {
  const _EmptyCenter({
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF171717),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF8A8880)),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class _CardSkeletonList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => Container(
        height: 180,
        decoration: BoxDecoration(
          color: DinqTokens.bgCard,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFEAE6E0), width: 0.5),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 20,
              width: 180,
              decoration: BoxDecoration(
                color: const Color(0xFFF0EFE9),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 14,
              width: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFF0EFE9),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const Spacer(),
            Container(
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFF0EFE9),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EnrichOverlay extends StatelessWidget {
  const _EnrichOverlay({
    required this.entry,
    required this.selectedRowId,
    required this.confidencePct,
    required this.onClose,
    required this.onRefresh,
  });

  final EnrichEntry? entry;
  final String? selectedRowId;
  final int? confidencePct;
  final VoidCallback onClose;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Positioned.fill(
      child: Material(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFEAE8E3))),
              ),
              child: SizedBox(
                height: 48,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: onClose,
                      icon: const Icon(Icons.arrow_back, size: 20),
                      color: const Color(0xFF171717),
                      tooltip: 'Back',
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: entry == null
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        24,
                        16,
                        24 + bottomPadding,
                      ),
                      child: EnrichProfileView(
                        entry: entry!,
                        isMobile: true,
                        selectedRowId: selectedRowId,
                        confidencePct: confidencePct,
                        onRefresh: onRefresh,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
