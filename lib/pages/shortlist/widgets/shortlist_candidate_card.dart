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
    const visibleTags = 2;

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
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ..._buildVisibleTags(visibleTags),
                if (_editingTag)
                  SizedBox(
                    width: 96,
                    height: 24,
                    child: TextField(
                      controller: _tagController,
                      focusNode: _tagFocus,
                      onSubmitted: (_) async {
                        await _addTag();
                        setState(() => _editingTag = false);
                      },
                      onEditingComplete: () async {
                        await _addTag();
                        setState(() => _editingTag = false);
                      },
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
                  _TagAddButton(
                    onTap: () {
                      setState(() {
                        _editingTag = true;
                        _tagController.clear();
                      });
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _tagFocus.requestFocus();
                      });
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildVisibleTags(int visibleCount) {
    final tags = _tagList;
    final canExpand = tags.length > visibleCount;
    final shownCount =
        _tagsExpanded ? tags.length : visibleCount.clamp(0, tags.length);
    final shown = tags.take(shownCount).toList();
    final remaining = tags.length - shown.length;
    final widgets = <Widget>[];

    for (final tag in shown) {
      widgets.add(_TagChip(
        label: tag,
        onRemove: () => _removeTag(tag),
      ));
    }

    if (remaining > 0) {
      widgets.add(
        GestureDetector(
          onTap: () => setState(() => _tagsExpanded = true),
          child: Container(
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFECE9E3),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(
              '+$remaining',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF8A8880),
              ),
            ),
          ),
        ),
      );
    }

    if (_tagsExpanded && canExpand) {
      widgets.add(
        GestureDetector(
          onTap: () => setState(() => _tagsExpanded = false),
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFFECE9E3),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.keyboard_arrow_up,
              size: 14,
              color: Color(0xFF8A8880),
            ),
          ),
        ),
      );
    }

    return widgets;
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 140),
      height: 24,
      padding: const EdgeInsets.only(left: 10, right: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F4F0),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Color(0xFF8A8880)),
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(
                Icons.close,
                size: 10,
                color: const Color(0xFFB5B3AE),
              ),
            ),
          ),
        ],
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
      child: Container(
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: const Color(0xFFD5D3CE),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, size: 12, color: Color(0xFFB5B3AE)),
            const SizedBox(width: 4),
            Text(
              ShortlistStrings.cardTagAdd,
              style: const TextStyle(fontSize: 12, color: Color(0xFFB5B3AE)),
            ),
          ],
        ),
      ),
    );
  }
}
