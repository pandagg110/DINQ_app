import 'dart:async';

import 'package:flutter_portal/flutter_portal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_constants.dart';
import '../../models/message_models.dart';
import '../../models/user_models.dart';
import '../../services/analytics_service.dart';
import '../../services/message_service.dart';
import '../../services/profile_service.dart';
import '../../utils/api_error.dart';
import '../../stores/card_store.dart';
import '../../stores/main_store.dart';
import '../../stores/messages_store.dart';
import '../../stores/user_store.dart';
import '../../stores/viewer_card_store.dart';
import '../../utils/add_image_card.dart';
import '../../widgets/cards/card_grid_staggered.dart';
import '../../widgets/cards/factory/card_registry.dart';
import '../../widgets/cards/factory/definitions/index.dart' show isSocialCard;
import '../../widgets/cards/placeholder/placeholder_config.dart';
import '../../widgets/common/add_card_dialog.dart';
import '../../theme/dinq_tokens.dart';
import '../../widgets/profile/mydinq_top_bar.dart';
import '../../widgets/profile/profile_header.dart';
import '../../widgets/profile/change_status_modal.dart';
import '../../widgets/profile/floating_toolbar.dart';
import '../../widgets/profile/share_profile_dialog.dart';
import '../../widgets/profile/card_toolbar.dart';
import '../../widgets/profile/preview_edit_toggle.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.username,
    this.showAppBar = false,
    this.showMyDinqTopBar = false,
    this.embeddedInMyDinq = false,
  });

  final String username;

  /// 为 true 时显示顶部 AppBar（含返回按钮），便于从 Discover 等 push 进入后返回
  final bool showAppBar;

  /// @deprecated 使用 [MyDinqPage] 壳层
  final bool showMyDinqTopBar;

  /// 嵌入 My DINQ 壳层：无 Scaffold/顶栏，默认编辑态
  final bool embeddedInMyDinq;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with WidgetsBindingObserver {
  final ProfileService _profileService = ProfileService();
  final MessageService _messageService = MessageService();
  bool _isLoading = true;
  bool _isStartingChat = false;
  int _totalViews = 0;
  UserData? _userData;
  bool _isStatusModalOpen = false;
  CardStore? _cardStore;

  /// true = 预览模式；My DINQ Page 标签下固定为 false（编辑态）
  bool _isPreviewMode = true;

  /// 埋点：本次路由访问是否已报过 dinq_page_view（State 随路由访问创建，
  /// 刷新/重建不重复上报）
  bool _dinqPageViewTracked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.embeddedInMyDinq) {
      _isPreviewMode = false;
    }
    _cardStore = widget.showAppBar
        ? context.read<ViewerCardStore>()
        : context.read<CardStore>();
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // 页面退出时清空卡片选中状态
    _cardStore?.clearSelection();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // 当应用进入后台或关闭时，清空选中状态
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _cardStore?.clearSelection();
    }
  }

  Future<void> _loadData() async {
    final cardStore = _cardStore!;
    await _refreshProfileData(checkInitialName: true);
    await cardStore.loadCards(widget.username);
    await _loadPageViewStats();
  }

  Future<void> _loadPageViewStats() async {
    try {
      final stats = await _profileService.getPageViewStats(
        widget.username,
        range: 'all',
      );
      if (!mounted) return;
      final total = stats['total_views'];
      setState(() {
        _totalViews = total is num ? total.toInt() : 0;
      });
    } catch (_) {
      // Footer stats are non-critical; keep the page usable if this fails.
    }
  }

  Future<void> _refreshProfileData({bool checkInitialName = false}) async {
    try {
      final userData = await _profileService.getUserData(widget.username);
      if (!mounted) return;
      setState(() {
        _userData = userData;
        _isLoading = false;
      });
      context.read<UserStore>().setCardOwner(userData);

      // 参考 tsx 逻辑：只有当是当前用户自己的 profile 且 name 为空时，弹出设置 name 的 dialog
      final userStore = context.read<UserStore>();
      final isLoggedIn = userStore.isLoggedIn();
      final currentUserDomain = userStore.user?.userData.domain;
      final userDataDomain = userData.domain;
      final isEditable = isLoggedIn && currentUserDomain == userDataDomain;

      // 埋点：DINQ Page 首次完成展示（一次路由访问一次；域名/用户名不上报）
      if (!_dinqPageViewTracked) {
        _dinqPageViewTracked = true;
        AnalyticsService.instance.track(
          'dinq_page_view',
          params: {'is_owner': isEditable ? 'true' : 'false'},
          activationIntent: 'dinq_page',
        );
      }

      final myFlow = userStore.myFlow;
      final flowStatus = myFlow?.status;
      final nameIsEmpty = userData.name.isEmpty || userData.name.trim().isEmpty;

      if (mounted &&
          checkInitialName &&
          isEditable &&
          flowStatus == 'success' &&
          nameIsEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showSetNameDialog();
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showSetNameDialog() async {
    final nameController = TextEditingController();

    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return _SetNameDialog(
          nameController: nameController,
          onSave: () async {
            final name = nameController.text.trim();
            if (name.isEmpty) {
              return;
            }

            try {
              final userStore = context.read<UserStore>();
              await userStore.updateUserData({'name': name});

              if (mounted && dialogContext.mounted) {
                Navigator.of(dialogContext).pop(true);
                // 刷新数据
                await _refreshProfileData();
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Failed to save. Please try again.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        );
      },
    );

    nameController.dispose();
  }

  void _handlePreviewModeChanged(bool isPreview) {
    setState(() => _isPreviewMode = isPreview);
    if (widget.embeddedInMyDinq) return;
    if (!isPreview) {
      context.read<MainStore>().hideBottomNavigation();
    } else {
      context.read<MainStore>().showBottomNavigation();
    }
  }

  PreferredSizeWidget? _buildAppBar({
    required BuildContext context,
    required bool isEditable,
    UserData? userData,
    bool isSaving = false,
  }) {
    if (widget.showMyDinqTopBar) {
      return MyDinqTopBar(
        context,
        isPageTab: _isPreviewMode,
        onTabChanged: _handlePreviewModeChanged,
        isSaving: isSaving,
        onShare: () {
          if (_userData == null) return;
          ShareProfileDialog.show(
            context: context,
            username: widget.username,
            userData: _userData!,
            cards: _cardStore?.cards,
          );
        },
      );
    }
    if (widget.showAppBar) {
      // 站内私信：仅当查看的是「已注册且有主页」的他人主页（有 user_id 且非本人）时显示
      final canMessage =
          userData != null &&
          userData.userId.isNotEmpty &&
          !_isEditable(userData);
      return AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          (userData?.name ?? '').isNotEmpty ? userData!.name : widget.username,
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF171717),
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          if (canMessage)
            IconButton(
              tooltip: 'Message',
              icon: _isStartingChat
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chat_bubble_outline_rounded),
              onPressed: _isStartingChat ? null : () => _startChat(userData),
            ),
        ],
      );
    }
    return null;
  }

  bool get _hasTopBar =>
      !widget.embeddedInMyDinq &&
      (widget.showAppBar || widget.showMyDinqTopBar);

  bool get _isEditMode =>
      widget.embeddedInMyDinq ||
      (!_isPreviewMode && _userData != null && _isEditable(_userData!));

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      if (widget.embeddedInMyDinq) {
        return const Center(child: CircularProgressIndicator());
      }
      return Scaffold(
        appBar: _hasTopBar
            ? _buildAppBar(context: context, isEditable: false)
            : null,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // watch 使本页在 store（选中状态等）更新时重建，否则点击卡片后外部 CardToolbar/FloatingToolbar 不刷新
    if (_cardStore != null) {
      context.watch<CardStore>();
    }

    final isEditable = _userData != null ? _isEditable(_userData!) : false;
    return ChangeNotifierProvider<CardStore>.value(
      value: _cardStore!,
      child: _buildProfileStack(isEditable),
    );
  }

  Widget _buildProfileStack(bool isEditable) {
    return Portal(
      child: GestureDetector(
        onTap: () {
          if (_isEditMode &&
              isEditable &&
              _cardStore!.selectedCardIds.isNotEmpty) {
            _cardStore!.clearSelection();
          }
        },
        behavior: HitTestBehavior.deferToChild,
        child: Stack(
          children: [
            if (widget.embeddedInMyDinq)
              ColoredBox(
                color: DinqTokens.bgPage,
                child: _buildProfileBody(isEditable),
              )
            else
              Scaffold(
                backgroundColor: widget.showMyDinqTopBar
                    ? DinqTokens.bgPage
                    : null,
                resizeToAvoidBottomInset: false,
                appBar: _buildAppBar(
                  context: context,
                  isEditable: isEditable,
                  userData: _userData,
                  isSaving: _cardStore?.isSaving ?? false,
                ),
                body: _buildProfileBody(isEditable),
              ),
            if (isEditable &&
                _userData != null &&
                !widget.embeddedInMyDinq &&
                !widget.showMyDinqTopBar &&
                !widget.showAppBar)
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    child: PreviewEditToggle(
                      key: const ValueKey('preview_edit_toggle'),
                      isPreviewMode: _isPreviewMode,
                      onPreviewModeChanged: _handlePreviewModeChanged,
                    ),
                  ),
                ),
              ),
            if (_userData != null)
              ChangeStatusModal(
                isOpen: _isStatusModalOpen,
                onClose: _closeStatusModal,
                currentStatus: _userData!.jobStatus ?? '',
              ),
            if (_isEditMode && isEditable) ...[
              if (_cardStore!.selectedCardIds.isNotEmpty) ...[
                Builder(
                  builder: (context) {
                    final selectedId = _cardStore!.selectedCardIds.first;
                    final idx = _cardStore!.cards.indexWhere(
                      (c) => c.id == selectedId,
                    );
                    if (idx < 0) return const SizedBox.shrink();
                    return CardToolbar(card: _cardStore!.cards[idx]);
                  },
                ),
              ] else
                FloatingToolbar(isMobile: true, isSaving: _cardStore!.isSaving),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProfileBody(bool isEditable) {
    final hasFloatingEditToolbar = _isEditMode && isEditable;
    final baseBottomPadding = widget.embeddedInMyDinq || widget.showMyDinqTopBar
        ? 32.0
        : ConstantsTool.bottomTabHeight + 32.0;
    final scrollBottomPadding =
        baseBottomPadding + (hasFloatingEditToolbar ? 112.0 : 0.0);

    return SafeArea(
      top: !_hasTopBar && !widget.embeddedInMyDinq,
      bottom: false,
      child: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onHorizontalDragEnd: widget.embeddedInMyDinq
                  ? null
                  : (details) {
                      final v = details.primaryVelocity ?? 0;
                      if (v < -100 && _isPreviewMode) {
                        _handlePreviewModeChanged(false);
                      } else if (v > 100 && !_isPreviewMode) {
                        _handlePreviewModeChanged(true);
                      }
                    },
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  top: widget.embeddedInMyDinq
                      ? 16
                      : (widget.showMyDinqTopBar ? 16 : (_hasTopBar ? 24 : 68)),
                  bottom: scrollBottomPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (_userData != null) ...[
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 24,
                          right: 24,
                          top: 24,
                          bottom: 0,
                        ),
                        child: ProfileHeader(
                          data: _userData!,
                          username: _userData?.name ?? '',
                          isPreviewMode: widget.embeddedInMyDinq
                              ? false
                              : _isPreviewMode,
                          onPreviewModeChanged: _handlePreviewModeChanged,
                          onAvatarUpdated: _refreshProfileData,
                          onStatusEdit: () =>
                              _showStatusModal(context, _userData!),
                          onDataUpdated: _refreshProfileData,
                          onShare: () {
                            if (_userData == null) return;
                            ShareProfileDialog.show(
                              context: context,
                              username: widget.username,
                              userData: _userData!,
                              cards: _cardStore?.cards,
                            );
                          },
                          showToggle: false,
                          showShare:
                              !widget.showMyDinqTopBar &&
                              !widget.embeddedInMyDinq,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 0,
                          bottom: 0,
                        ),
                        child: CardGridStaggered(
                          editable: _isEditMode && isEditable,
                          onPlaceholderClick: _handlePlaceholderClick,
                          cardStore: _cardStore,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _ProfileFooter(
                        showOwnerStats: isEditable,
                        username: widget.username,
                        totalViews: _totalViews,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showStatusModal(BuildContext context, UserData data) {
    setState(() => _isStatusModalOpen = true);
  }

  void _closeStatusModal() {
    setState(() => _isStatusModalOpen = false);
    // 刷新用户数据
    _loadData();
  }

  bool _isEditable(UserData data) {
    final userStore = context.read<UserStore>();
    return userStore.isLoggedIn() &&
        userStore.user?.userData.domain == data.domain;
  }

  /// 站内私信：对已注册且有主页的用户发起私聊（对齐 web ProfileSection.handleStartChat）。
  /// 未登录跳登录；成功后进入会话详情页。
  Future<void> _startChat(UserData owner) async {
    if (owner.userId.isEmpty || _isStartingChat) return;
    final userStore = context.read<UserStore>();
    if (!userStore.isLoggedIn()) {
      context.push('/signin');
      return;
    }
    setState(() => _isStartingChat = true);
    try {
      final resp = await _messageService.createPrivateConversation(
        owner.userId,
      );
      final convRaw = resp['conversation'];
      final convMap = convRaw is Map
          ? Map<String, dynamic>.from(convRaw)
          : null;
      final convId =
          (convMap?['id'] ?? convMap?['conversation_id'] ?? resp['id'])
              ?.toString() ??
          '';
      if (!mounted) return;
      if (convId.isNotEmpty) {
        final messagesStore = context.read<MessagesStore>();
        if (convMap != null && convMap.isNotEmpty) {
          try {
            messagesStore.setCurrentConversation(
              Conversation.fromJson(convMap),
            );
          } catch (_) {}
        }
        unawaited(messagesStore.connectWebSocket());
        context.push('/admin/inbox/$convId');
      } else {
        _snack('Failed to open conversation');
      }
    } catch (e) {
      if (mounted) _snack(apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isStartingChat = false);
    }
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  void _handlePlaceholderClick(PlaceholderCardConfig config) {
    final cardStore = context.read<CardStore>();
    final definition = CardRegistry().getDefinition(config.type);
    final type = config.type.toUpperCase();
    if (type == 'ACHIEVEMENT_NETWORK' && definition != null) {
      AddCardDialog.show(context: context, definition: definition);
      return;
    }
    if (type == 'CAREER_TRAJECTORY' && definition != null) {
      AddCardDialog.show(context: context, definition: definition);
      return;
    }
    if (type == 'IMAGE') {
      addImageCard(context);
      return;
    }
    if (definition != null &&
        (isSocialCard(config.type) || type == 'LINK' || type == 'IFRAME')) {
      AddCardDialog.show(context: context, definition: definition);
      return;
    }
    cardStore.addCard(type: config.type);
  }
}

class _ProfileFooter extends StatelessWidget {
  const _ProfileFooter({
    required this.showOwnerStats,
    required this.username,
    required this.totalViews,
  });

  final bool showOwnerStats;
  final String username;
  final int totalViews;

  static const _textColor = Color(0xFF9CA3AF);
  static const _dividerColor = Color(0xFFE5E7EB);

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _formatViews(int value) {
    final text = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final remaining = text.length - i;
      buffer.write(text[i]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write(',');
      }
    }
    return buffer.toString();
  }

  void _showViewsStats(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      // 安全区由 sheet 内部白底自行铺满，避免透明区透出黑边。
      useSafeArea: false,
      builder: (_) => _ViewsStatsBottomSheet(
        username: username,
        initialTotalViews: totalViews,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Built by ',
            style: TextStyle(fontSize: 14, color: _textColor),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _open('https://dinq.me'),
            child: const Text(
              'DINQ.me',
              style: TextStyle(fontSize: 14, color: _textColor),
            ),
          ),
          if (showOwnerStats) ...[
            const _FooterDivider(),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _showViewsStats(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Views ${_formatViews(totalViews)}',
                  style: const TextStyle(fontSize: 14, color: _textColor),
                ),
              ),
            ),
            const _FooterDivider(),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _open('https://discord.com/invite/dgkW7ej2bj'),
              child: SvgPicture.asset(
                'assets/icons/social-icons-line/discord.svg',
                width: 16,
                height: 16,
                colorFilter: const ColorFilter.mode(
                  _textColor,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FooterDivider extends StatelessWidget {
  const _FooterDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 12,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: _ProfileFooter._dividerColor,
    );
  }
}

// Page visitor details.
class _ViewsStatsBottomSheet extends StatefulWidget {
  const _ViewsStatsBottomSheet({
    required this.username,
    required this.initialTotalViews,
  });

  final String username;
  final int initialTotalViews;

  @override
  State<_ViewsStatsBottomSheet> createState() => _ViewsStatsBottomSheetState();
}

class _ViewsStatsBottomSheetState extends State<_ViewsStatsBottomSheet> {
  final ProfileService _profileService = ProfileService();
  bool _loading = true;
  List<_ViewerEntry> _viewers = const [];
  int _total = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadViewers();
  }

  Future<void> _loadViewers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _profileService.getViewers(
        username: widget.username,
        page: 1,
        pageSize: 50,
      );
      final rawViewers = data['viewers'];
      if (!mounted) return;
      setState(() {
        _total = _intFrom(data['total']);
        _viewers = rawViewers is List
            ? rawViewers.whereType<Map>().map((entry) {
                return _ViewerEntry.fromJson(Map<String, dynamic>.from(entry));
              }).toList()
            : const [];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = apiErrorMessage(e);
        _loading = false;
      });
    }
  }

  String _plural(int value, String singular) {
    return '$value $singular${value == 1 ? '' : 's'}';
  }

  int _intFrom(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.replaceAll(',', '')) ?? 0;
    return 0;
  }

  int _locationCount() {
    final groups = <String>{};
    for (final viewer in _viewers) {
      if (viewer.latitude == null || viewer.longitude == null) continue;
      if (viewer.city.isEmpty) continue;
      groups.add('${viewer.city}-${viewer.country}');
    }
    return groups.length;
  }

  Widget _buildVisitorsContent() {
    final visits = _total > 0 ? _total : widget.initialTotalViews;
    final locationCount = _locationCount();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 14),
          child: Row(
            children: [
              const Text(
                'Visitors',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF171717),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${_plural(visits, 'visit')} · ${_plural(locationCount, 'location')}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF9CA3AF),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE5E7EB)),
        Expanded(
          child: _viewers.isEmpty
              ? const Center(
                  child: Text(
                    'No visitors yet',
                    style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 24, 20, 32),
                  itemBuilder: (context, index) {
                    return _ViewerRow(viewer: _viewers[index]);
                  },
                  separatorBuilder: (_, index) => const SizedBox(height: 22),
                  itemCount: _viewers.length,
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bottomInset = media.viewInsets.bottom;
    final bottomSafe = media.padding.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          // 含底部安全区，避免内容被系统导航条挡住。
          maxHeight: 560 + bottomSafe,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        // 白底延伸进系统导航区；内容再垫 SafeArea，避免黑边。
        padding: EdgeInsets.only(bottom: bottomSafe),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? _ViewsError(message: _error!, onRetry: _loadViewers)
                  : _buildVisitorsContent(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewerEntry {
  const _ViewerEntry({
    required this.viewerType,
    required this.viewerName,
    required this.viewerCompany,
    required this.viewerAvatar,
    required this.viewerUsername,
    required this.country,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.lastViewedAt,
    required this.viewCount,
  });

  factory _ViewerEntry.fromJson(Map<String, dynamic> json) {
    double? doubleValue(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    int intValue(dynamic value) {
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    String textValue(String key) => json[key]?.toString().trim() ?? '';

    return _ViewerEntry(
      viewerType: textValue('viewer_type'),
      viewerName: textValue('viewer_name'),
      viewerCompany: textValue('viewer_company'),
      viewerAvatar: textValue('viewer_avatar'),
      viewerUsername: textValue('viewer_username'),
      country: textValue('country'),
      city: textValue('city'),
      latitude: doubleValue(json['latitude']),
      longitude: doubleValue(json['longitude']),
      lastViewedAt: textValue('last_viewed_at'),
      viewCount: intValue(json['view_count']),
    );
  }

  final String viewerType;
  final String viewerName;
  final String viewerCompany;
  final String viewerAvatar;
  final String viewerUsername;
  final String country;
  final String city;
  final double? latitude;
  final double? longitude;
  final String lastViewedAt;
  final int viewCount;

  bool get isAnonymous => viewerType == 'anonymous';

  String get displayName {
    if (isAnonymous) return 'Guest';
    return viewerName.isEmpty ? 'User' : viewerName;
  }

  String get location =>
      [city, country].where((part) => part.isNotEmpty).join(', ');

  String get subtitle {
    if (isAnonymous) return location;
    return [
      viewerCompany,
      location,
    ].where((part) => part.isNotEmpty).join(' · ');
  }
}

class _ViewerRow extends StatelessWidget {
  const _ViewerRow({required this.viewer});

  final _ViewerEntry viewer;

  String _formatTimeAgo(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return '';
    final diff = DateTime.now().difference(parsed.toLocal());
    if (diff.inDays >= 365) return '${diff.inDays ~/ 365}y';
    if (diff.inDays >= 30) return '${diff.inDays ~/ 30}mo';
    if (diff.inDays >= 1) return '${diff.inDays}d';
    if (diff.inHours >= 1) return '${diff.inHours}h';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m';
    return 'now';
  }

  Widget _avatar() {
    final image = viewer.isAnonymous ? '' : viewer.viewerAvatar;
    if (image.isEmpty) {
      return SvgPicture.asset(
        'assets/images/default-avatar.svg',
        width: 40,
        height: 40,
      );
    }
    return ClipOval(
      child: Image.network(
        image,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (_, error, stackTrace) {
          return SvgPicture.asset(
            'assets/images/default-avatar.svg',
            width: 40,
            height: 40,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timeAgo = _formatTimeAgo(viewer.lastViewedAt);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _avatar(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      viewer.displayName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF171717),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (viewer.viewCount > 1) ...[
                    const SizedBox(width: 6),
                    Text(
                      '×${viewer.viewCount}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ],
              ),
              if (viewer.subtitle.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  viewer.subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        if (timeAgo.isNotEmpty) ...[
          const SizedBox(width: 12),
          Text(
            timeAgo,
            style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
          ),
        ],
      ],
    );
  }
}

class _ViewsError extends StatelessWidget {
  const _ViewsError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _SetNameDialog extends StatefulWidget {
  final TextEditingController nameController;
  final Future<void> Function() onSave;

  const _SetNameDialog({required this.nameController, required this.onSave});

  @override
  State<_SetNameDialog> createState() => _SetNameDialogState();
}

class _SetNameDialogState extends State<_SetNameDialog> {
  bool _isUpdating = false;

  bool get _isValid => widget.nameController.text.trim().isNotEmpty;

  Future<void> _handleSubmit() async {
    if (!_isValid || _isUpdating) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      await widget.onSave();
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.all(24),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 输入框 - h-14 (56px), rounded-xl (12px)
            TextField(
              controller: widget.nameController,
              autofocus: true,
              enabled: !_isUpdating,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) {
                if (_isValid && !_isUpdating) {
                  _handleSubmit();
                }
              },
              decoration: InputDecoration(
                hintText: 'Enter Your name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF171717),
                    width: 1,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 0,
                ),
                hintStyle: const TextStyle(
                  fontSize: 18,
                  color: Color.fromRGBO(48, 48, 48, 0.32),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              style: const TextStyle(
                fontSize: 18,
                color: Color(0xFF171717),
                height: 1.0,
              ),
            ),
            const SizedBox(height: 16),
            // 按钮 - h-14 (56px), rounded-xl (12px), text-lg
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: (_isUpdating || !_isValid) ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: (_isUpdating || !_isValid)
                      ? const Color(0xFFE5E5E5)
                      : const Color(0xFF171717),
                  foregroundColor: (_isUpdating || !_isValid)
                      ? const Color.fromRGBO(48, 48, 48, 0.4)
                      : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isUpdating
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Saving...',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      )
                    : const Text(
                        "Let's Start DINQ",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
