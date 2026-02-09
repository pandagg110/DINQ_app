import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../stores/chat_history_store.dart';

const double sidebarWidth = 220.0;

class ChatHistorySidebarWidget extends StatelessWidget {
  const ChatHistorySidebarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatHistoryStore>(
      builder: (context, store, _) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: store.isCollapsed ? 0 : sidebarWidth,
          color: const Color(0xFFFDFDFD),
          child: store.isCollapsed
              ? const SizedBox.shrink()
              : Column(
                  children: [
                    // Header
                    Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Color(0xFFE5E5E5))),
                      ),
                      child: Row(
                        children: [
                          // TODO: 添加历史图标
                          const SizedBox(width: 6),
                          const Text(
                            'Chat History',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF171717),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            padding: EdgeInsets.zero,
                            iconSize: 16,
                            icon: const Icon(Icons.unfold_less),
                            color: const Color(0xFF6B7280),
                            onPressed: () => store.toggleCollapse(),
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
        );
      },
    );
  }
}
