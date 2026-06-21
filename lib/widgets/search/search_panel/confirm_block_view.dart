import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';

import '../../../stores/quick_replies_store.dart';
import '../../../utils/parse_quick_replies.dart';
import '../deep_search/deep_search_models.dart';
import 'narration_text.dart';

const startSearchLabel = 'Start search';

/// 与 TSX `ConfirmBlock.tsx` / `ConfirmBlockView` 对齐。
class ConfirmBlockView extends StatefulWidget {
  const ConfirmBlockView({
    super.key,
    required this.block,
    required this.onStartSearch,
  });

  final ReasoningBlock block;
  final void Function(String query, String displayQuery) onStartSearch;

  @override
  State<ConfirmBlockView> createState() => _ConfirmBlockViewState();
}

class _ConfirmBlockViewState extends State<ConfirmBlockView> {
  late final TextEditingController _controller;
  bool _lockedDraft = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _textareaBody());
  }

  @override
  void didUpdateWidget(covariant ConfirmBlockView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final body = _textareaBody();
    if (widget.block.isStreaming) {
      if (_controller.text != body) {
        _controller.text = body;
      }
    } else if (!_lockedDraft) {
      _lockedDraft = true;
      if (_controller.text != body) {
        _controller.text = body;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _cleanText() {
    // search_v2 将确认文案放在 envelope 的 `content` 字段，与 TSX parseEnvelope 对齐。
    return parseEnvelope(widget.block.text).cleanText;
  }

  String _textareaBody() {
    return splitConfirmContent(_cleanText()).textareaBody;
  }

  ({String intro, String textareaBody}) get _split {
    return splitConfirmContent(_cleanText());
  }

  @override
  Widget build(BuildContext context) {
    final split = _split;
    final isLocked = widget.block.isStreaming;
    final value = _controller.text;
    final isConsumed =
        context.watch<QuickRepliesStore>().isUsed(widget.block.id);

    if (isConsumed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (split.intro.isNotEmpty) _IntroProse(intro: split.intro),
            if (value.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E3DE)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Icon(
                        Icons.search,
                        size: 16,
                        color: Color(0xFF6B6862),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          height: 1.6,
                          color: Color(0xFF4A4845),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (split.intro.isNotEmpty) _IntroProse(intro: split.intro),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E3DE)),
            ),
            child: TextField(
              controller: _controller,
              readOnly: isLocked,
              maxLines: null,
              minLines: 4,
              style: const TextStyle(
                fontSize: 15,
                height: 1.6,
                color: Color(0xFF4A4845),
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: 'Edit your search criteria…',
                hintStyle: TextStyle(color: Color(0xFFA5A39E)),
              ),
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: isLocked || value.trim().isEmpty
                  ? null
                  : () {
                      context
                          .read<QuickRepliesStore>()
                          .markUsed(widget.block.id);
                      widget.onStartSearch(value.trim(), startSearchLabel);
                    },
              icon: const Icon(Icons.search, size: 16),
              label: const Text(startSearchLabel),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2A2826),
                disabledBackgroundColor: const Color(0xFFA5A39E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroProse extends StatelessWidget {
  const _IntroProse({required this.intro});

  final String intro;

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: intro,
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
      ),
    );
  }
}
