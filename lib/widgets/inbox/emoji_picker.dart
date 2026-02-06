import 'package:flutter/material.dart';

/// 内置表情选择器
class InboxEmojiPicker extends StatelessWidget {
  const InboxEmojiPicker({
    super.key,
    required this.onEmojiSelected,
    this.onClose,
  });

  final ValueChanged<String> onEmojiSelected;
  final VoidCallback? onClose;

  static const List<String> _emojis = [
    '😀', '😃', '😄', '😁', '😆', '😅', '🤣', '😂',
    '🙂', '🙃', '😉', '😊', '😇', '🥰', '😍', '🤩',
    '😘', '😗', '😚', '😙', '🥲', '😋', '😛', '😜',
    '🤪', '😝', '🤑', '🤗', '🤭', '🤫', '🤔', '🫡',
    '🤐', '🤨', '😐', '😑', '😶', '🫥', '😏', '😒',
    '🙄', '😬', '🤥', '😌', '😔', '😪', '🤤', '😴',
    '😷', '🤒', '🤕', '🤢', '🤮', '🥵', '🥶', '🥴',
    '😵', '🤯', '🥳', '🥺', '😢', '😭', '😤', '😠',
    '😡', '🤬', '👍', '👎', '👏', '🙌', '🤝', '❤️',
    '🔥', '💯', '✨', '🎉', '👋', '🤞', '✌️', '🤟',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        border: Border(
          top: BorderSide(color: Color(0xFFE5E7EB), width: 0.5),
        ),
      ),
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
        ),
        itemCount: _emojis.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => onEmojiSelected(_emojis[index]),
            child: Center(
              child: Text(
                _emojis[index],
                style: const TextStyle(fontSize: 28),
              ),
            ),
          );
        },
      ),
    );
  }
}
