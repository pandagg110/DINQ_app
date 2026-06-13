import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../utils/display_assistant_text.dart';
import '../../../utils/parse_quick_replies.dart';
import 'quick_replies_widget.dart';

/// 与 TSX NarrationBlockView 对应：Markdown 叙述 + 快捷回复
class AssistantNarrationView extends StatelessWidget {
  const AssistantNarrationView({
    super.key,
    required this.text,
    required this.blockId,
    this.isStreaming = false,
    this.showQuickReplies = false,
    this.quickRepliesUsed = false,
    this.hasCandidates = false,
    this.onQuickReplySelect,
  });

  final String text;
  final String blockId;
  final bool isStreaming;
  final bool showQuickReplies;
  final bool quickRepliesUsed;
  final bool hasCandidates;
  final ValueChanged<String>? onQuickReplySelect;

  @override
  Widget build(BuildContext context) {
    final displayText = displayAssistantText(
      rawText: text,
      hasCandidates: hasCandidates,
      quickRepliesUsed: quickRepliesUsed,
    );
    final parsed = parseQuickReplies(
      text.replaceFirst(RegExp(r'^\s*\[confirm\]\s*', caseSensitive: false), ''),
    );
    final hasContent = displayText.isNotEmpty || parsed.options.isNotEmpty;

    if (!hasContent && isStreaming) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: _TypingDots(),
      );
    }

    if (!hasContent) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (displayText.isNotEmpty)
          MarkdownBody(
            data: displayText,
            selectable: true,
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Color(0xFF4A4845),
              ),
              strong: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF3A3835),
              ),
              h1: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2A2826),
              ),
              h2: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2A2826),
              ),
              h3: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3A3835),
              ),
              blockquote: const TextStyle(
                color: Color(0xFF8A8880),
                fontStyle: FontStyle.normal,
              ),
              code: const TextStyle(
                fontSize: 13,
                color: Color(0xFF4A4845),
                backgroundColor: Color(0xFFF5F4EF),
              ),
              listBullet: const TextStyle(color: Color(0xFFA5A39E)),
            ),
          ),
        if (isStreaming && parsed.options.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: _TypingDots(),
          ),
        if (parsed.options.isNotEmpty &&
            showQuickReplies &&
            onQuickReplySelect != null)
          QuickRepliesWidget(
            options: parsed.options,
            onSelect: onQuickReplySelect!,
          ),
      ],
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = (_controller.value + i * 0.2) % 1.0;
            final opacity = 0.3 + (t < 0.5 ? t * 1.4 : (1 - t) * 1.4);
            return Container(
              margin: const EdgeInsets.only(right: 6),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: const Color(0xFFD1D5DB).withOpacity(opacity.clamp(0.3, 1.0)),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}
