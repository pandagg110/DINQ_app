import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../models/shortlist_models.dart';
import '../../../services/shortlist_service.dart';

/// 与 TSX `common.shortlistFolderModal` 对齐。
abstract final class ShortlistFolderModalStrings {
  static const title = 'Add to shortlist';
  static const loading = 'Loading folders…';
  static const loadError = 'Could not load folders.';
  static const retry = 'Retry';
  static const empty = 'No folders yet. Create one below.';
  static const defaultFolder = 'Default';
  static const namePlaceholder = 'Folder name';
  static const newFolder = 'New folder';
}

/// 对齐 Web `ShortlistFolderModal.tsx` 的文件夹选择。
Future<String?> showShortlistFolderModal(BuildContext context) {
  return showGeneralDialog<String>(
    context: context,
    barrierDismissible: true,
    barrierLabel: ShortlistFolderModalStrings.title,
    barrierColor: const Color(0x4D000000),
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, animation, secondaryAnimation) {
      return Stack(
        fit: StackFit.expand,
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: const SizedBox.expand(),
          ),
          Center(
            child: ScaleTransition(
              scale: CurvedAnimation(
                parent: animation,
                curve: const Cubic(0.4, 0, 0.2, 1),
              ).drive(Tween<double>(begin: 0.95, end: 1)),
              child: FadeTransition(
                opacity: animation,
                child: const _ShortlistFolderModalDialog(),
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _ShortlistFolderModalDialog extends StatefulWidget {
  const _ShortlistFolderModalDialog();

  @override
  State<_ShortlistFolderModalDialog> createState() =>
      _ShortlistFolderModalDialogState();
}

class _ShortlistFolderModalDialogState extends State<_ShortlistFolderModalDialog> {
  final _service = ShortlistService();
  final _createController = TextEditingController();
  final _createFocusNode = FocusNode();

  List<FavoriteProject> _projects = const [];
  var _isLoading = false;
  var _hasLoaded = false;
  String? _loadError;
  var _creating = false;
  var _submitting = false;

  @override
  void initState() {
    super.initState();
    _createController.addListener(_onCreateTextChanged);
    _loadProjects();
  }

  void _onCreateTextChanged() {
    if (_creating && mounted) setState(() {});
  }

  @override
  void dispose() {
    _createController.removeListener(_onCreateTextChanged);
    _createController.dispose();
    _createFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadProjects() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final projects = await _service.listProjects();
      if (!mounted) return;
      setState(() {
        _projects = projects;
        _isLoading = false;
        _hasLoaded = true;
        _loadError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasLoaded = false;
        _loadError = ShortlistFolderModalStrings.loadError;
      });
    }
  }

  List<FavoriteProject> get _sortedProjects {
    final list = List<FavoriteProject>.from(_projects);
    list.sort((a, b) {
      if (a.isDefault != b.isDefault) return a.isDefault ? -1 : 1;
      final aAt = a.createdAt ?? '';
      final bAt = b.createdAt ?? '';
      if (aAt.isNotEmpty && bAt.isNotEmpty) return bAt.compareTo(aAt);
      return a.name.compareTo(b.name);
    });
    return list;
  }

  void _pick(String projectId) {
    Navigator.pop(context, projectId);
  }

  void _close() {
    Navigator.pop(context);
  }

  Future<void> _startCreate() async {
    if (!_hasLoaded && !_isLoading) {
      await _loadProjects();
    }
    if (!_hasLoaded || !mounted) return;
    setState(() {
      _creating = true;
      _createController.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _createFocusNode.requestFocus();
    });
  }

  Future<void> _submitCreate() async {
    if (_submitting) return;
    final name = _createController.text.trim();
    if (name.isEmpty) {
      setState(() => _creating = false);
      return;
    }
    setState(() => _submitting = true);
    try {
      final created = await _service.createProject(name);
      if (!mounted) return;
      setState(() {
        _creating = false;
        _createController.clear();
        _submitting = false;
        _projects = [..._projects, created];
      });
      _pick(created.id);
    } catch (_) {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _cancelCreate() {
    setState(() {
      _creating = false;
      _createController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.7;
    final showLoading = !_hasLoaded && _isLoading;
    final isEmpty = _hasLoaded && _sortedProjects.isEmpty;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 380,
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEAE7E0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F000000),
              blurRadius: 50,
              offset: Offset(0, 20),
              spreadRadius: -12,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFF0EEEA))),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      ShortlistFolderModalStrings.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2A2826),
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _close,
                      borderRadius: BorderRadius.circular(8),
                      hoverColor: const Color(0xFFF5F4F0),
                      child: const SizedBox(
                        width: 28,
                        height: 28,
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: Color(0xFF9E9B93),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFB5B3AE),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              ShortlistFolderModalStrings.loading,
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFFB5B3AE),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (!_hasLoaded && _loadError != null && !_isLoading)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 20,
                        ),
                        child: Column(
                          children: [
                            const Text(
                              ShortlistFolderModalStrings.loadError,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF8A8880),
                              ),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: _loadProjects,
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 32),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                side: const BorderSide(
                                  color: Color(0xFFE5E3DE),
                                ),
                                foregroundColor: const Color(0xFF171717),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              child: const Text(
                                ShortlistFolderModalStrings.retry,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (isEmpty && !_creating)
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 20,
                        ),
                        child: Text(
                          ShortlistFolderModalStrings.empty,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFFB5B3AE),
                          ),
                        ),
                      ),
                    for (final project in _sortedProjects)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _pick(project.id),
                          hoverColor: const Color(0xFFFAFAF8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.folder_open_outlined,
                                  size: 16,
                                  color: project.isDefault
                                      ? const Color(0xFF8A8880)
                                      : const Color(0xFFB5B3AE),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    project.isDefault
                                        ? ShortlistFolderModalStrings
                                            .defaultFolder
                                        : project.name,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF2A2826),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (_creating)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
                        child: SizedBox(
                          height: 32,
                          child: Stack(
                            alignment: Alignment.centerRight,
                            children: [
                              TextField(
                                controller: _createController,
                                focusNode: _createFocusNode,
                                enabled: !_submitting,
                                onSubmitted: (_) => _submitCreate(),
                                onEditingComplete: _submitCreate,
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.fromLTRB(
                                    8,
                                    8,
                                    56,
                                    8,
                                  ),
                                  hintText:
                                      ShortlistFolderModalStrings.namePlaceholder,
                                  hintStyle: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFFB5B3AE),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFC0C0C0),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFC0C0C0),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFC0C0C0),
                                    ),
                                  ),
                                ),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF2A2826),
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _CreateActionIcon(
                                    icon: Icons.check,
                                    enabled: !_submitting &&
                                        _createController.text
                                            .trim()
                                            .isNotEmpty,
                                    onTap: _submitCreate,
                                  ),
                                  _CreateActionIcon(
                                    icon: Icons.close,
                                    onTap: _cancelCreate,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFF0EEEA))),
              ),
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: (_creating || _submitting || _isLoading)
                      ? null
                      : _startCreate,
                  borderRadius: BorderRadius.circular(6),
                  hoverColor: const Color(0xFFFAFAF8),
                  child: Opacity(
                    opacity: (_creating || _submitting || _isLoading) ? 0.4 : 1,
                    child: SizedBox(
                      height: 36,
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          if (_submitting)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF6B6962),
                              ),
                            )
                          else
                            const Icon(
                              Icons.add,
                              size: 16,
                              color: Color(0xFF6B6962),
                            ),
                          const SizedBox(width: 8),
                          const Text(
                            ShortlistFolderModalStrings.newFolder,
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B6962),
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
    );
  }
}

class _CreateActionIcon extends StatelessWidget {
  const _CreateActionIcon({
    required this.icon,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(4),
        hoverColor: const Color(0xFFF0EFEB),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            icon,
            size: 14,
            color: enabled
                ? const Color(0xFF8A8880)
                : const Color(0xFF8A8880).withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}
