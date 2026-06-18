import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/resume_models.dart';
import '../../../stores/resume_store.dart';
import '../../common/confirm_dialog.dart';
import 'resume_icons.dart';

// 对齐 Web ResumeList.tsx 设计 token
const _kTextPrimary = Color(0xFF171717);
const _kTextSecondary = Color(0xFF6B7280);
const _kTextMuted = Color(0xFF9CA3AF);
const _kTextRename = Color(0xFF374151);
const _kTextDelete = Color(0xFFDC2626);
const _kActiveCardBg = Color(0xFFF0EFEA);
const _kActiveCardBorder = Color(0x80EBE9E4);
const _kHoverBg = Color(0xFFF5F4F1);
const _kDivider = Color(0xFFF3F4F6);
const _kMobileHeaderBorder = Color(0xFFEEEDE9);
const _kIconRing = Color(0xFFF3F4F6);
const _kCheckIcon = Color(0xFF2C2B2A);

/// 对齐 Web `ResumeList.tsx` — 桌面下拉面板。
class ResumeList extends StatelessWidget {
  const ResumeList({
    super.key,
    required this.isOpen,
    required this.onClose,
    required this.onCreateOpen,
  });

  final bool isOpen;
  final VoidCallback onClose;
  final VoidCallback onCreateOpen;

  @override
  Widget build(BuildContext context) {
    if (!isOpen) return const SizedBox.shrink();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: onClose,
            behavior: HitTestBehavior.translucent,
            child: const SizedBox.expand(),
          ),
        ),
        Material(
          color: Colors.transparent,
          elevation: 0,
          shadowColor: const Color(0x38172A38),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 380,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.6,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xE6E5E7EB)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x38172A38),
                  blurRadius: 60,
                  offset: Offset(0, 24),
                  spreadRadius: -28,
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: SingleChildScrollView(
                    child: ResumeListBody(onClose: onClose),
                  ),
                ),
                const Divider(height: 1, thickness: 1, color: _kDivider),
                _CreateButton(onCreateOpen: onCreateOpen, onClose: onClose),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 移动端 BottomSheet 内容。
class ResumeListMobileSheet extends StatelessWidget {
  const ResumeListMobileSheet({
    super.key,
    required this.scrollController,
    required this.onClose,
    required this.onCreateOpen,
  });

  final ScrollController scrollController;
  final VoidCallback onClose;
  final VoidCallback onCreateOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Resume versions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _kTextPrimary,
                  ),
            ),
          ),
        ),
        const Divider(height: 1, thickness: 1, color: _kMobileHeaderBorder),
        Expanded(
          child: SingleChildScrollView(
            controller: scrollController,
            child: ResumeListBody(onClose: onClose),
          ),
        ),
        const Divider(height: 1, thickness: 1, color: _kDivider),
        _CreateButton(onCreateOpen: onCreateOpen, onClose: onClose),
        SizedBox(height: MediaQuery.paddingOf(context).bottom),
      ],
    );
  }
}

/// 简历列表主体（桌面 / 移动端共用）。
class ResumeListBody extends StatefulWidget {
  const ResumeListBody({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  State<ResumeListBody> createState() => _ResumeListBodyState();
}

class _ResumeListBodyState extends State<ResumeListBody> {
  String? _renamingId;
  final _draftController = TextEditingController();

  @override
  void dispose() {
    _draftController.dispose();
    super.dispose();
  }

  void _startRename(ResumeItem item) {
    setState(() {
      _renamingId = item.id;
      _draftController.text = item.title;
    });
  }

  Future<void> _saveRename(String resumeId) async {
    final store = context.read<ResumeStore>();
    final next = _draftController.text.trim().isEmpty
        ? 'Untitled'
        : _draftController.text.trim();
    final item = store.resumes.firstWhere((r) => r.id == resumeId);
    if (next != item.title) {
      await store.updateResume(resumeId, title: next);
    }
    if (mounted) setState(() => _renamingId = null);
  }

  Future<void> _deleteResume(String resumeId) async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Delete Resume',
      content: 'This action cannot be undone.',
      okText: 'Delete',
    );
    if (confirmed != true || !mounted) return;
    final store = context.read<ResumeStore>();
    final selectedId = store.selectedResume?.id;
    await store.deleteResume(resumeId);
    if (selectedId == resumeId) {
      final nextId = store.resumes.isNotEmpty ? store.resumes.first.id : null;
      if (nextId != null) {
        await store.selectResume(nextId);
      } else {
        store.clearSelection();
      }
    }
  }

  Future<void> _openResume(String id) async {
    await context.read<ResumeStore>().selectResume(id);
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ResumeStore>();
    if (store.isLoadingList) return _loadingSkeleton();

    final activeId = store.selectedResume?.id;
    final activeTitle = store.selectedResume?.title ?? 'Untitled';
    final others = activeId != null
        ? store.resumes.where((r) => r.id != activeId).toList()
        : store.resumes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (activeId != null) ...[
          const _SectionLabel('Currently viewing'),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: _activeCard(activeId, activeTitle),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Divider(height: 1, thickness: 1, color: _kDivider),
          ),
        ],
        if (others.isNotEmpty) ...[
          const _SectionLabel('Switch version'),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            child: Column(
              children: [
                for (final item in others) _otherRow(item),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _activeCard(String activeId, String activeTitle) {
    final isRenaming = _renamingId == activeId;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: _kActiveCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kActiveCardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 2,
                ),
              ],
              border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
            ),
            child: const Center(
              child: ResumeSvgIcon(ResumeIcons.fileText, size: 20, color: Color(0xFF4B5563)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: isRenaming
                ? _renameField(activeId)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activeTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _kTextPrimary,
                          height: 1.3,
                        ),
                      ),
                      const Text(
                        'Active version',
                        style: TextStyle(
                          fontSize: 12,
                          color: _kTextSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
          ),
          if (!isRenaming) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: _kActiveCardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 2,
                  ),
                ],
              ),
              child: const Center(
                child: ResumeSvgIcon(ResumeIcons.check, size: 16, color: _kCheckIcon),
              ),
            ),
            const SizedBox(width: 4),
            _ResumeActionsMenu(
              onRename: () => _startRename(
                context.read<ResumeStore>().resumes.firstWhere((r) => r.id == activeId),
              ),
              onDelete: () => _deleteResume(activeId),
              hoverOnLight: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _otherRow(ResumeItem item) {
    final isRenaming = _renamingId == item.id;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isRenaming ? null : () => _openResume(item.id),
        borderRadius: BorderRadius.circular(12),
        hoverColor: _kHoverBg,
        splashColor: _kHoverBg,
        highlightColor: _kHoverBg,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _kIconRing),
                ),
                child: const Center(
                  child: ResumeSvgIcon(
                    ResumeIcons.fileInput,
                    size: 16,
                    color: _kTextSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: isRenaming
                    ? _renameField(item.id)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _kTextPrimary,
                              height: 1.3,
                            ),
                          ),
                          Text(
                            resumeRowSubtitle(item),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: _kTextSecondary,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
              ),
              _ResumeActionsMenu(
                onRename: () => _startRename(item),
                onDelete: () => _deleteResume(item.id),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _renameField(String resumeId) {
    return SizedBox(
      height: 32,
      child: TextField(
        controller: _draftController,
        autofocus: true,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: _kTextPrimary,
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _kTextPrimary),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        onSubmitted: (_) => _saveRename(resumeId),
        onEditingComplete: () => _saveRename(resumeId),
      ),
    );
  }

  Widget _loadingSkeleton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 96,
            height: 12,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F4),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 112,
            height: 12,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < 3; i++) ...[
            Container(
              height: 56,
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 对齐 Web `DropdownMenu`：w-36、右对齐、hover #F5F4F1。
class _ResumeActionsMenu extends StatefulWidget {
  const _ResumeActionsMenu({
    required this.onRename,
    required this.onDelete,
    this.hoverOnLight = false,
  });

  final VoidCallback onRename;
  final VoidCallback onDelete;
  final bool hoverOnLight;

  @override
  State<_ResumeActionsMenu> createState() => _ResumeActionsMenuState();
}

class _ResumeActionsMenuState extends State<_ResumeActionsMenu> {
  ButtonStyle get _menuItemStyle => ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(144, 44)),
        maximumSize: const WidgetStatePropertyAll(Size(144, 44)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        overlayColor: const WidgetStatePropertyAll(_kHoverBg),
        backgroundColor: const WidgetStatePropertyAll(Colors.white),
        foregroundColor: const WidgetStatePropertyAll(_kTextRename),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.2),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      alignmentOffset: const Offset(-112, 4),
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(Colors.white),
        elevation: const WidgetStatePropertyAll(8),
        shadowColor: WidgetStatePropertyAll(Colors.black.withValues(alpha: 0.12)),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 4)),
        minimumSize: const WidgetStatePropertyAll(Size(144, 0)),
        maximumSize: const WidgetStatePropertyAll(Size(144, double.infinity)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      menuChildren: [
        MenuItemButton(
          style: _menuItemStyle,
          onPressed: widget.onRename,
          child: const Row(
            children: [
              ResumeSvgIcon(ResumeIcons.pencil, size: 16, color: _kTextRename),
              SizedBox(width: 10),
              Text('Rename', style: TextStyle(fontSize: 14, color: _kTextRename)),
            ],
          ),
        ),
        MenuItemButton(
          style: _menuItemStyle.copyWith(
            foregroundColor: const WidgetStatePropertyAll(_kTextDelete),
          ),
          onPressed: widget.onDelete,
          child: const Row(
            children: [
              ResumeSvgIcon(ResumeIcons.trash2, size: 16, color: _kTextDelete),
              SizedBox(width: 10),
              Text('Delete', style: TextStyle(fontSize: 14, color: _kTextDelete)),
            ],
          ),
        ),
      ],
      builder: (context, controller, child) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (controller.isOpen) {
                controller.close();
              } else {
                controller.open();
              }
            },
            borderRadius: BorderRadius.circular(8),
            hoverColor: widget.hoverOnLight
                ? Colors.white.withValues(alpha: 0.7)
                : _kHoverBg,
            splashColor: widget.hoverOnLight
                ? Colors.white.withValues(alpha: 0.7)
                : _kHoverBg,
            child: const SizedBox(
              width: 32,
              height: 32,
              child: Center(
                child: ResumeSvgIcon(
                  ResumeIcons.moreHorizontal,
                  size: 16,
                  color: _kTextMuted,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CreateButton extends StatelessWidget {
  const _CreateButton({required this.onCreateOpen, required this.onClose});

  final VoidCallback onCreateOpen;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          onCreateOpen();
          onClose();
        },
        hoverColor: _kHoverBg,
        splashColor: _kHoverBg,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              ResumeSvgIcon(ResumeIcons.plus, size: 16, color: _kTextSecondary),
              SizedBox(width: 8),
              Text(
                'New',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _kTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          color: _kTextMuted,
          height: 1.2,
        ),
      ),
    );
  }
}
