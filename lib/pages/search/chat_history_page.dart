import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../pages/settings/settings_subscription_page.dart';
import '../../stores/chat_history_store.dart';
import '../../stores/search_store.dart';
import '../../stores/user_store.dart';
import '../../widgets/search/history/chat_history_item_widget.dart';
import '../../widgets/search/history/chat_history_skeleton_widget.dart';

/// 与 TSX MobileSearchHistory 一致：New Chat = fullReset + 关闭侧栏 + /search
class ChatHistoryPage extends StatefulWidget {
  const ChatHistoryPage({super.key, this.onClose, this.isOpen = true});

  final VoidCallback? onClose;
  final bool isOpen;

  @override
  State<ChatHistoryPage> createState() => _ChatHistoryPageState();
}

class _ChatHistoryPageState extends State<ChatHistoryPage> {
  bool _hasLoaded = false;
  bool _isLoadingMoreScheduled = false;
  String _query = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadIfNeeded();
  }

  @override
  void didUpdateWidget(ChatHistoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen && !oldWidget.isOpen) {
      _loadIfNeeded();
    }
  }

  void _loadIfNeeded() {
    if (_hasLoaded || !widget.isOpen) return;
    _hasLoaded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ChatHistoryStore>().loadConversations('');
    });
  }

  void _handleNewChat() {
    context.read<ChatHistoryStore>().setActiveConversationId(null);
    context.read<SearchStore>().clearAll();
    widget.onClose?.call();
    context.go('/search');
  }

  List<ConversationItem> _filteredConversations(List<ConversationItem> items) {
    final normalized = _query.trim().toLowerCase();
    if (normalized.isEmpty) return items;
    return items
        .where(
          (c) => (c.title.isNotEmpty ? c.title : 'Untitled')
              .toLowerCase()
              .contains(normalized),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final userStore = context.watch<UserStore>();
    final subscription = userStore.subscription;
    final basePlan = subscription?.basePlan ?? 'free';
    final credits = subscription?.creditsBalance ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F3),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _handleNewChat,
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: Center(
                            child: SvgPicture.asset(
                              'assets/logo/dinq-black.svg',
                              width: 24,
                              height: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Search history',
                      prefixIcon: const Icon(
                        Icons.search,
                        size: 16,
                        color: Color(0xFF9e9b93),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE6E1DA)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE6E1DA)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: TextButton.icon(
                      onPressed: _handleNewChat,
                      icon: const Icon(
                        Icons.add,
                        size: 16,
                        color: Color(0xFF171717),
                      ),
                      label: const Text(
                        'New chat',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF171717),
                        ),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFEEEDE9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Selector<ChatHistoryStore, List<ConversationItem>>(
                selector: (_, store) => store.conversations,
                builder: (context, conversations, _) {
                  final chatStore = context.watch<ChatHistoryStore>();
                  final searchStore = context.watch<SearchStore>();
                  final normalizedQuery = _query.trim();
                  final filteredItems = _filteredConversations(conversations);
                  return _buildList(
                    chatStore: chatStore,
                    foregroundSearchingSessionId: searchStore.isSearching
                        ? searchStore.deepSearchSessionId
                        : null,
                    filteredItems: filteredItems,
                    normalizedQuery: normalizedQuery,
                    onItemClick: (item) => _handleItemClick(context, item),
                  );
                },
              ),
            ),
            _buildFooter(context, basePlan: basePlan, credits: credits),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(
    BuildContext context, {
    required String basePlan,
    required int credits,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE6E1DA))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  getPlanLabel(basePlan),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF171717),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () {
                  widget.onClose?.call();
                  context.push('/settings/credits');
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      'assets/images/card/thunder-fold.svg',
                      width: 16,
                      height: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      credits.toString(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF171717),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      size: 14,
                      color: Color(0xFF8a8880),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Row(
            children: [
              Icon(
                Icons.card_giftcard_outlined,
                size: 16,
                color: Color(0xFF6b6862),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Invite friends, earn credits',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6b6862)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    widget.onClose?.call();
                    context.push('/me/invite');
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF2a2826),
                    side: BorderSide.none,
                    minimumSize: const Size(0, 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Invite', style: TextStyle(fontSize: 14)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    widget.onClose?.call();
                    context.push('/pricing');
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF171717),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Upgrade', style: TextStyle(fontSize: 14)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildList({
    required ChatHistoryStore chatStore,
    required String? foregroundSearchingSessionId,
    required List<ConversationItem> filteredItems,
    required String normalizedQuery,
    required void Function(ConversationItem) onItemClick,
  }) {
    if (chatStore.isLoading && chatStore.conversations.isEmpty) {
      return const ChatHistorySkeletonWidget();
    }
    if (chatStore.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            chatStore.error!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Color(0xFF8a8880)),
          ),
        ),
      );
    }
    if (chatStore.conversations.isEmpty && !chatStore.hasMore()) {
      return const Center(
        child: Text(
          'No history yet',
          style: TextStyle(fontSize: 14, color: Color(0xFF8a8880)),
        ),
      );
    }
    if (normalizedQuery.isNotEmpty && filteredItems.isEmpty) {
      return const Center(
        child: Text(
          'No matching history',
          style: TextStyle(fontSize: 14, color: Color(0xFF8a8880)),
        ),
      );
    }

    final showLoadMore = normalizedQuery.isEmpty && chatStore.hasMore();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      itemCount: filteredItems.length + (showLoadMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= filteredItems.length) {
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
        final item = filteredItems[index];
        final isActive = chatStore.isActiveConversation(item);
        return ChatHistoryItemWidget(
          key: ValueKey('conv_${item.type}_${item.id}'),
          conversation: item,
          isActive: isActive,
          isCurrentLocalSearching:
              isActive && foregroundSearchingSessionId == item.id.toString(),
          onClick: () => onItemClick(item),
          onDelete: (id) =>
              chatStore.deleteConversationById(id, type: item.type),
        );
      },
    );
  }

  void _handleItemClick(BuildContext context, ConversationItem item) {
    context.read<ChatHistoryStore>().setActiveConversation(item);

    final route = item.type == 'discover'
        ? '/search/${item.id}'
        : '/search/${item.type}/${item.id}';

    widget.onClose?.call();
    context.go(route);
  }
}
