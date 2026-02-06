import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'emoji_picker.dart';

/// 消息输入组件
class MessageInput extends StatefulWidget {
  const MessageInput({
    super.key,
    required this.onSendMessage,
    this.disabled = false,
    this.placeholder = 'Send a message...',
  });

  final ValueChanged<String> onSendMessage;
  final bool disabled;
  final String placeholder;

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showEmojiPicker = false;
  bool _hasContent = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasContent = _controller.text.trim().isNotEmpty;
      if (hasContent != _hasContent) {
        setState(() => _hasContent = hasContent);
      }
    });
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isNotEmpty && !widget.disabled) {
      widget.onSendMessage(text);
      _controller.clear();
      setState(() => _hasContent = false);
    }
  }

  void _toggleEmojiPicker() {
    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
      if (_showEmojiPicker) {
        _focusNode.unfocus();
      } else {
        _focusNode.requestFocus();
      }
    });
  }

  void _onEmojiSelected(String emoji) {
    final text = _controller.text;
    final selection = _controller.selection;
    // selection.start 可能为 -1（TextField 未获得焦点时），此时追加到末尾
    final start = selection.start >= 0 ? selection.start : text.length;
    final end = selection.end >= 0 ? selection.end : text.length;
    final newText = text.replaceRange(start, end, emoji);
    _controller.text = newText;
    _controller.selection = TextSelection.collapsed(
      offset: start + emoji.length,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 表情选择器
        if (_showEmojiPicker)
          InboxEmojiPicker(
            onEmojiSelected: _onEmojiSelected,
            onClose: () => setState(() => _showEmojiPicker = false),
          ),

        // 输入框
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Color(0xFFE5E7EB), width: 0.5),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(24),
                color: Colors.white,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // 文本输入
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 100),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        enabled: !widget.disabled,
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _handleSend(),
                        onTap: () {
                          if (_showEmojiPicker) {
                            setState(() => _showEmojiPicker = false);
                          }
                        },
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.3,
                          fontFamily: 'Geist',
                        ),
                        decoration: InputDecoration(
                          hintText: widget.placeholder,
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 15,
                            fontFamily: 'Geist',
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          isDense: true,
                        ),
                      ),
                    ),
                  ),

                  // 表情按钮
                  GestureDetector(
                    onTap: widget.disabled ? null : _toggleEmojiPicker,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        _showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions_outlined,
                        size: 22,
                        color: widget.disabled ? Colors.grey[300] : Colors.grey[600],
                      ),
                    ),
                  ),

                  // 发送按钮
                  GestureDetector(
                    onTap: (_hasContent && !widget.disabled) ? _handleSend : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: (_hasContent && !widget.disabled)
                            ? Colors.black
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(
                            'assets/icons/send-message.svg',
                            width: 16,
                            height: 16,
                            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
