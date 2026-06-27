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
  int _tab = 0; // 0 = Inbox, 1 = Notifications

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final messagesStore = context.read<MessagesStore>();
      final notificationsStore = context.read<NotificationsStore>();
      messagesStore.loadConversations();
      notificationsStore.loadNotifications();
      messagesStore.connectWebSocket();

      // 设置 WebSocket 错误回调
      messagesStore.onWsError = (message) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text(
              'Inbox Warning',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, fontFamily: 'Geist'),
            ),
            content: Text(
              message,
              style: const TextStyle(fontSize: 15, fontFamily: 'Geist'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      };
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

          // 列表（按 Tab 切换）
          Expanded(
            child: _tab == 0
                ? (messagesStore.isLoadingConversations
                    ? _buildLoadingSkeleton()
                    : ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          ...conversations.map((conv) => _buildConversationItem(
                                conv,
                                currentUserId,
                              )),
                          if (conversations.isEmpty && !_isSearching) _buildEmptyState(),
                          SizedBox(height: MediaQuery.of(context).padding.bottom + 80),
                        ],
                      ))
                : _buildNotificationsTab(notificationsStore),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 分段切换 Inbox / Notifications
          Container(
            height: 44,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF0EEEB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _segTab('Inbox', 0),
                _segTab('Notifications', 1),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // 搜索框（灰色填充，无分割线/双边框）
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF0EEEB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const SizedBox(width: 14),
                Icon(Icons.search, size: 20, color: Colors.grey[500]),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    style: const TextStyle(fontSize: 15, fontFamily: 'Geist'),
                    decoration: InputDecoration(
                      hintText: 'Search conversations',
                      hintStyle: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 15,
                        fontFamily: 'Geist',
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _segTab(String label, int index) {
    final active = _tab == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _tab = index),
        child: Container(
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: active
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 1))]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              color: active ? const Color(0xFF171717) : const Color(0xFF8A8880),
              fontFamily: 'Geist',
            ),
          ),
        ),
      ),
    );
  }

  /// Notifications Tab 内容（标题 + Mark read + 列表 / 空态）
  Widget _buildNotificationsTab(NotificationsStore store) {
    final notifications = store.notifications;
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(
            children: [
              const Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF171717),
                  fontFamily: 'Geist',
                ),
              ),
              const Spacer(),
              if (notifications.isNotEmpty)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => store.markAllRead(),
                  child: Row(
                    children: [
                      Icon(Icons.done_all_rounded, size: 16, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text('Mark read',
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey[500], fontFamily: 'Geist')),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (notifications.isEmpty)
          _buildNotificationsEmpty()
        else
          ...notifications.map(_buildNotificationItem),
        SizedBox(height: MediaQuery.of(context).padding.bottom + 80),
      ],
    );
  }

  Widget _buildNotificationsEmpty() {
    return Padding(
      padding: const EdgeInsets.only(top: 120),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(color: Color(0xFFF0EEEB), shape: BoxShape.circle),
            child: Icon(Icons.notifications_none_rounded, size: 26, color: Colors.grey[500]),
          ),
          const SizedBox(height: 16),
          const Text('No notifications yet',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF171717), fontFamily: 'Geist')),
          const SizedBox(height: 6),
          Text('New updates will appear here.',
              style: TextStyle(fontSize: 13, color: Colors.grey[500], fontFamily: 'Geist')),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(AppNotification n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6, right: 10),
            decoration: BoxDecoration(
              color: n.isRead ? Colors.transparent : const Color(0xFFEF4444),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(n.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600,
                              color: Color(0xFF171717), fontFamily: 'Geist')),
                    ),
                    Text(formatMessageDate(n.createdAt),
                        style: TextStyle(fontSize: 12, color: Colors.grey[500], fontFamily: 'Geist')),
                  ],
                ),
                if (n.content.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(n.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600], fontFamily: 'Geist')),
                ],
              ],
            ),
          ),
        ],
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
                            fixTruncatedUtf8(conv.lastMessageText).isNotEmpty
                                ? fixTruncatedUtf8(conv.lastMessageText)
                                : 'Enter your message description here...',
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
