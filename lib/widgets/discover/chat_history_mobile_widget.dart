import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../stores/chat_history_store.dart';

class ChatHistoryMobileWidget extends StatelessWidget {
  const ChatHistoryMobileWidget({
    super.key,
    required this.isOpen,
    required this.onClose,
  });

  final bool isOpen;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    if (!isOpen) {
      return const SizedBox.shrink();
    }

    return AnimatedSlide(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      offset: isOpen ? Offset.zero : const Offset(1.0, 0.0),
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Header
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE5E5E5))),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    color: const Color(0xFF171717),
                    onPressed: onClose,
                  ),
                  const SizedBox(width: 12),
                  // TODO: 添加历史图标
                  const Text(
                    'Chat History',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF171717),
                    ),
                  ),
                ],
              ),
            ),
            // TODO: 添加搜索框（仅 Pro/Plus 用户）
            // TODO: 添加 New Chat 按钮
            // TODO: 添加会话列表
            const Expanded(
              child: Center(
                child: Text(
                  'Chat History',
                  style: TextStyle(color: Color(0xFF9CA3AF)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
