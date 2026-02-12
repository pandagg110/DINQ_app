import 'package:dinq_app/utils/color_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../common/base_page.dart';
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
    _controller.selection = TextSelection.collapsed(offset: start + emoji.length);
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

        // 输入框区域（与 H5 p-4 对应）
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: SafeArea(
            top: false,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFD8D8D8), width: 1),
                borderRadius: BorderRadius.circular(24),
                color: widget.disabled ? const Color(0xFFF9F9F9) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              constraints: BoxConstraints(minHeight: 50),
              padding: const EdgeInsets.only(left: 8, right: 4, bottom: 5),
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
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.2,
                          fontFamily: 'Geist',
                          color: widget.disabled ? Colors.grey[400] : null,
                        ),
                        decoration: InputDecoration(
                          hintText: widget.placeholder,
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 15,
                            fontFamily: 'Geist',
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                          isDense: true,
                        ),
                      ),
                    ),
                  ),

                  // 表情按钮
                  GestureDetector(
                    onTap: widget.disabled ? null : _toggleEmojiPicker,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _showEmojiPicker ? Color(0xFF1487fa) : Colors.transparent,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Color(0x12303030), width: 1),
                      ),
                      child: Center(
                        child: AssetImageView(
                          _showEmojiPicker ? "inbox_keyboard" : "inbox_emoji",
                          width: 24,
                          height: 24,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // 发送按钮（与 H5 移动端 px-2.5 py-2.5 对应）
                  NormalButton(
                    onTap: () {
                      if (_hasContent && !widget.disabled) {
                        _handleSend();
                      }
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: (_hasContent && !widget.disabled)
                            ? ColorUtil.textColor
                            : Color(0x47303030),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          'assets/icons/send-message.svg',
                          width: 16,
                          height: 16,
                          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                        ),
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
