import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/user_models.dart';
import '../../stores/chat_history_store.dart';
import '../../stores/search_store.dart';
import '../../stores/user_store.dart';
import '../../widgets/search_bak/history/chat_history_empty_state_widget.dart';
import '../../widgets/search_bak/history/chat_history_item_widget.dart';
import '../../widgets/search_bak/history/chat_history_skeleton_widget.dart';
import '../../widgets/search_bak/history/new_chat_confirm_dialog.dart';

/// Chat History 页：与 TSX ChatHistorySidebar/ChatHistoryMobile 逻辑一致
/// 含 Header、Search(Pro/Plus)、New Chat、列表( free→locked / basic→1+mock+upgrade / 加载|错误|空|列表 )、Footer、NewChatConfirmDialog
class ChatHistoryPage extends StatefulWidget {
  const ChatHistoryPage({super.key, this.onClose});

  /// 在左侧弹框内展示时传入，返回按钮和 New Chat 将调用此回调而非 Navigator.pop
  final VoidCallback? onClose;

  @override
  State<ChatHistoryPage> createState() => _ChatHistoryPageState();
}

class _ChatHistoryPageState extends State<ChatHistoryPage> {
  bool _hasLoaded = false;
  bool _isLoadingMoreScheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoaded) {
      _hasLoaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<ChatHistoryStore>().loadConversations();
      });
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

    void doNewChat() {
      chatStore.setActiveConversationId(null);
      searchStore.clearAll();
      if (widget.onClose != null) {
        widget.onClose!();
      } else {
        Navigator.of(context).pop();
      }
    }

    void handleNewChat() {
      // 使用根 Navigator 弹框，使确认框居中在整个窗口而非当前组件
      showDialog<void>(
        context: context,
        useRootNavigator: true,
        barrierDismissible: false,
        builder: (dialogContext) => NewChatConfirmDialog(
          isOpen: true,
          onClose: () => Navigator.of(dialogContext).pop(),
          onConfirm: () {
            doNewChat();
            Navigator.of(dialogContext).pop();
          },
          userPlan: basePlan,
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: SizedBox(
                    height: 40,
                    child: TextField(
                      onChanged: (v) {
                        chatStore.setSearchQuery(v);
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          context.read<ChatHistoryStore>().loadConversations();
                        });
                      },
                      readOnly: false,
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Search...',
                        prefixIcon: const Icon(
                          Icons.search,
                          size: 20,
                          color: Color(0xFF9CA3AF),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB),
                            width: 1,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 12,
                        ),
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),

                // New Chat button
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: handleNewChat,
                      icon: const Icon(
                        Icons.add,
                        size: 20,
                        color: Colors.black,
                      ),
                      label: const Text('New Chat'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF6F6F6),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
                // Search box - 始终显示（与 list 一致）
                // Conversation list：用 Selector 依赖 conversations，列表更新时必重建
                Expanded(
                  child: Selector<ChatHistoryStore, List<ConversationItem>>(
                    selector: (_, store) => store.conversations,
                    builder: (context, _, child) {
                      final chatStore = context.watch<ChatHistoryStore>();
                      return _buildList(
                        context,
                        chatStore: chatStore,
                        onItemClick: (item) => _handleItemClick(context, item),
                      );
                    },
                  ),
                ),
                // Footer - Total for Pro/Plus
                if (chatStore.total > 0)
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
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF636363),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
    BuildContext context, {
    required ChatHistoryStore chatStore,
    required void Function(ConversationItem) onItemClick,
  }) {
    return _buildListContent(
      context,
      chatStore: chatStore,
      onItemClick: onItemClick,
    );
  }

  /// 列表内容：所有用户都走统一真实会话接口（无 VIP 限制）
  Widget _buildListContent(
    BuildContext context, {
    required ChatHistoryStore chatStore,
    required void Function(ConversationItem) onItemClick,
  }) {
    if (chatStore.isLoading && chatStore.conversations.isEmpty) {
      return const ChatHistorySkeletonWidget();
    }
    if (chatStore.error != null) {
      return SingleChildScrollView(
        child: ChatHistoryEmptyStateWidget(
          type: 'error',
          message: chatStore.error,
        ),
      );
    }
    if (chatStore.conversations.isEmpty) {
      return SingleChildScrollView(
        child: ChatHistoryEmptyStateWidget(type: 'empty'),
      );
    }

    final list = chatStore.conversations;
    return ListView.builder(
      key: ValueKey('conversations_${list.length}_${list.hashCode}'),
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: list.length + (chatStore.hasMore() ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= list.length) {
          if (chatStore.hasMore()) {
            if (!_isLoadingMoreScheduled) {
              _isLoadingMoreScheduled = true;
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                if (!mounted) return;
                await context.read<ChatHistoryStore>().loadMore();
                if (mounted) _isLoadingMoreScheduled = false;
              });
            }
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          return const SizedBox.shrink();
        }
        final item = list[index];
        return ChatHistoryItemWidget(
          key: ValueKey('conv_${item.id}'),
          conversation: item,
          isActive: chatStore.isActiveConversation(item),
          onClick: () => onItemClick(item),
          onDelete: (id) => chatStore.deleteConversationById(id, type: item.type),
          onRename: (id, title) => chatStore.renameConversation(id, title, type: item.type),
        );
      },
    );
  }

  void _handleItemClick(BuildContext context, ConversationItem item) {
    final chatStore = context.read<ChatHistoryStore>();
    chatStore.setActiveConversation(item);

    // 与 dinq-client 一致：history 只负责路由跳转，详情拉取与恢复由 SearchPage 处理
    final route = item.type == 'discover'
        ? '/search/${item.id}'
        : '/search/${item.type}/${item.id}';

    context.go(route);
    widget.onClose?.call();
  }
}
