import 'package:flutter/material.dart';

import '../../../utils/card_url_validation.dart';
import '../../../utils/onboarding_social_icons.dart';
import '../../common/asset_icon.dart';
import 'onboarding_top_bar.dart';

class OnboardingAddedLink {
  const OnboardingAddedLink({
    required this.type,
    required this.platform,
    required this.url,
  });

  final String type;
  final String platform;
  final String url;
}

/// 对齐 Web `/onboarding/socials/page.tsx` 与移动端设计稿。
class OnboardingSocialsView extends StatefulWidget {
  const OnboardingSocialsView({
    super.key,
    this.initialLinks = const [],
    required this.onBack,
    required this.onFinish,
  });

  final List<OnboardingAddedLink> initialLinks;
  final VoidCallback onBack;
  final Future<void> Function(List<OnboardingAddedLink> links) onFinish;

  @override
  State<OnboardingSocialsView> createState() => _OnboardingSocialsViewState();
}

class _OnboardingSocialsViewState extends State<OnboardingSocialsView> {
  late List<OnboardingAddedLink> _added;
  final _newUrlController = TextEditingController();
  bool _isValidating = false;
  bool _isSubmitting = false;
  bool _isSkipping = false;
  int? _editingIndex;
  final _editingController = TextEditingController();
  bool _isCommittingEdit = false;

  bool get _busy =>
      _isSubmitting || _isSkipping || _isValidating || _isCommittingEdit;

  static bool _isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 768;

  @override
  void initState() {
    super.initState();
    _added = List<OnboardingAddedLink>.from(widget.initialLinks);
  }

  @override
  void dispose() {
    _newUrlController.dispose();
    _editingController.dispose();
    super.dispose();
  }

  Future<void> _handleAdd() async {
    final raw = _newUrlController.text.trim();
    if (raw.isEmpty || _isValidating) return;
    setState(() => _isValidating = true);
    try {
      final result = await validateCardUrlInput(raw);
      if (_added.any((a) => a.type == result.type)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'You already added a ${platformNameForType(result.type)} link',
            ),
          ),
        );
        return;
      }
      setState(() {
        _added = [
          ..._added,
          OnboardingAddedLink(
            type: result.type,
            platform: platformNameForType(result.type),
            url: result.url,
          ),
        ];
        _newUrlController.clear();
      });
    } catch (error) {
      if (!mounted) return;
      final msg = error.toString().replaceAll('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg.isEmpty ? 'Invalid URL' : msg)),
      );
    } finally {
      if (mounted) setState(() => _isValidating = false);
    }
  }

  void _handleDelete(int index) {
    setState(() {
      _added = [
        for (var i = 0; i < _added.length; i++)
          if (i != index) _added[i],
      ];
      if (_editingIndex == index) {
        _editingIndex = null;
        _editingController.clear();
      }
    });
  }

  void _startEdit(int index) {
    setState(() {
      _editingIndex = index;
      _editingController.text = _added[index].url;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingIndex = null;
      _editingController.clear();
    });
  }

  Future<void> _commitEdit() async {
    if (_editingIndex == null) return;
    final raw = _editingController.text.trim();
    if (raw.isEmpty) return;
    setState(() => _isCommittingEdit = true);
    try {
      final result = await validateCardUrlInput(raw);
      final index = _editingIndex!;
      setState(() {
        _added = _added
            .asMap()
            .entries
            .map(
              (e) => e.key == index
                  ? OnboardingAddedLink(
                      type: result.type,
                      platform: platformNameForType(result.type),
                      url: result.url,
                    )
                  : e.value,
            )
            .toList();
        _editingIndex = null;
        _editingController.clear();
      });
    } catch (error) {
      if (!mounted) return;
      final msg = error.toString().replaceAll('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg.isEmpty ? 'Invalid URL' : msg)),
      );
    } finally {
      if (mounted) setState(() => _isCommittingEdit = false);
    }
  }

  Future<void> _finish(List<OnboardingAddedLink> links) async {
    setState(() {
      _isSubmitting = links.isNotEmpty;
      _isSkipping = links.isEmpty;
    });
    try {
      await widget.onFinish(links);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isSkipping = false;
        });
      }
    }
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: OnboardingCircleBackButton(onTap: widget.onBack),
          ),
        ),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Add social links',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF171717),
              height: 1.25,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Paste a link to auto-detect the platform — more links, more visibility',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 14,
              height: 1.5,
              color: Color(0xFF6B6862),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIconGrid() {
    const iconSize = 40.0;
    const gap = 10.0;
    const iconsPerRow = 9;

    final tiles = <Widget>[
      ...OnboardingSocialIcons.platformIconFiles.map(
        (icon) => _PlatformIconTile(
          asset: OnboardingSocialIcons.assetFor(icon.file),
          label: icon.name,
        ),
      ),
      Container(
        width: iconSize,
        height: iconSize,
        decoration: BoxDecoration(
          color: const Color(0xFFF0EEE8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.more_horiz, size: 20, color: Color(0xFF9E9B93)),
      ),
    ];

    Widget buildRow(List<Widget> items) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: gap),
            items[i],
          ],
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              buildRow(tiles.sublist(0, iconsPerRow)),
              const SizedBox(height: gap),
              buildRow(tiles.sublist(iconsPerRow)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUrlInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEEEDE9)),
        ),
        child: Row(
          children: [
            const Icon(Icons.link, size: 16, color: Color(0xFF9E9B93)),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _newUrlController,
                enabled: !_busy,
                decoration: const InputDecoration(
                  hintText: 'Paste a link to auto-detect the platform',
                  hintStyle: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 14,
                    color: Color(0x66303030),
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  filled: false,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                style: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 14,
                  color: Color(0xFF171717),
                ),
                onSubmitted: (_) => _handleAdd(),
              ),
            ),
            if (_isValidating)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddedList() {
    if (_added.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Added (${_added.length})',
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B6862),
            ),
          ),
          const SizedBox(height: 8),
          ..._added.asMap().entries.map(
                (entry) => _AddedRow(
                  link: entry.value,
                  iconAsset: OnboardingSocialIcons.iconForType(entry.value.type),
                  isEditing: _editingIndex == entry.key,
                  editingController: _editingController,
                  isCommittingEdit: _isCommittingEdit,
                  onStartEdit: () => _startEdit(entry.key),
                  onDelete: () => _handleDelete(entry.key),
                  onCommitEdit: _commitEdit,
                  onCancelEdit: _cancelEdit,
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final canSubmit = _added.isNotEmpty && !_busy;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomPad),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: canSubmit ? () => _finish(_added) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canSubmit
                    ? const Color(0xFF171717)
                    : const Color(0xFFE5E5E5),
                foregroundColor: canSubmit
                    ? Colors.white
                    : const Color(0xFF303030).withValues(alpha: 0.4),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _isSubmitting ? 'Submitting...' : 'Submit',
                      style: const TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _busy ? null : () => _finish(const []),
            child: Text(
              _isSkipping ? 'Skipping...' : "I'll do this later",
              style: const TextStyle(
                fontFamily: 'Geist',
                fontSize: 14,
                color: Color(0xFF6B6862),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(),
        const SizedBox(height: 24),
        _buildIconGrid(),
        const SizedBox(height: 24),
        _buildUrlInput(),
        _buildAddedList(),
        const SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isMobile(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: _buildBodyContent(),
            ),
          ),
          _buildFooter(),
        ],
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 512),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 24),
                child: _buildBodyContent(),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }
}

class _PlatformIconTile extends StatelessWidget {
  const _PlatformIconTile({required this.asset, required this.label});

  final String asset;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 40,
          height: 40,
          child: AssetIcon(asset: asset, size: 40),
        ),
      ),
    );
  }
}

class _AddedRow extends StatelessWidget {
  const _AddedRow({
    required this.link,
    required this.iconAsset,
    required this.isEditing,
    required this.editingController,
    required this.isCommittingEdit,
    required this.onStartEdit,
    required this.onDelete,
    required this.onCommitEdit,
    required this.onCancelEdit,
  });

  final OnboardingAddedLink link;
  final String iconAsset;
  final bool isEditing;
  final TextEditingController editingController;
  final bool isCommittingEdit;
  final VoidCallback onStartEdit;
  final VoidCallback onDelete;
  final VoidCallback onCommitEdit;
  final VoidCallback onCancelEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEDE9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: AssetIcon(asset: iconAsset, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  link.platform,
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF171717),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isEditing)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: TextField(
                      controller: editingController,
                      autofocus: true,
                      enabled: !isCommittingEdit,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFEEEDE9)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF171717)),
                        ),
                      ),
                      style: const TextStyle(fontFamily: 'Geist', fontSize: 13),
                      onSubmitted: (_) => onCommitEdit(),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      stripUrlScheme(link.url),
                      style: const TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 13,
                        color: Color(0xFF6B6862),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          if (isEditing)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check, size: 18, color: Color(0xFF171717)),
                  onPressed: isCommittingEdit ? null : onCommitEdit,
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Color(0xFF9E9B93)),
                  onPressed: isCommittingEdit ? null : onCancelEdit,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            )
          else
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz, size: 20, color: Color(0xFF6B6862)),
              padding: EdgeInsets.zero,
              onSelected: (action) {
                if (action == 'edit') onStartEdit();
                if (action == 'delete') onDelete();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: Text('Edit link', style: TextStyle(fontFamily: 'Geist')),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text('Remove', style: TextStyle(fontFamily: 'Geist')),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
