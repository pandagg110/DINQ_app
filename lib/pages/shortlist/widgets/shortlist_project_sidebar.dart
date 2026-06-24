import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../constants/shortlist_constants.dart';
import '../../../models/shortlist_models.dart';
import '../../../stores/shortlist_store.dart';
import '../../../stores/user_store.dart';
import '../../../utils/top_toast_util.dart';
import '../shortlist_strings.dart';

/// 对齐 Web `ProjectSidebar.tsx`。
class ShortlistProjectSidebar extends StatefulWidget {
  const ShortlistProjectSidebar({
    super.key,
    this.variant = ShortlistProjectSidebarVariant.desktop,
    this.onSelectProject,
  });

  final ShortlistProjectSidebarVariant variant;
  final ValueChanged<String>? onSelectProject;

  @override
  State<ShortlistProjectSidebar> createState() =>
      _ShortlistProjectSidebarState();
}

enum ShortlistProjectSidebarVariant { desktop, mobile }

class _ShortlistProjectSidebarState extends State<ShortlistProjectSidebar> {
  String? _editingId;
  String _editingValue = '';
  String? _deletingId;
  bool _creating = false;
  String _creatingValue = '';
  bool _creatingSubmitting = false;
  String? _busyId;
  final _createFocus = FocusNode();
  final _editFocus = FocusNode();
  final _editController = TextEditingController();

  @override
  void dispose() {
    _createFocus.dispose();
    _editFocus.dispose();
    _editController.dispose();
    super.dispose();
  }

  String _displayName(FavoriteProject project) =>
      project.isDefault
          ? ShortlistStrings.projectDefaultProject
          : project.name;

  String _formatCount(int count) => count > 999 ? '999+' : '$count';

  Future<void> _startCreate(ShortlistStore store) async {
    if (!store.projectsLoaded && !store.projectsLoading) {
      await store.loadProjects();
    }
    if (!store.projectsLoaded || !mounted) return;
    final plan = context.read<UserStore>().subscription?.plan;
    if (isShortlistProjectLimitReached(store.projects.length, plan)) {
      // Pricing modal not wired on mobile yet — show toast.
      TopToastUtil.showError(
        context: context,
        title: 'Upgrade required',
        description: 'Folder limit reached for your plan.',
      );
      return;
    }
    setState(() {
      _creating = true;
      _creatingValue = '';
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _createFocus.requestFocus();
    });
  }

  Future<void> _submitCreate(ShortlistStore store) async {
    if (_creatingSubmitting) return;
    final name = _creatingValue.trim();
    if (name.isEmpty) {
      setState(() => _creating = false);
      return;
    }
    setState(() => _creatingSubmitting = true);
    final created = await store.createProject(name);
    if (!mounted) return;
    setState(() {
      _creating = false;
      _creatingValue = '';
      _creatingSubmitting = false;
    });
    if (created != null) {
      TopToastUtil.showSuccess(
        context: context,
        title: ShortlistStrings.projectCreated,
        description: created.name,
      );
      await store.loadFavorites(clear: true);
    }
  }

  Future<void> _submitRename(ShortlistStore store, String id, String original) async {
    final name = _editController.text.trim();
    if (name.isEmpty || name == original) {
      setState(() => _editingId = null);
      return;
    }
    final ok = await store.renameProject(id, name);
    if (!mounted) return;
    if (ok) {
      setState(() => _editingId = null);
      TopToastUtil.showSuccess(
        context: context,
        title: ShortlistStrings.projectRenamed,
        description: name,
      );
    }
  }

  Future<void> _submitDelete(ShortlistStore store, String id) async {
    setState(() => _busyId = id);
    final ok = await store.deleteProject(id);
    if (!mounted) return;
    setState(() {
      _busyId = null;
      if (ok) _deletingId = null;
    });
    if (ok) {
      TopToastUtil.showSuccess(
        context: context,
        title: ShortlistStrings.projectDeleted,
        description: '',
      );
      await store.loadFavorites(clear: true);
    }
  }

  void _handleSelect(ShortlistStore store, String id) {
    if (store.activeProjectId != id) {
      store.setActiveProjectId(id);
      store.loadFavorites(clear: true);
    }
    widget.onSelectProject?.call(id);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ShortlistStore>();
    final isMobile = widget.variant == ShortlistProjectSidebarVariant.mobile;

    return Container(
      width: isMobile ? double.infinity : 208,
      decoration: BoxDecoration(
        color: Colors.white,
        border: isMobile
            ? null
            : const Border(
                right: BorderSide(color: Color(0xFFEAE8E3)),
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(isMobile ? 16 : 12, isMobile ? 16 : 0, isMobile ? 16 : 12, isMobile ? 12 : 0),
            child: SizedBox(
              height: isMobile ? null : 64,
              child: Center(
                child: OutlinedButton.icon(
                  onPressed: store.projectsLoading
                      ? null
                      : () => _startCreate(store),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 40),
                    side: const BorderSide(
                      color: Color(0xFFD4D2CC),
                      style: BorderStyle.solid,
                    ),
                    foregroundColor: const Color(0xFF6B6962),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(
                    ShortlistStrings.projectCreateFolder,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              children: [
                if (!store.projectsLoaded && store.projectsLoading)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      ShortlistStrings.projectLoading,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFB5B3AE),
                      ),
                    ),
                  ),
                if (!store.projectsLoaded &&
                    store.projectsLoadError != null &&
                    !store.projectsLoading)
                  TextButton(
                    onPressed: store.loadProjects,
                    child: Text(ShortlistStrings.projectRetryLoad),
                  ),
                for (final project in store.sortedProjects)
                  _buildProjectRow(store, project, isMobile),
                if (_creating) _buildCreateInput(store),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectRow(
    ShortlistStore store,
    FavoriteProject project,
    bool isMobile,
  ) {
    final isActive = store.activeProjectId == project.id;
    final isEditing = _editingId == project.id;
    final isDeleting = _deletingId == project.id;
    final displayName = _displayName(project);

    if (isEditing) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: TextField(
          focusNode: _editFocus,
          controller: _editController,
          onSubmitted: (_) => _submitRename(store, project.id, project.name),
          onEditingComplete: () =>
              _submitRename(store, project.id, project.name),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFC0C0C0)),
            ),
          ),
          style: const TextStyle(fontSize: 14),
        ),
      );
    }

    if (isDeleting) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFDF2F2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                ShortlistStrings.projectDeleteConfirm(displayName),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFA04444),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              onPressed: _busyId == project.id
                  ? null
                  : () => _submitDelete(store, project.id),
              icon: const Icon(Icons.check, size: 14, color: Color(0xFFA04444)),
              tooltip: ShortlistStrings.projectConfirmDelete,
            ),
            IconButton(
              onPressed: () => setState(() => _deletingId = null),
              icon: const Icon(Icons.close, size: 14, color: Color(0xFF8A8880)),
              tooltip: ShortlistStrings.projectCancel,
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFF6F4F0) : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _handleSelect(store, project.id),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        isActive ? Icons.folder : Icons.folder_outlined,
                        size: 16,
                        color: isActive
                            ? const Color(0xFF171717)
                            : const Color(0xFFB5B3AE),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          displayName,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                isActive ? FontWeight.w500 : FontWeight.w400,
                            color: isActive
                                ? const Color(0xFF171717)
                                : const Color(0xFF6B6962),
                          ),
                        ),
                      ),
                      Text(
                        _formatCount(project.talentCount),
                        style: TextStyle(
                          fontSize: 12,
                          color: isActive
                              ? const Color(0xFF6B6962)
                              : const Color(0xFFB5B3AE),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (!project.isDefault)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz, size: 16, color: Color(0xFF8A8880)),
              tooltip: ShortlistStrings.projectMoreActions(displayName),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'rename',
                  child: Row(
                    children: [
                      const Icon(Icons.edit_outlined, size: 14, color: Color(0xFF8A8880)),
                      const SizedBox(width: 8),
                      Text(ShortlistStrings.projectRename),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_outline, size: 14, color: Color(0xFFA04444)),
                      const SizedBox(width: 8),
                      Text(
                        ShortlistStrings.projectDelete,
                        style: const TextStyle(color: Color(0xFFA04444)),
                      ),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'rename') {
                  setState(() {
                    _editingId = project.id;
                    _editingValue = project.name;
                    _editController.text = project.name;
                  });
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _editFocus.requestFocus();
                  });
                } else if (value == 'delete') {
                  setState(() => _deletingId = project.id);
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCreateInput(ShortlistStore store) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextField(
        focusNode: _createFocus,
        enabled: !_creatingSubmitting,
        onChanged: (v) => setState(() => _creatingValue = v),
        onSubmitted: (_) => _submitCreate(store),
        onEditingComplete: () => _submitCreate(store),
        decoration: InputDecoration(
          isDense: true,
          hintText: ShortlistStrings.projectNamePlaceholder,
          hintStyle: const TextStyle(color: Color(0xFFB5B3AE)),
          contentPadding: const EdgeInsets.fromLTRB(10, 8, 48, 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFC0C0C0)),
          ),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: _creatingSubmitting || _creatingValue.trim().isEmpty
                    ? null
                    : () => _submitCreate(store),
                icon: const Icon(Icons.check, size: 14),
                tooltip: ShortlistStrings.projectConfirm,
              ),
              IconButton(
                onPressed: () => setState(() {
                  _creating = false;
                  _creatingValue = '';
                }),
                icon: const Icon(Icons.close, size: 14),
                tooltip: ShortlistStrings.projectCancel,
              ),
            ],
          ),
        ),
        style: const TextStyle(fontSize: 14),
      ),
    );
  }
}

/// 对齐 Web `MobileFoldersDrawer`。
Future<void> showShortlistFoldersDrawer(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(ctx).height * 0.75,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        ShortlistStrings.foldersTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF171717),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close, size: 16, color: Color(0xFF6B6962)),
                      tooltip: ShortlistStrings.foldersClose,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFEAE8E3)),
              Expanded(
                child: ShortlistProjectSidebar(
                  variant: ShortlistProjectSidebarVariant.mobile,
                  onSelectProject: (_) => Navigator.pop(ctx),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
