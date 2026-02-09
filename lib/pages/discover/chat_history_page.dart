import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_models.dart';
import '../../stores/chat_history_store.dart';
import '../../stores/search_store.dart';
import '../../stores/user_store.dart';
import '../../widgets/discover/history/chat_history_empty_state_widget.dart';
import '../../widgets/discover/history/chat_history_item_widget.dart';
import '../../widgets/discover/history/chat_history_skeleton_widget.dart';
import '../../widgets/discover/history/mock_history_data.dart';
import '../../widgets/discover/history/new_chat_confirm_dialog.dart';

/// Chat History 页：与 TSX ChatHistorySidebar/ChatHistoryMobile 逻辑一致
/// 含 Header、Search(Pro/Plus)、New Chat、列表( free→locked / basic→1+mock+upgrade / 加载|错误|空|列表 )、Footer、NewChatConfirmDialog
class ChatHistoryPage extends StatefulWidget {
  const ChatHistoryPage({super.key});

  @override
  State<ChatHistoryPage> createState() => _ChatHistoryPageState();
}

class _ChatHistoryPageState extends State<ChatHistoryPage> {
  bool _hasLoaded = false;
  bool _showNewChatDialog = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoaded) {
      _hasLoaded = true;
      context.read<ChatHistoryStore>().loadConversations();
    }
  }

  String _basePlan(Subscription? sub) {
    if (sub == null) return 'free';
    return sub.basePlan;
  }

  @override
  Widget build(BuildContext context) {
    final chatStore = context.watch<ChatHistoryStore>();
    final userStore = context.watch<UserStore>();
    final searchStore = context.read<SearchStore>();
    final subscription = userStore.subscription;
    final basePlan = _basePlan(subscription);
    final isProOrPlus = basePlan == 'pro' || basePlan == 'plus';

    void doNewChat() {
      chatStore.setActiveConversationId(null);
      searchStore.clearAll();
      Navigator.of(context).pop();
    }

    void handleNewChat() {
      if (basePlan == 'free' ||
          (basePlan == 'basic' && chatStore.conversations.isNotEmpty)) {
        setState(() => _showNewChatDialog = true);
        return;
      }
      doNewChat();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF171717)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/icons/discover/clock-time-arrow.png',
              width: 24,
              height: 24,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.history,
                size: 24,
                color: Color(0xFF171717),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Chat History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF171717),
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // New Chat button
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: handleNewChat,
                      icon: const Icon(Icons.add, size: 20, color: Colors.white),
                      label: const Text('New Chat'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF171717),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ),
                // Search box - only for Pro/Plus
                if (isProOrPlus) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: TextField(
                      onChanged: (v) => chatStore.setSearchQuery(v),
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF9CA3AF)),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
                // Conversation list
                Expanded(
                  child: _buildList(
                    context,
                    chatStore: chatStore,
                    basePlan: basePlan,
                    isProOrPlus: isProOrPlus,
                    onItemClick: (item) => _handleItemClick(context, item),
                  ),
                ),
                // Footer - Total for Pro/Plus
                if (basePlan != 'free' && basePlan != 'basic' && chatStore.total > 0)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
                      color: Color(0xFFF9FAFB),
                    ),
                    child: Center(
                      child: Text(
                        '${chatStore.total} ${chatStore.total == 1 ? 'Conversation' : 'Conversations'} Total',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF636363)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_showNewChatDialog)
            NewChatConfirmDialog(
              isOpen: true,
              onClose: () => setState(() => _showNewChatDialog = false),
              onConfirm: () {
                doNewChat();
                setState(() => _showNewChatDialog = false);
              },
              userPlan: basePlan == 'basic' ? 'basic' : 'free',
            ),
        ],
      ),
    );
  }

  Widget _buildList(
    BuildContext context, {
    required ChatHistoryStore chatStore,
    required String basePlan,
    required bool isProOrPlus,
    required void Function(ConversationItem) onItemClick,
  }) {
    // Free: locked state
    if (basePlan == 'free') {
      return SingleChildScrollView(
        child: ChatHistoryEmptyStateWidget(type: 'locked'),
      );
    }

    // Basic: 1 real + mock blurred + upgrade_pro
    if (basePlan == 'basic') {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...chatStore.conversations.take(1).map(
                  (item) => ChatHistoryItemWidget(
                    conversation: item,
                    isActive: item.id == chatStore.activeConversationId,
                    onClick: () => onItemClick(item),
                    onDelete: (id) => chatStore.deleteConversation(id),
                    onRename: (id, title) => chatStore.renameConversation(id, title),
                  ),
                ),
            ...mockHistoryItems.map(
                  (item) => ChatHistoryItemWidget(
                    conversation: item,
                    isBlurred: true,
                    onClick: () {},
                    onDelete: (_) async => false,
                    onRename: (_, __) async => false,
                  ),
                ),
            ChatHistoryEmptyStateWidget(type: 'upgrade_pro'),
          ],
        ),
      );
    }

    // Pro/Plus: loading / error / empty / list
    if (chatStore.isLoading && chatStore.conversations.isEmpty) {
      return const ChatHistorySkeletonWidget();
    }
    if (chatStore.error != null) {
      return SingleChildScrollView(
        child: ChatHistoryEmptyStateWidget(
          type: 'error',
          message: chatStore.error,
          tier: basePlan,
        ),
      );
    }
    if (chatStore.conversations.isEmpty) {
      return SingleChildScrollView(
        child: ChatHistoryEmptyStateWidget(type: 'empty'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: chatStore.conversations.length + (chatStore.hasMore() ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= chatStore.conversations.length) {
          if (chatStore.hasMore()) {
            chatStore.loadMore();
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          return const SizedBox.shrink();
        }
        final item = chatStore.conversations[index];
        return ChatHistoryItemWidget(
          conversation: item,
          isActive: item.id == chatStore.activeConversationId,
          onClick: () => onItemClick(item),
          onDelete: (id) => chatStore.deleteConversation(id),
          onRename: (id, title) => chatStore.renameConversation(id, title),
        );
      },
    );
  }

  Future<void> _handleItemClick(BuildContext context, ConversationItem item) async {
    final chatStore = context.read<ChatHistoryStore>();
    final searchStore = context.read<SearchStore>();

    chatStore.setActiveConversationId(item.id);
    searchStore.setLoadingConversation(true);

    try {
      // TODO: discoverApi.getConversationDetail(item.id) -> searchStore.loadConversation(detail)
      // 暂时仅清除 loading
      await Future.delayed(const Duration(milliseconds: 300));
      if (!context.mounted) return;
      searchStore.setLoadingConversation(false);
    } catch (_) {
      if (context.mounted) {
        chatStore.setActiveConversationId(null);
        searchStore.setLoadingConversation(false);
      }
    }
  }
}
