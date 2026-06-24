import 'package:flutter/material.dart';

import '../../../models/shortlist_models.dart';
import '../../../stores/shortlist_store.dart';
import '../../../widgets/search/deep_search/deep_search_results_helpers.dart';
import '../shortlist_strings.dart';
import 'shortlist_shared_widgets.dart';

/// 对齐 Web Shortlist 卡片视图（card view）。
class ShortlistCandidateCard extends StatefulWidget {
  const ShortlistCandidateCard({
    super.key,
    required this.item,
    required this.store,
    required this.isSelected,
    required this.onTap,
    required this.onToggleSelect,
  });

  final FavoriteItem item;
  final ShortlistStore store;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onToggleSelect;

  @override
  State<ShortlistCandidateCard> createState() => _ShortlistCandidateCardState();
}

class _ShortlistCandidateCardState extends State<ShortlistCandidateCard> {
  bool _showRemoveConfirm = false;
  bool _tagsExpanded = false;
  bool _editingTag = false;
  final _tagController = TextEditingController();
  final _tagFocus = FocusNode();

  @override
  void dispose() {
    _tagController.dispose();
    _tagFocus.dispose();
    super.dispose();
  }

  List<String> get _tagList => widget.item.tagList;

  Future<void> _commitTags(List<String> nextList) async {
    await widget.store.updateTags(widget.item.id, nextList.join(', '));
  }

  Future<void> _removeTag(String tag) async {
    await _commitTags(_tagList.where((t) => t != tag).toList());
  }

  Future<void> _addTag() async {
    final next = _tagController.text.trim();
    if (next.isEmpty || _tagList.contains(next)) {
      _tagController.clear();
      return;
    }
    await _commitTags([..._tagList, next]);
    _tagController.clear();
  }

  Future<void> _removeFavorite() async {
    setState(() => _showRemoveConfirm = false);
    await widget.store.removeFavorite(widget.item.id);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final name = item.name.isEmpty ? '—' : item.name;
    final metaLine = item.roleLine;
    final avatarColor = nameToAvatarColor(name);

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.isSelected
                ? const Color(0xFF171717)
                : const Color(0xFFEAE8E3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: widget.onToggleSelect,
                  child: ShortlistSelectCheckbox(
                    checked: widget.isSelected,
                    onChanged: widget.onToggleSelect,
                  ),
                ),
                const Spacer(),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    GestureDetector(
                      onTap: () => setState(
                        () => _showRemoveConfirm = !_showRemoveConfirm,
                      ),
                      child: Container(
                        width: 16,
                        height: 16,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFECE9E3)),
                        ),
                        child: const Icon(
                          Icons.remove,
                          size: 12,
                          color: Color(0xFF8A8880),
                        ),
                      ),
                    ),
                    if (_showRemoveConfirm)
                      Positioned(
                        right: 0,
                        top: 20,
                        child: Material(
                          elevation: 8,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 112,
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFEAE8E3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  ShortlistStrings.cardRemoveConfirm,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF171717),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextButton(
                                        onPressed: _removeFavorite,
                                        style: TextButton.styleFrom(
                                          minimumSize: const Size(0, 24),
                                          padding: EdgeInsets.zero,
                                          backgroundColor:
                                              const Color(0xFFA04444),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                        ),
                                        child: Text(
                                          ShortlistStrings.cardConfirmYes,
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: TextButton(
                                        onPressed: () => setState(
                                          () => _showRemoveConfirm = false,
                                        ),
                                        style: TextButton.styleFrom(
                                          minimumSize: const Size(0, 24),
                                          padding: EdgeInsets.zero,
                                          backgroundColor:
                                              const Color(0xFFF6F4F0),
                                          foregroundColor:
                                              const Color(0xFF6B6962),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                        ),
                                        child: Text(
                                          ShortlistStrings.cardConfirmNo,
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: avatarColor,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    toInitials(name),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1F1F1F),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF171717),
                        ),
                      ),
                      if (metaLine.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            metaLine,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF8A8880),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                ShortlistStatusBadge(status: item.status),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: Color(0xFFEAE8E3)),
            ),
            if (item.evidence.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  item.evidence,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: Color(0xFF171717),
                  ),
                ),
              ),
            _TagRow(
              tags: _tagList,
              tagsExpanded: _tagsExpanded,
              editingTag: _editingTag,
              tagController: _tagController,
              tagFocus: _tagFocus,
              onToggleExpanded: () =>
                  setState(() => _tagsExpanded = !_tagsExpanded),
              onRemoveTag: _removeTag,
              onStartEditTag: () {
                setState(() {
                  _editingTag = true;
                  _tagController.clear();
                });
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _tagFocus.requestFocus();
                });
              },
              onFinishEditTag: () async {
                await _addTag();
                if (mounted) setState(() => _editingTag = false);
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// 对齐 Web `flex items-center gap-1.5` 标签行，避免 Wrap 换行后子项撑满整行。
class _TagRow extends StatelessWidget {
  const _TagRow({
    required this.tags,
    required this.tagsExpanded,
    required this.editingTag,
    required this.tagController,
    required this.tagFocus,
    required this.onToggleExpanded,
    required this.onRemoveTag,
    required this.onStartEditTag,
    required this.onFinishEditTag,
  });

  static const _visibleCount = 2;

  final List<String> tags;
  final bool tagsExpanded;
  final bool editingTag;
  final TextEditingController tagController;
  final FocusNode tagFocus;
  final VoidCallback onToggleExpanded;
  final ValueChanged<String> onRemoveTag;
  final VoidCallback onStartEditTag;
  final Future<void> Function() onFinishEditTag;

  @override
  Widget build(BuildContext context) {
    final canExpand = tags.length > _visibleCount;
    final shownCount =
        tagsExpanded ? tags.length : _visibleCount.clamp(0, tags.length);
    final shown = tags.take(shownCount).toList();
    final remaining = tags.length - shown.length;

    return tagsExpanded
        ? Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _children(
              shown: shown,
              remaining: 0,
              canExpand: canExpand,
            ),
          )
        : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: _children(
                shown: shown,
                remaining: remaining,
                canExpand: canExpand,
              ),
            ),
          );
  }

  List<Widget> _children({
    required List<String> shown,
    required int remaining,
    required bool canExpand,
  }) {
    return [
      for (final tag in shown)
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: _TagChip(label: tag, onRemove: () => onRemoveTag(tag)),
        ),
      if (remaining > 0)
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: GestureDetector(
            onTap: onToggleExpanded,
            child: _TagPill(
              backgroundColor: const Color(0xFFECE9E3),
              child: Text(
                '+$remaining',
                style: _tagTextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ),
      if (tagsExpanded && canExpand)
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: GestureDetector(
            onTap: onToggleExpanded,
            child: _TagPill(
              width: 24,
              backgroundColor: const Color(0xFFECE9E3),
              padding: EdgeInsets.zero,
              child: const Icon(
                Icons.keyboard_arrow_up,
                size: 14,
                color: Color(0xFF8A8880),
              ),
            ),
          ),
        ),
      if (editingTag)
        SizedBox(
          width: 96,
          height: 24,
          child: TextField(
            controller: tagController,
            focusNode: tagFocus,
            onSubmitted: (_) => onFinishEditTag(),
            onEditingComplete: onFinishEditTag,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              hintText: ShortlistStrings.cardTagNewPlaceholder,
              hintStyle: const TextStyle(
                fontSize: 12,
                color: Color(0xFFB5B3AE),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFFC0C0C0)),
              ),
            ),
            style: const TextStyle(fontSize: 12),
          ),
        )
      else
        _TagAddButton(onTap: onStartEditTag),
    ];
  }
}

const double _tagHeight = 24;

TextStyle _tagTextStyle({FontWeight? fontWeight}) => TextStyle(
      fontSize: 12,
      height: 1,
      fontWeight: fontWeight,
      color: const Color(0xFF8A8880),
    );

/// 统一 h-6 标签 pill，对齐 Web `inline-flex items-center h-6`。
class _TagPill extends StatelessWidget {
  const _TagPill({
    required this.child,
    this.width,
    this.backgroundColor,
    this.border,
    this.padding = const EdgeInsets.symmetric(horizontal: 8),
  });

  final Widget child;
  final double? width;
  final Color? backgroundColor;
  final BoxBorder? border;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: _tagHeight,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: border,
      ),
      child: Align(
        alignment: Alignment.center,
        widthFactor: 1,
        heightFactor: 1,
        child: child,
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 140),
      child: _TagPill(
      backgroundColor: const Color(0xFFF6F4F0),
      padding: const EdgeInsets.only(left: 10, right: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 110),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: _tagTextStyle(),
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(
                Icons.close,
                size: 10,
                color: Color(0xFFB5B3AE),
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class _TagAddButton extends StatelessWidget {
  const _TagAddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: _TagPill(
        border: Border.all(color: const Color(0xFFD5D3CE)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.add, size: 12, color: Color(0xFFB5B3AE)),
            const SizedBox(width: 4),
            Text(ShortlistStrings.cardTagAdd, style: _tagTextStyle()),
          ],
        ),
      ),
    );
  }
}
