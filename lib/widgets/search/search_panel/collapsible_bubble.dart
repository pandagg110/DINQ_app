import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'attachment_bubble_preview.dart';

/// 与 TSX `SearchPanel.CollapsibleBubble` 对齐。
class CollapsibleBubble extends StatefulWidget {
  const CollapsibleBubble({
    super.key,
    required this.text,
    this.attachment,
    this.hideActions = false,
  });

  final String text;
  final Map<String, dynamic>? attachment;
  final bool hideActions;

  @override
  State<CollapsibleBubble> createState() => _CollapsibleBubbleState();
}

class _CollapsibleBubbleState extends State<CollapsibleBubble> {
  static const _collapseThreshold = 200;
  static const _bubbleFontSize = 17.0;
  static const _collapsedMaxHeight = _bubbleFontSize * 11;

  bool _expanded = false;
  bool _copied = false;
  bool _showCopyAction = false;
  bool _hovering = false;

  void _handleBubbleTap(bool shouldCollapse) {
    if (widget.hideActions && shouldCollapse) {
      setState(() => _expanded = !_expanded);
      return;
    }
    if (!widget.hideActions) {
      setState(() => _showCopyAction = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.text;
    final hasText = text.trim().isNotEmpty;
    final shouldCollapse = text.length > _collapseThreshold;
    final collapsed = shouldCollapse && !_expanded;
    final hasAttachment = widget.attachment != null;

    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        AttachmentBubblePreview(attachment: widget.attachment),
        if (hasText) ...[
          if (hasAttachment) const SizedBox(height: 4),
          GestureDetector(
            onTap: () => _handleBubbleTap(shouldCollapse),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              clipBehavior: Clip.hardEdge,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: collapsed ? _collapsedMaxHeight : double.infinity,
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        12,
                        16,
                        collapsed ? 32 : 12,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF0EFE9),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(4),
                        ),
                      ),
                      child: Text(
                        text,
                        style: const TextStyle(
                          fontSize: _bubbleFontSize,
                          color: Color(0xFF111827),
                          height: 1.625,
                        ),
                      ),
                    ),
                    if (collapsed)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 36,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                const Color(0xFFFBFBF9).withValues(alpha: 0),
                                const Color(0xFFFBFBF9).withValues(alpha: 0.8),
                                const Color(0xFFFBFBF9),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (!widget.hideActions)
            Align(
              alignment: Alignment.centerLeft,
              widthFactor: 1,
              heightFactor: 0,
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (shouldCollapse)
                      InkWell(
                        onTap: () => setState(() => _expanded = !_expanded),
                        borderRadius: BorderRadius.circular(6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _expanded ? 'Show less' : 'Show more',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF9E9B93),
                              ),
                            ),
                            Icon(
                              _expanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              size: 12,
                              color: const Color(0xFF9E9B93),
                            ),
                          ],
                        ),
                      )
                    else
                      const SizedBox.shrink(),
                    InkWell(
                      onTap: _copy,
                      borderRadius: BorderRadius.circular(8),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 120),
                        opacity: _copied || _showCopyAction || _hovering ? 1 : 0,
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            _copied ? Icons.check : Icons.content_copy,
                            size: 14,
                            color: const Color(0xFF9E9B93),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );

    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.85,
        ),
        child: widget.hideActions
            ? column
            : MouseRegion(
                onEnter: (_) => setState(() => _hovering = true),
                onExit: (_) => setState(() => _hovering = false),
                child: column,
              ),
      ),
    );
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.text));
    setState(() => _copied = true);
    Future<void>.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() => _copied = false);
    });
  }
}
