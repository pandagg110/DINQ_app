import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../utils/card_url_validation.dart';
import 'onboarding_footer.dart';

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

/// 对齐 Web `/onboarding/socials/page.tsx`。
class OnboardingSocialsView extends StatefulWidget {
  const OnboardingSocialsView({
    super.key,
    this.initialLinks = const [],
    required this.onFinish,
  });

  final List<OnboardingAddedLink> initialLinks;
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

  static const _platformIcons = [
    ('assets/icons/social-icons/Twitter.svg', 'X'),
    ('assets/icons/social-icons/Github.svg', 'GitHub'),
    ('assets/icons/social-icons/LinkedIn.svg', 'LinkedIn'),
    ('assets/icons/social-icons/Youtube.svg', 'YouTube'),
    ('assets/icons/social-icons/Instagram.svg', 'Instagram'),
    ('assets/icons/social-icons/Medium.svg', 'Medium'),
    ('assets/icons/social-icons/Behance.svg', 'Behance'),
    ('assets/icons/social-icons/Substack.svg', 'Substack'),
    ('assets/icons/social-icons/HuggingFace.svg', 'Hugging Face'),
    ('assets/icons/social-icons/Scholar.svg', 'Scholar'),
    ('assets/icons/social-icons/OpenReview.svg', 'OpenReview'),
  ];

  String _iconForType(String type) {
    switch (type.toUpperCase()) {
      case 'LINKEDIN':
        return 'assets/icons/social-icons/LinkedIn.svg';
      case 'GITHUB':
        return 'assets/icons/social-icons/Github.svg';
      case 'TWITTER':
        return 'assets/icons/social-icons/Twitter.svg';
      case 'SCHOLAR':
        return 'assets/icons/social-icons/Scholar.svg';
      case 'OPENREVIEW':
        return 'assets/icons/social-icons/OpenReview.svg';
      case 'HUGGINGFACE':
        return 'assets/icons/social-icons/HuggingFace.svg';
      case 'MEDIUM':
        return 'assets/icons/social-icons/Medium.svg';
      case 'SUBSTACK':
        return 'assets/icons/social-icons/Substack.svg';
      case 'BEHANCE':
        return 'assets/icons/social-icons/Behance.svg';
      case 'INSTAGRAM':
        return 'assets/icons/social-icons/Instagram.svg';
      case 'YOUTUBE':
        return 'assets/icons/social-icons/Youtube.svg';
      default:
        return 'assets/icons/social-icons/Link.svg';
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _added.isNotEmpty && !_busy;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 512),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFEEEDE9)),
                ),
                child: const Icon(Icons.auto_fix_high, size: 20, color: Color(0xFF171717)),
              ),
              const SizedBox(height: 24),
              const Text(
                'Add social links',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF171717),
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Paste a link to auto-detect the platform — more links, more visibility',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Color(0xFF6B6862),
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  ..._platformIcons.map(
                    (icon) => Tooltip(
                      message: icon.$2,
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: SvgPicture.asset(
                          icon.$1,
                          width: 40,
                          height: 40,
                          placeholderBuilder: (_) => Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0EEE8),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.link, size: 20, color: Color(0xFF9E9B93)),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0EEE8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.more_horiz, size: 20, color: Color(0xFF9E9B93)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
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
                            fontSize: 14,
                            color: Color(0x66303030),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: const TextStyle(fontSize: 14, color: Color(0xFF171717)),
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
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Text(
                  'Press Enter ↵ to add',
                  style: TextStyle(fontSize: 12, color: Color(0xFF9E9B93)),
                ),
              ),
              const SizedBox(height: 24),
              OnboardingFixedFooter(
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: canSubmit ? () => _finish(_added) : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canSubmit
                              ? const Color(0xFF171717)
                              : const Color(0xFFE5E5E5),
                          foregroundColor: canSubmit
                              ? Colors.white
                              : const Color(0x66303030),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _isSubmitting ? 'Continuing...' : 'Continue',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _busy ? null : () => _finish(const []),
                      child: Text(
                        _isSkipping ? 'Skipping...' : "I'll do this later",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B6862),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_added.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Added (${_added.length})',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B6862),
                  ),
                ),
                const SizedBox(height: 8),
                ..._added.asMap().entries.map(
                      (entry) => _AddedRow(
                        link: entry.value,
                        iconAsset: _iconForType(entry.value.type),
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
            ],
          ),
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
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isEditing ? const Color(0xFFF7F6F2) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            iconAsset,
            width: 24,
            height: 24,
            placeholderBuilder: (_) =>
                const Icon(Icons.link, size: 24, color: Color(0xFF6B6862)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  link.platform,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF171717),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isEditing)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: TextField(
                      controller: editingController,
                      autofocus: true,
                      enabled: !isCommittingEdit,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(color: Color(0xFF171717)),
                        ),
                      ),
                      style: const TextStyle(fontSize: 14),
                      onSubmitted: (_) => onCommitEdit(),
                    ),
                  )
                else
                  Text(
                    stripUrlScheme(link.url),
                    style: const TextStyle(fontSize: 14, color: Color(0xFF6B6862)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (isEditing)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check, size: 18, color: Colors.green),
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
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF6B6862)),
                  onPressed: onStartEdit,
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFF6B6862)),
                  onPressed: onDelete,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
