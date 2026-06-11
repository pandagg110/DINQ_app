import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../models/shortlist_models.dart';
import '../../stores/shortlist_store.dart';
import '../../stores/user_store.dart';
import '../../theme/dinq_icons.dart';
import '../../theme/dinq_tokens.dart';
import '../../widgets/common/dinq_svg_icon.dart';
import 'candidate_detail_page.dart';

/// Shortlist Tab（存人 / 候选人库）。
/// 1:1 还原 `my_first_app` 的 `_ShortlistPage`，接线上 `/favorite-projects` + `/favorites`。
class ShortlistPage extends StatefulWidget {
  const ShortlistPage({super.key});

  @override
  State<ShortlistPage> createState() => _ShortlistPageState();
}

class _ShortlistPageState extends State<ShortlistPage> {
  bool _selectionMode = false;
  final Set<String> _selectedIds = <String>{};

  @override
  void initState() {
    super.initState();
    _loadWhenReady();
  }

  /// 轮询等待登录态就绪后再加载。
  /// UserStore 启动时异步读取 token 并注入 ApiClient；其 initialize() 若因
  /// 个别接口异常而未 notify，也不影响——这里只依赖 isLoggedIn()（token 已就绪）。
  Future<void> _loadWhenReady() async {
    for (int i = 0; i < 25; i++) {
      if (!mounted) return;
      if (context.read<UserStore>().isLoggedIn()) {
        await context.read<ShortlistStore>().load();
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
  }

  void _exitSelection() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  Future<void> _removeSelected() async {
    final ids = Set<String>.from(_selectedIds);
    if (ids.isEmpty) return;
    final store = context.read<ShortlistStore>();
    _exitSelection();
    await store.removeFavorites(ids);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ShortlistStore>();
    const double s = 1;
    final items = store.visibleItems;
    final visibleIds = items.map((e) => e.id).toSet();
    final allSelected =
        visibleIds.isNotEmpty && visibleIds.every(_selectedIds.contains);

    return Scaffold(
      backgroundColor: DinqTokens.bgPage,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                _Header(
                  scale: s,
                  selectionMode: _selectionMode,
                  selectedCount: _selectedIds.length,
                  folderName: store.selectedFolderName,
                  allSelected: allSelected,
                  onFolderTap: () => _openFolderSheet(store),
                  onEnterSelection: () => setState(() => _selectionMode = true),
                  onCloseSelection: _exitSelection,
                  onToggleSelectAll: () {
                    setState(() {
                      if (allSelected) {
                        _selectedIds.removeAll(visibleIds);
                      } else {
                        _selectedIds.addAll(visibleIds);
                      }
                    });
                  },
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(16 * s, 12 * s, 16 * s, 12 * s),
                  child: Column(
                    children: [
                      _SearchField(
                        scale: s,
                        onChanged: store.setQuery,
                      ),
                      SizedBox(height: 12 * s),
                      _StatusFilter(
                        scale: s,
                        options: ShortlistStore.statusOptions,
                        selected: store.selectedStatus,
                        onSelected: store.selectStatus,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _body(store, items, s),
                ),
              ],
            ),
            if (_selectedIds.isNotEmpty)
              Positioned(
                left: 16 * s,
                right: 16 * s,
                bottom: 18 * s,
                child: _BatchBar(scale: s, onRemove: _removeSelected),
              ),
          ],
        ),
      ),
    );
  }

  Widget _body(ShortlistStore store, List<FavoriteItem> items, double s) {
    if (store.loading && store.projects.isEmpty) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (store.error != null && store.projects.isEmpty) {
      return _ErrorState(message: store.error!, onRetry: store.load);
    }
    if (items.isEmpty) {
      return const _EmptyState();
    }
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        16 * s,
        0,
        16 * s,
        // 底部留白需清开 dev 的悬浮底栏（约 110）。
        (_selectedIds.isEmpty ? 110 : 160) * s,
      ),
      children: [
        for (final item in items) ...[
          _CandidateCard(
            scale: s,
            item: item,
            selectionMode: _selectionMode,
            selected: _selectedIds.contains(item.id),
            onTap: () {
              if (_selectionMode) {
                setState(() {
                  if (!_selectedIds.add(item.id)) _selectedIds.remove(item.id);
                });
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CandidateDetailPage(item: item),
                  ),
                );
              }
            },
            onLongPress: () {
              setState(() {
                _selectionMode = true;
                _selectedIds.add(item.id);
              });
            },
          ),
          SizedBox(height: 12 * s),
        ],
      ],
    );
  }

  Future<void> _openFolderSheet(ShortlistStore store) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.28),
      builder: (_) => _FolderSheet(
        projects: store.projects,
        selectedId: store.selectedProject?.id,
      ),
    );
    if (selected != null) store.selectProject(selected);
  }
}

// ───────────────────────── Header ─────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.scale,
    required this.selectionMode,
    required this.selectedCount,
    required this.folderName,
    required this.allSelected,
    required this.onFolderTap,
    required this.onEnterSelection,
    required this.onCloseSelection,
    required this.onToggleSelectAll,
  });

  final double scale;
  final bool selectionMode;
  final int selectedCount;
  final String folderName;
  final bool allSelected;
  final VoidCallback onFolderTap;
  final VoidCallback onEnterSelection;
  final VoidCallback onCloseSelection;
  final VoidCallback onToggleSelectAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16 * scale, 18 * scale, 16 * scale, 0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: selectionMode
                ? _TextButton(
                    scale: scale, label: 'Cancel', onTap: onCloseSelection)
                : _FolderPill(
                    scale: scale, folderName: folderName, onTap: onFolderTap),
          ),
          if (selectionMode)
            Text(
              '$selectedCount selected',
              style: TextStyle(
                fontSize: 17 * scale,
                fontWeight: FontWeight.w600,
                color: DinqTokens.textPrimary,
              ),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: selectionMode
                ? _TextButton(
                    scale: scale,
                    label: allSelected ? 'Deselect all' : 'Select all',
                    onTap: onToggleSelectAll,
                    color: allSelected
                        ? const Color(0xFFE24B3C)
                        : const Color(0xFF2563EB),
                    plain: true,
                  )
                : _TextButton(
                    scale: scale,
                    label: 'Select',
                    onTap: onEnterSelection,
                    color: const Color(0xFF2563EB),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TextButton extends StatelessWidget {
  const _TextButton({
    required this.scale,
    required this.label,
    required this.onTap,
    this.color = const Color(0xFF2563EB),
    this.plain = false,
  });

  final double scale;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final bool plain;

  @override
  Widget build(BuildContext context) {
    if (plain) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4 * scale, vertical: 9 * scale),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 14 * scale,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 42 * scale,
        padding: EdgeInsets.symmetric(horizontal: 18 * scale),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: DinqTokens.bgCard,
          borderRadius: BorderRadius.circular(999 * scale),
          boxShadow: [
            BoxShadow(
              color: DinqTokens.shadow,
              blurRadius: 16 * scale,
              offset: Offset(0, 1 * scale),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 14 * scale,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _FolderPill extends StatelessWidget {
  const _FolderPill({
    required this.scale,
    required this.folderName,
    required this.onTap,
  });

  final double scale;
  final String folderName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 188 * scale),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 42 * scale,
          padding: EdgeInsets.fromLTRB(14 * scale, 0, 13 * scale, 0),
          decoration: BoxDecoration(
            color: DinqTokens.bgCard,
            borderRadius: BorderRadius.circular(999 * scale),
            boxShadow: [
              BoxShadow(
                color: DinqTokens.shadow,
                blurRadius: 16 * scale,
                offset: Offset(0, 1 * scale),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.folder_outlined,
                  size: 19 * scale, color: DinqTokens.textPrimary),
              SizedBox(width: 8 * scale),
              Flexible(
                child: Text(
                  folderName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: DinqTokens.textPrimary,
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: 8 * scale),
              DinqSvgIcon(
                assetName: DinqIcons.caretDown,
                size: 14 * scale,
                color: DinqTokens.textPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Search + Filter ─────────────────────────

class _SearchField extends StatelessWidget {
  const _SearchField({required this.scale, required this.onChanged});

  final double scale;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40 * scale,
      padding: EdgeInsets.symmetric(horizontal: 12 * scale),
      decoration: BoxDecoration(
        color: DinqTokens.bgCard,
        borderRadius: BorderRadius.circular(12 * scale),
      ),
      child: Row(
        children: [
          DinqSvgIcon(
            assetName: DinqIcons.searchShortlist,
            size: 18 * scale,
            color: DinqTokens.textTertiary,
          ),
          SizedBox(width: 14 * scale),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: 'Search keyword (fuzzy)',
                hintStyle: TextStyle(
                  color: DinqTokens.textTertiary,
                  fontSize: 14 * scale,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
              style: TextStyle(
                color: DinqTokens.textPrimary,
                fontSize: 14 * scale,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusFilter extends StatelessWidget {
  const _StatusFilter({
    required this.scale,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final double scale;
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40 * scale,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: options.length,
        separatorBuilder: (context, index) => SizedBox(width: 10 * scale),
        itemBuilder: (context, i) {
          final option = options[i];
          final sel = option == selected;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onSelected(option),
            child: Container(
              height: 40 * scale,
              constraints: BoxConstraints(minWidth: 60 * scale),
              padding: EdgeInsets.symmetric(horizontal: 18 * scale),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: sel ? const Color(0xFFEAF1FF) : DinqTokens.bgCard,
                borderRadius: BorderRadius.circular(999 * scale),
                border: Border.all(
                  color: sel ? Colors.transparent : DinqTokens.borderL,
                  width: 0.5 * scale,
                ),
                boxShadow: [
                  BoxShadow(
                    color: DinqTokens.shadow,
                    blurRadius: 16 * scale,
                    offset: Offset(0, 1 * scale),
                  ),
                ],
              ),
              child: Text(
                option,
                style: TextStyle(
                  color: sel ? const Color(0xFF2563EB) : DinqTokens.textPrimary,
                  fontSize: 13 * scale,
                  fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ───────────────────────── Candidate Card ─────────────────────────

const List<Color> _avatarPalette = [
  Color(0xFFECD9AC),
  Color(0xFFF4D7C4),
  Color(0xFFF2D7B6),
  Color(0xFFEED0D6),
  Color(0xFFD9E4CF),
  Color(0xFFD8DDF2),
  Color(0xFFD4E8E1),
  Color(0xFFE5D8EF),
];

Color _avatarColorFor(String seed) {
  final int h = seed.codeUnits.fold<int>(0, (a, c) => a + c);
  return _avatarPalette[h % _avatarPalette.length];
}

Color _statusColor(String label) {
  switch (label) {
    case 'Email obtained':
      return const Color(0xFFB7B4AE);
    case 'Contacted':
      return const Color(0xFF6E9B72);
    default:
      return const Color(0xFFD6D3CE);
  }
}

List<String> _socialIconsFor(String seed) {
  final int offset = seed.codeUnits.fold<int>(0, (a, c) => a + c);
  final pool = DinqIcons.shortlistSocialPool;
  return List<String>.generate(
    5,
    (i) => pool[(offset + i * 3) % pool.length],
    growable: false,
  );
}

class _CandidateCard extends StatelessWidget {
  const _CandidateCard({
    required this.scale,
    required this.item,
    required this.selectionMode,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  final double scale;
  final FavoriteItem item;
  final bool selectionMode;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final double avatarSize = 68 * scale;
    final socials = _socialIconsFor(item.id);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: EdgeInsets.fromLTRB(20 * scale, 20 * scale, 20 * scale, 18 * scale),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF7FAFF) : DinqTokens.bgCard,
          borderRadius: BorderRadius.circular(22 * scale),
          border: Border.all(
            color: selected ? const Color(0xFF2F6FED) : const Color(0xFFEAE6E0),
            width: selected ? 1 * scale : 0.5 * scale,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (selectionMode) ...[
                  Padding(
                    padding: EdgeInsets.only(right: 12 * scale, top: 4 * scale),
                    child: _Checkbox(scale: scale, selected: selected),
                  ),
                ],
                Container(
                  width: avatarSize,
                  height: avatarSize,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _avatarColorFor(item.id),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    item.initials,
                    style: TextStyle(
                      color: DinqTokens.textPrimary,
                      fontSize: 24 * scale,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(width: 18 * scale),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: DinqTokens.textPrimary,
                                fontSize: 15 * scale,
                                height: 20 / 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(width: 8 * scale),
                          _StatusPill(scale: scale, label: item.statusLabel),
                        ],
                      ),
                      SizedBox(height: 4 * scale),
                      Text(
                        item.roleLine,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: DinqTokens.textSecondary,
                          fontSize: 12 * scale,
                          height: 18 / 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 18 * scale),
            Row(
              children: [
                for (int i = 0; i < socials.length; i++) ...[
                  if (i > 0) SizedBox(width: 8 * scale),
                  SizedBox(
                    width: 24 * scale,
                    height: 24 * scale,
                    child: Center(
                      child: SvgPicture.asset(
                        socials[i],
                        width: 24 * scale,
                        height: 24 * scale,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.scale, required this.label});

  final double scale;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(label);
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 120 * scale),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6 * scale,
            height: 6 * scale,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: 7 * scale),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 12 * scale,
                height: 16 / 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Checkbox extends StatelessWidget {
  const _Checkbox({required this.scale, required this.selected});

  final double scale;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      width: 20 * scale,
      height: 20 * scale,
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF2F6FED) : DinqTokens.bgCard,
        borderRadius: BorderRadius.circular(6 * scale),
        border: Border.all(
          color: selected ? const Color(0xFF2F6FED) : const Color(0xFFD7D2CA),
          width: selected ? 0.5 * scale : 1 * scale,
        ),
      ),
      child: selected
          ? Icon(Icons.check_rounded, size: 14 * scale, color: DinqTokens.bgCard)
          : null,
    );
  }
}

// ───────────────────────── Batch bar / states ─────────────────────────

class _BatchBar extends StatelessWidget {
  const _BatchBar({required this.scale, required this.onRemove});

  final double scale;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60 * scale,
      padding: EdgeInsets.symmetric(horizontal: 8 * scale),
      decoration: BoxDecoration(
        color: DinqTokens.bgCard,
        borderRadius: BorderRadius.circular(18 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24 * scale,
            offset: Offset(0, 6 * scale),
          ),
        ],
        border: Border.all(color: DinqTokens.borderL, width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _batchAction(Icons.drive_file_move_outline, 'Move', () {}),
          _batchAction(Icons.ios_share, 'Export', () {}),
          _batchAction(Icons.delete_outline, 'Remove', onRemove,
              color: const Color(0xFFE24B3C)),
        ],
      ),
    );
  }

  Widget _batchAction(IconData icon, String label, VoidCallback onTap,
      {Color color = const Color(0xFF171717)}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20 * scale, color: color),
          SizedBox(height: 2 * scale),
          Text(label,
              style: TextStyle(
                  fontSize: 11 * scale, fontWeight: FontWeight.w500, color: color)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No candidates yet',
        style: TextStyle(
          fontSize: 14,
          color: DinqTokens.textTertiary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, color: DinqTokens.textTertiary),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: DinqTokens.textTertiary),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

// ───────────────────────── Folder sheet ─────────────────────────

class _FolderSheet extends StatelessWidget {
  const _FolderSheet({required this.projects, required this.selectedId});

  final List<FavoriteProject> projects;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: DinqTokens.bgPage,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: DinqTokens.borderL,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text('Folders',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: DinqTokens.textPrimary)),
            ),
            for (final p in projects)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: const Icon(Icons.folder_outlined,
                    color: DinqTokens.textPrimary),
                title: Text(p.name,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: DinqTokens.textPrimary)),
                trailing: Text('${p.talentCount}',
                    style: const TextStyle(
                        color: DinqTokens.textTertiary, fontSize: 14)),
                selected: p.id == selectedId,
                onTap: () => Navigator.of(context).pop(p.id),
              ),
          ],
        ),
      ),
    );
  }
}
