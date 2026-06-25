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

/// Shortlist Tab — 严格对齐 Web `(workspace)/shortlist/page.tsx` 移动端。
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
    if (store.selectionActive) {
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
      final folderName =
          folder?.isDefault == true ? 'Default' : (folder?.name ?? 'shortlist');
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

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ShortlistStore>();
    final enrichStore = context.watch<DeepSearchEnrichStore>();
    final waitingForProject =
        store.activeProjectId == null && !store.projectsLoaded && store.projectsLoadError == null;
    final hasSearchOrStatus =
        _searchQuery.isNotEmpty || store.statusFilter != null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                _TopBar(
                  isExporting: _isExporting,
                  onOpenFolders: () => showShortlistFoldersDrawer(context),
                  onExport: () => ShortlistExportModal.show(
                    context,
                    onSelect: _handleExport,
                  ),
                ),
                _Toolbar(
                  searchController: _searchController,
                  onSearchChanged: _onSearchChanged,
                  statusFilter: store.statusFilter,
                  onStatusChanged: (status) {
                    if (status == store.statusFilter) return;
                    store.setStatusFilter(status);
                    store.loadFavorites(clear: true);
                  },
                ),
                if (store.selectionActive)
                  _SelectionBar(
                    count: store.selectedIds.length,
                    onCancel: store.clearSelected,
                    onDelete: _openBulkDeleteConfirm,
                    onMove: _openMoveSheet,
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
            if (enrichStore.isOpen)
              _EnrichOverlay(
                entry: enrichStore.selectedEntry,
                selectedRowId: enrichStore.selectedRowId,
                confidencePct:
                    enrichStore.confidenceFor(enrichStore.selectedRowId),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      itemCount: store.favorites.length + (store.hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 16),
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
          isSelected: store.selectedIds.contains(item.id),
          onTap: () => _handleRowClick(item),
          onToggleSelect: () => store.toggleSelected(item.id),
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.isExporting,
    required this.onOpenFolders,
    required this.onExport,
  });

  final bool isExporting;
  final VoidCallback onOpenFolders;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Text(
            ShortlistStrings.headerTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF171717),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onOpenFolders,
              borderRadius: BorderRadius.circular(8),
              child: const SizedBox(
                width: 36,
                height: 36,
                child: Icon(
                  Icons.folder_open_outlined,
                  size: 16,
                  color: Color(0xFF171717),
                ),
              ),
            ),
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: isExporting ? null : onExport,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 32),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              side: const BorderSide(color: Color(0xFFF0EFEB)),
              foregroundColor: const Color(0xFF171717),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.download_outlined, size: 16),
            label: Text(
              isExporting
                  ? ShortlistStrings.exportingLabel
                  : ShortlistStrings.exportLabel,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.searchController,
    required this.onSearchChanged,
    required this.statusFilter,
    required this.onStatusChanged,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final String? statusFilter;
  final ValueChanged<String?> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: [
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E3DE)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                DinqSvgIcon(
                  assetName: DinqIcons.searchShortlist,
                  size: 16,
                  color: const Color(0xFFB5B3AE),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: searchController,
                    onChanged: onSearchChanged,
                    decoration: const InputDecoration(
                      hintText: ShortlistStrings.searchPlaceholder,
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: Color(0xFFB5B3AE),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF171717),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _StatusDropdown(
            statusFilter: statusFilter,
            onStatusChanged: onStatusChanged,
          ),
        ],
      ),
    );
  }
}

class _StatusDropdown extends StatelessWidget {
  const _StatusDropdown({
    required this.statusFilter,
    required this.onStatusChanged,
  });

  /// 与「取消/点遮罩关闭」区分；点选 All 时 pop 此值。
  static const _allSentinel = '__shortlist_status_all__';

  final String? statusFilter;
  final ValueChanged<String?> onStatusChanged;

  String get _label => statusFilter == null
      ? ShortlistStrings.statusAll
      : ShortlistStrings.statusLabelFor(statusFilter!);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () async {
          final picked = await showModalBottomSheet<String>(
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
                    title: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFD5D3CE),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(ShortlistStrings.statusAll),
                      ],
                    ),
                    onTap: () => Navigator.pop(ctx, _allSentinel),
                  ),
                  const Divider(height: 1),
                  for (final status in favoriteStatuses)
                    ListTile(
                      title: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: favoriteStatusColors[status]!.dot,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(ShortlistStrings.statusLabelFor(status)),
                        ],
                      ),
                      onTap: () => Navigator.pop(ctx, status),
                    ),
                ],
              ),
            ),
          );
          // 点遮罩/下滑关闭时 picked == null，不应触发筛选或重新加载。
          if (picked == null) return;
          final next = picked == _allSentinel ? null : picked;
          onStatusChanged(next);
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFF0EFEB)),
          ),
          child: Row(
            children: [
              Text(
                ShortlistStrings.statusLabel,
                style: const TextStyle(fontSize: 14, color: Color(0xFF8A8880)),
              ),
              const Spacer(),
              Text(
                _label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF171717),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.keyboard_arrow_down,
                size: 14,
                color: Color(0xFF8A8880),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionBar extends StatelessWidget {
  const _SelectionBar({
    required this.count,
    required this.onCancel,
    required this.onDelete,
    required this.onMove,
  });

  final int count;
  final VoidCallback onCancel;
  final VoidCallback onDelete;
  final VoidCallback onMove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            ShortlistStrings.selectionCount(count),
            style: const TextStyle(fontSize: 14, color: Color(0xFF6B6962)),
          ),
          OutlinedButton(
            onPressed: onCancel,
            style: _outlinedStyle(const Color(0xFF6B6962)),
            child: Text(ShortlistStrings.selectionCancel),
          ),
          OutlinedButton(
            onPressed: onDelete,
            style: _outlinedStyle(const Color(0xFFA04444))
                .copyWith(side: WidgetStateProperty.all(
              const BorderSide(color: Color(0xFFE9C6C6)),
            )),
            child: Text(ShortlistStrings.selectionDelete),
          ),
          OutlinedButton.icon(
            onPressed: onMove,
            style: _outlinedStyle(const Color(0xFF171717)),
            icon: const Icon(Icons.folder_open_outlined, size: 14),
            label: Text(ShortlistStrings.selectionMove),
          ),
        ],
      ),
    );
  }

  ButtonStyle _outlinedStyle(Color color) {
    return OutlinedButton.styleFrom(
      minimumSize: const Size(0, 36),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      foregroundColor: color,
      side: const BorderSide(color: Color(0xFFF0EFEB)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, __) => Container(
        height: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEAE8E3)),
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
    return Positioned.fill(
      child: GestureDetector(
        onTap: onClose,
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.4),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: () {},
              child: FractionallySizedBox(
                widthFactor: 1,
                heightFactor: 0.85,
                child: Material(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: entry == null
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                          child: EnrichProfileView(
                            entry: entry!,
                            isMobile: true,
                            selectedRowId: selectedRowId,
                            confidencePct: confidencePct,
                            onRefresh: onRefresh,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
