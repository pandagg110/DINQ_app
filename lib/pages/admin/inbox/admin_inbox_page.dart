import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../models/message_models.dart';
import '../../../stores/messages_store.dart';
import '../../../stores/notifications_store.dart';
import '../../../stores/user_store.dart';
import '../../../widgets/inbox/delete_conversation_modal.dart';
import '../../../widgets/common/base_page.dart';

/// Inbox 主页面 - 对话列表
class AdminInboxPage extends StatefulWidget {
  const AdminInboxPage({super.key});

  @override
  State<AdminInboxPage> createState() => _AdminInboxPageState();
}

class _AdminInboxPageState extends State<AdminInboxPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  List<Conversation>? _searchResults;
  bool _isSearching = false;
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final messagesStore = context.read<MessagesStore>();
      final notificationsStore = context.read<NotificationsStore>();
      messagesStore.loadConversations();
      notificationsStore.loadNotifications();
      messagesStore.connectWebSocket();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = null;
        _isSearching = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    _searchDebounce = Timer(const Duration(milliseconds: 300), () async {
      final results = await context.read<MessagesStore>().searchConversations(query.trim());
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    });
  }

  void _onSelectConversation(Conversation conversation) {
    context.read<MessagesStore>().setCurrentConversation(conversation);
    context.push('/admin/inbox/${conversation.id}');
  }

  @override
  Widget build(BuildContext context) {
    final messagesStore = context.watch<MessagesStore>();
    final notificationsStore = context.watch<NotificationsStore>();

    // 只在 userId 未设置时初始化一次
    if (_currentUserId.isEmpty) {
      final userStore = context.read<UserStore>();
      _currentUserId = userStore.user?.user.id ?? '';
      if (_currentUserId.isNotEmpty) {
        messagesStore.setCurrentUserId(_currentUserId);
      }
    }

    final currentUserId = _currentUserId;
    final conversations = _searchResults ?? messagesStore.conversations;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 安全区域顶部
          SizedBox(height: MediaQuery.of(context).padding.top),

          // 标题 + 搜索
          _buildHeader(),

          // 列表
          Expanded(
            child: messagesStore.isLoadingConversations
                ? _buildLoadingSkeleton()
                : ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      // 通知入口
                      _buildNotificationEntry(notificationsStore),

                      // 对话列表
                      ...conversations.map((conv) => _buildConversationItem(
                            conv,
                            currentUserId,
                          )),

                      // 空状态
                      if (conversations.isEmpty && !_isSearching)
                        _buildEmptyState(),

                      // 底部安全区域
                      SizedBox(height: MediaQuery.of(context).padding.bottom + 80),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Inbox',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Color(0xFF171717),
              fontFamily: 'Geist',
            ),
          ),
          const SizedBox(height: 16),
          // 搜索框
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Icon(Icons.search, size: 20, color: Colors.grey[400]),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'Geist',
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search names...',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                        fontFamily: 'Geist',
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
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

  /// 通知入口
  Widget _buildNotificationEntry(NotificationsStore store) {
    final hasUnread = store.unreadCount > 0;
    final latestNotification = store.notifications.isNotEmpty ? store.notifications.first : null;

    return InkWell(
      onTap: () => context.push('/admin/inbox/notifications'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
        ),
        child: Row(
          children: [
            // 通知图标
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Color(0xFF171717),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/icons/bell-notifications.svg',
                      width: 28,
                      height: 28,
                      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                    ),
                  ),
                ),
                if (hasUnread)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 22),
                      height: 22,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        store.unreadCount > 99 ? '99+' : '${store.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Geist',
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // 内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Notifications',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF171717),
                            fontFamily: 'Geist',
                          ),
                        ),
                      ),
                      if (latestNotification != null)
                        Text(
                          formatMessageDate(latestNotification.createdAt),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[500],
                            fontFamily: 'Geist',
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    latestNotification?.title ?? 'No new notifications',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontFamily: 'Geist',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 对话项
  Widget _buildConversationItem(Conversation conv, String currentUserId) {
    final display = getConversationDisplay(conv, currentUserId);
    final otherMember = conv.members.where((m) => m.userId != currentUserId).firstOrNull;

    return InkWell(
      onTap: () => _onSelectConversation(conv),
      onLongPress: () => _showDeleteMenu(conv, display.name),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
        ),
        child: Row(
          children: [
            // 头像
            Stack(
              children: [
                _buildAvatar(display.avatar, display.name, 56),
                if (display.isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // 内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 名字 + 标签 + 时间
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                display.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF171717),
                                  fontFamily: 'Geist',
                                ),
                              ),
                            ),
                            // 标签
                            if (conv.tags != null && conv.tags!.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              ...conv.tags!.map((tag) => Container(
                                    margin: const EdgeInsets.only(right: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3E8FF),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      tag,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF7C3AED),
                                        fontFamily: 'Geist',
                                      ),
                                    ),
                                  )),
                            ],
                          ],
                        ),
                      ),
                      Text(
                        formatMessageDate(conv.lastMessageTime),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[500],
                          fontFamily: 'Geist',
                        ),
                      ),
                    ],
                  ),

                  // 职位
                  if (otherMember?.fullPosition != null && otherMember!.fullPosition!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            'assets/icons/bag-iconly-pro.svg',
                            width: 14,
                            height: 14,
                            colorFilter: ColorFilter.mode(Colors.grey[400]!, BlendMode.srcIn),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              otherMember.fullPosition!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                                fontFamily: 'Geist',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // 最后消息 + 未读数
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            conv.lastMessageText ?? 'Enter your message description here...',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                              fontFamily: 'Geist',
                            ),
                          ),
                        ),
                        if (conv.unreadCount > 0)
                          Container(
                            constraints: const BoxConstraints(minWidth: 22),
                            height: 22,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              conv.unreadCount > 99 ? '99+' : '${conv.unreadCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Geist',
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String? avatarUrl, String name, double size) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return NetworkImageView(
        imageUrl: avatarUrl,
        width: size,
        height: size,
        borderRadius: BorderRadius.circular(size / 2),
        placeholder: _buildDefaultAvatar(name, size),
      );
    }
    return _buildDefaultAvatar(name, size);
  }

  Widget _buildDefaultAvatar(String name, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: size * 0.4,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      itemCount: 6,
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 16, width: 100, color: Colors.grey[200]),
                    const SizedBox(height: 8),
                    Container(height: 12, width: 150, color: Colors.grey[200]),
                    const SizedBox(height: 6),
                    Container(height: 12, width: 200, color: Colors.grey[200]),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _searchController.text.isNotEmpty ? 'No results found' : 'No conversations yet',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
                fontFamily: 'Geist',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchController.text.isNotEmpty
                  ? 'Try a different search term'
                  : 'Start a conversation to get started',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
                fontFamily: 'Geist',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteMenu(Conversation conv, String name) {
    DeleteConversationModal.show(
      context: context,
      conversationName: name,
      onConfirm: () async {
        await context.read<MessagesStore>().deleteConversation(conv.id);
      },
    );
  }
}
