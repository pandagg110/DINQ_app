import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'attachment_bubble_preview.dart';

/// 与 TSX CollapsibleBubble 对齐。
class CollapsibleBubble extends StatefulWidget {
  const CollapsibleBubble({
    super.key,
    required this.text,
    this.attachment,
  });

  final String text;
  final Map<String, dynamic>? attachment;

  @override
  State<CollapsibleBubble> createState() => _CollapsibleBubbleState();
}

class _CollapsibleBubbleState extends State<CollapsibleBubble> {
  static const _collapseThreshold = 200;

  bool _expanded = false;
  bool _copied = false;
  bool _showCopyAction = false;

  @override
  Widget build(BuildContext context) {
    final text = widget.text;
    final hasText = text.trim().isNotEmpty;
    final shouldCollapse = text.length > _collapseThreshold;
    final collapsed = shouldCollapse && !_expanded;

    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.85,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            AttachmentBubblePreview(attachment: widget.attachment),
            if (hasText) ...[
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => setState(() => _showCopyAction = true),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  constraints: collapsed
                      ? const BoxConstraints(maxHeight: 11 * 16)
                      : const BoxConstraints(),
                  clipBehavior: Clip.hardEdge,
                  decoration: const BoxDecoration(),
                  child: Stack(
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
                            fontSize: 17,
                            color: Color(0xFF111827),
                            height: 1.45,
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
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (shouldCollapse)
                      InkWell(
                        onTap: () => setState(() => _expanded = !_expanded),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _expanded ? 'Show less' : 'Show more',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF9E9B93),
                              ),
                            ),
                            Icon(
                              _expanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              size: 14,
                              color: const Color(0xFF9E9B93),
                            ),
                          ],
                        ),
                      )
                    else
                      const SizedBox.shrink(),
                    InkWell(
                      onTap: _copy,
                      child: Opacity(
                        opacity: _copied || _showCopyAction ? 1 : 0,
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
            ],
          ],
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
