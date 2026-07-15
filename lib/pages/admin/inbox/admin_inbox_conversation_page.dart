import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../models/message_models.dart';
import '../../../pages/profile/profile_page.dart';
import '../../../stores/card_store.dart';
import '../../../stores/messages_store.dart';
import '../../../stores/user_store.dart';
import '../../../stores/viewer_card_store.dart';
import '../../../widgets/common/base_page.dart';
import '../../../widgets/inbox/create_team_recruit_sheet.dart';
import '../../../widgets/inbox/delete_conversation_modal.dart';
import '../../../widgets/inbox/message_bubble.dart';
import '../../../widgets/inbox/message_input.dart';
import '../../../widgets/inbox/team_recruit_card.dart';

/// 对话详情页面
class AdminInboxConversationPage extends StatefulWidget {
  const AdminInboxConversationPage({super.key, required this.conversationId});

  final String conversationId;

  @override
  State<AdminInboxConversationPage> createState() => _AdminInboxConversationPageState();
}

class _AdminInboxConversationPageState extends State<AdminInboxConversationPage> {
  final ScrollController _scrollController = ScrollController();
  String? _lastReadMessageId;
  bool _hasTriedResolve = false;
  bool _isAtBottom = true;
  double _prevScrollExtent = 0;
  int _lastMessageCount = 0;
  bool _isInitialLoad = true;
  String _currentUserId = '';
  MessagesStore? _messagesStore;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _messagesStore = context.read<MessagesStore>();
      final userStore = context.read<UserStore>();
      _currentUserId = userStore.user?.user.id ?? '';
      if (_currentUserId.isNotEmpty) {
        _messagesStore!.setCurrentUserId(_currentUserId);
      }
      if (_messagesStore!.conversations.isEmpty) {
        _messagesStore!.loadConversations();
      }

      // 监听 messages 变化，处理滚动和已读
      _messagesStore!.addListener(_onStoreChanged);
    }
  }

  @override
  void dispose() {
    _messagesStore?.removeListener(_onStoreChanged);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// 监听 store 变化，处理滚动与已读（替代在 build 中直接调用）
  void _onStoreChanged() {
    if (!mounted || _messagesStore == null) return;
    final store = _messagesStore!;
    final messages = store.messages;

    // 处理滚动
    _handleMessageListUpdates(messages);

    // 标记已读
    _markAsRead(store, messages, _currentUserId);
  }

  void _onScroll() {
    final store = context.read<MessagesStore>();
    if (_scrollController.hasClients) {
      final max = _scrollController.position.maxScrollExtent;
      final offset = _scrollController.position.pixels;
      _isAtBottom = (max - offset) <= 80;
    }
    // 滚动到顶部附近时加载更多
    if (_scrollController.position.pixels < 100 &&
        store.hasMoreMessages &&
        !store.isLoadingMoreMessages) {
      _prevScrollExtent = _scrollController.position.maxScrollExtent;
      store.loadMoreMessages();
    }
  }

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (animate) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      }
    });
  }

  void _handleSendMessage(String content) {
    final store = context.read<MessagesStore>();
    if (store.currentConversation == null) return;
    store.sendTextMessage(store.currentConversation!.id, content);
    _scrollToBottom();
  }

  /// 发起组队（对齐 web CreateTeamRecruitModal：提交成功后立即
  /// 将返回的 team_recruit 消息入列，websocket 推送按 id 去重）。
  Future<void> _openCreateTeamRecruit(String conversationId) async {
    final store = context.read<MessagesStore>();
    final message = await CreateTeamRecruitSheet.show(
      context: context,
      conversationId: conversationId,
    );
    if (message != null && message.id.isNotEmpty) {
      store.addMessage(message);
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<MessagesStore>();
    final conversation = store.currentConversation;

    if (conversation == null) {
      if (store.isLoadingConversations) {
        return const Scaffold(
          backgroundColor: Colors.white,
          body: Center(child: CircularProgressIndicator()),
        );
      }

      if (store.conversations.isNotEmpty && !_hasTriedResolve) {
        _hasTriedResolve = true;
        final conv = store.conversations.where((c) => c.id == widget.conversationId).firstOrNull;
        if (conv != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            store.setCurrentConversation(conv);
          });
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator()),
          );
        }
      }

      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // 返回按钮
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Color(0xFF111827)),
                  onPressed: () => context.pop(),
                ),
              ),
              const Expanded(
                child: Center(
                  child: Text(
                    'Conversation not found',
                    style: TextStyle(fontSize: 16, color: Color(0xFF6B7280), fontFamily: 'Geist'),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final currentUserId = _currentUserId;
    final display = getConversationDisplay(conversation, currentUserId);
    final otherMember = conversation.members.where((m) => m.userId != currentUserId).firstOrNull;
    final messages = store.messages;
    final isGroup = conversation.conversationType == ConversationType.group;

    // 判断输入框是否禁用：所有消息都是当前用户发送的（对方还未接受）。
    // 单条消息限制仅适用于私聊，群聊（组织群/组队子群）不受限
    //（对齐 web inbox/[conversationId]/page.tsx:441-445 的 conversation_type === "private" 判断）
    final allFromCurrentUser =
        messages.isNotEmpty && messages.every((m) => m.senderId == currentUserId);
    final isInputDisabled = !store.isWsConnected || (!isGroup && allFromCurrentUser);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 安全区域
          SizedBox(height: MediaQuery.of(context).padding.top),

          // Header
          _buildHeader(context, display, otherMember, conversation),

          // 消息列表
          Expanded(
            child: store.isLoadingMessages
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                ? _buildEmptyMessages()
                : _buildMessageList(messages, currentUserId, conversation, store),
          ),

          // 输入框（群聊提供「发起组队」入口，
          // 对齐 web inbox/[conversationId]/page.tsx:456-458）
          MessageInput(
            onSendMessage: _handleSendMessage,
            disabled: isInputDisabled,
            placeholder: store.isWsConnected ? 'Send a message...' : 'Connecting...',
            onTeamRecruit: isGroup ? () => _openCreateTeamRecruit(conversation.id) : null,
          ),
        ],
      ),
    );
  }

  /// QA: 点头像/名字应打开 App 内原生个人主页，而不是跳外部浏览器。
  /// 复用 dinq_results_view._openProfile 的模式：ViewerCardStore + ProfilePage。
  void _handleProfileClick(ConversationMember? otherMember) {
    final username = otherMember?.username?.trim() ?? '';
    if (username.isEmpty) return;
    final viewerCardStore = context.read<ViewerCardStore>();
    Navigator.of(context).push<Object?>(
      MaterialPageRoute<Object?>(
        builder: (_) => ChangeNotifierProvider<CardStore>.value(
          value: viewerCardStore,
          child: ProfilePage(username: username, showAppBar: true),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ConversationDisplay display,
    ConversationMember? otherMember,
    Conversation conversation,
  ) {
    final profileUsername = otherMember?.username?.trim() ?? '';
    final hasProfile = profileUsername.isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: Row(
        children: [
          // 返回按钮
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Color(0xFF111827)),
            onPressed: () {
              context.read<MessagesStore>().setCurrentConversation(null);
              context.pop();
            },
          ),

          // 头像（可点击跳转 Profile）
          GestureDetector(
            onTap: hasProfile ? () => _handleProfileClick(otherMember) : null,
            child: Stack(
              children: [
                _buildAvatar(display.avatar, display.name, 44),
                if (display.isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // 名字和职位
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: GestureDetector(
                        onTap: hasProfile ? () => _handleProfileClick(otherMember) : null,
                        child: Text(
                          display.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF171717),
                            fontFamily: 'Geist',
                          ),
                        ),
                      ),
                    ),
                    if (conversation.tags != null && conversation.tags!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      ...conversation.tags!.map(
                        (tag) => Container(
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
                        ),
                      ),
                    ],
                  ],
                ),
                if (otherMember?.fullPosition != null && otherMember!.fullPosition!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          'assets/icons/bag-iconly-pro.svg',
                          width: 12,
                          height: 12,
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
              ],
            ),
          ),

          // 更多菜单
          _buildMenuButton(display.name),
        ],
      ),
    );
  }

  bool _showMenu = false;

  Widget _buildMenuButton(String convName) {
    return Builder(
      builder: (context) {
        return GestureDetector(
          onTap: () {
            setState(() => _showMenu = !_showMenu);
            if (_showMenu) {
              _showCustomMenu(context, convName);
            }
          },
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(Icons.more_vert, size: 22, color: Color(0xFF6B7280)),
          ),
        );
      },
    );
  }

  void _showCustomMenu(BuildContext context, String convName) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final buttonSize = button.size;
    final buttonPosition = button.localToGlobal(Offset.zero, ancestor: overlay);

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (dialogContext) {
        return Stack(
          children: [
            // 透明背景点击关闭
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  Navigator.of(dialogContext).pop();
                  setState(() => _showMenu = false);
                },
                child: Container(color: Colors.transparent),
              ),
            ),
            // 菜单
            Positioned(
              top: buttonPosition.dy + buttonSize.height - MediaQuery.of(context).padding.top,
              right: overlay.size.width - buttonPosition.dx - buttonSize.width,
              child: Container(
                constraints: const BoxConstraints(minWidth: 210),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD8D8D8)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A0E121B),
                      blurRadius: 32,
                      offset: Offset(0, 16),
                      spreadRadius: -12,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      Navigator.of(dialogContext).pop();
                      setState(() => _showMenu = false);
                      DeleteConversationModal.show(
                        context: context,
                        conversationName: convName,
                        onConfirm: () async {
                          final store = context.read<MessagesStore>();
                          await store.deleteConversation(widget.conversationId);
                          if (mounted) context.pop();
                        },
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AssetImageView("icon_delete_red", width: 24, height: 24),
                          const SizedBox(width: 10),
                          const Text(
                            'Delete Conversation',
                            style: TextStyle(
                              color: Color(0xFFC81E1D),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Geist',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ).then((_) {
      if (mounted) setState(() => _showMenu = false);
    });
  }

  Widget _buildEmptyMessages() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
              fontFamily: 'Geist',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Send a message to start the conversation',
            style: TextStyle(fontSize: 14, color: Colors.grey[400], fontFamily: 'Geist'),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(
    List<Message> messages,
    String currentUserId,
    Conversation conversation,
    MessagesStore store,
  ) {
    // 提前计算不变量，避免在 itemBuilder 中重复计算（O(n²) → O(n)）
    final isPrivate = conversation.conversationType == ConversationType.private_;
    final showAvatar = conversation.conversationType == ConversationType.group;
    final otherMember = conversation.members.where((m) => m.userId != currentUserId).firstOrNull;
    final lastReadMsgIndex = otherMember?.lastReadMessageId != null
        ? messages.indexWhere((m) => m.id == otherMember!.lastReadMessageId)
        : -1;
    final allFromCurrentUser =
        messages.isNotEmpty && messages.every((m) => m.senderId == currentUserId);

    // 构建 senderId → member 的查找表
    final memberMap = <String, ConversationMember>{};
    for (final m in conversation.members) {
      memberMap[m.userId] = m;
    }

    // 总 item 数 = 加载更多指示器(1) + 消息数
    final itemCount = messages.length + 1;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // 第一项：加载更多指示器
        if (index == 0) {
          if (store.isLoadingMoreMessages) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  'Loading more messages...',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B7280), fontFamily: 'Geist'),
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }

        final msgIndex = index - 1;
        final message = messages[msgIndex];

        // 组队招募：被删除（recalled）的隐藏；否则渲染专用卡片
        if (message.messageType == MessageType.teamRecruit) {
          if (message.isRecalled) return const SizedBox.shrink();
          return TeamRecruitCard(message: message, currentUserId: currentUserId);
        }

        final isOwnMessage = message.senderId == currentUserId;
        final sender = memberMap[message.senderId];

        // 已读状态
        final isRead = isOwnMessage && lastReadMsgIndex != -1 && msgIndex <= lastReadMsgIndex;

        // 日期分割线（转为本地时区比较）
        final currentDate = DateTime.tryParse(message.createdAt)?.toLocal();
        final prevMessage = msgIndex > 0 ? messages[msgIndex - 1] : null;
        final prevDate = prevMessage != null
            ? DateTime.tryParse(prevMessage.createdAt)?.toLocal()
            : null;
        final showDateDivider =
            currentDate != null &&
            (prevDate == null ||
                currentDate.year != prevDate.year ||
                currentDate.month != prevDate.month ||
                currentDate.day != prevDate.day);

        // 未读消息分割线
        final showUnreadDivider =
            store.unreadMessageStartIndex != null && msgIndex == store.unreadMessageStartIndex;

        // 消息限制警告（仅私聊，对齐 web inbox 页 conversation_type === "private" 判断）
        final isLastMessage = msgIndex == messages.length - 1;
        final showRestrictionWarning =
            isPrivate && isLastMessage && isOwnMessage && allFromCurrentUser;

        return Column(
          children: [
            // 日期分割线（showDateDivider 已包含 currentDate != null 检查）
            if (showDateDivider) _buildDivider(getDateDividerText(currentDate!)),

            // 未读分割线
            if (showUnreadDivider) _buildDivider('Unread messages'),

            // 消息气泡
            MessageBubble(
              message: message,
              isOwnMessage: isOwnMessage,
              showAvatar: showAvatar,
              senderName: sender?.name ?? sender?.displayName ?? sender?.username,
              senderAvatar: sender?.avatarUrl,
              isRead: isRead,
            ),

            // 消息限制警告
            if (showRestrictionWarning)
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDE277),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'You can only send one message request until they accept or reply.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, fontFamily: 'Geist'),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDivider(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey[200], height: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: Colors.grey[500], fontFamily: 'Geist'),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey[200], height: 1)),
        ],
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
      decoration: const BoxDecoration(color: Color(0xFFE5E7EB), shape: BoxShape.circle),
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

  void _markAsRead(MessagesStore store, List<Message> messages, String currentUserId) {
    if (store.currentConversation == null || !store.isWsConnected || messages.isEmpty) return;

    final lastMessage = messages.last;
    if (_lastReadMessageId == lastMessage.id) return;

    final isOwnMessage = lastMessage.senderId == currentUserId;
    if (!isOwnMessage) {
      store.sendReadReceipt(store.currentConversation!.id, lastMessage.id);
      _lastReadMessageId = lastMessage.id;
      if (store.currentConversation!.unreadCount > 0) {
        store.markConversationAsRead(store.currentConversation!.id);
      }
    } else {
      _lastReadMessageId = lastMessage.id;
    }
  }

  void _handleMessageListUpdates(List<Message> messages) {
    if (messages.length == _lastMessageCount) {
      return;
    }

    final isFirstLoad = _isInitialLoad && _lastMessageCount == 0 && messages.isNotEmpty;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;

      // 首次加载完成 → 直接跳到底部（与 H5 一致）
      if (isFirstLoad) {
        _isInitialLoad = false;
        _scrollController.jumpTo(max);
        _lastMessageCount = messages.length;
        return;
      }

      // 加载更多后保持滚动位置
      if (_prevScrollExtent > 0) {
        final diff = max - _prevScrollExtent;
        if (diff > 0) {
          _scrollController.jumpTo(_scrollController.position.pixels + diff);
        }
        _prevScrollExtent = 0;
        _lastMessageCount = messages.length;
        return;
      }

      // 新消息时，只有在用户在底部附近才自动滚动
      if (_isAtBottom) {
        _scrollToBottom();
      }
      _lastMessageCount = messages.length;
    });
  }
}
