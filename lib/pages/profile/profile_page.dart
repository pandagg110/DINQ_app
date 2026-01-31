import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_portal/flutter_portal.dart';
import '../../models/user_models.dart';
import '../../services/profile_service.dart';
import '../../stores/card_store.dart';
import '../../stores/user_store.dart';
import '../../widgets/cards/card_grid_staggered.dart';
import '../../widgets/layout/nav_bar.dart';
import '../../widgets/profile/profile_avatar.dart';
import '../../widgets/profile/change_status_modal.dart';
import '../../widgets/profile/floating_toolbar.dart';
import '../../widgets/profile/card_toolbar.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.username});

  final String username;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with WidgetsBindingObserver {
  final ProfileService _profileService = ProfileService();
  bool _isLoading = true;
  UserData? _userData;
  bool _isStatusModalOpen = false;
  CardStore? _cardStore;
  /// true = Preview 模式，false = Edit 模式
  bool _isPreviewMode = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cardStore = context.read<CardStore>();
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
    final cardStore = context.read<CardStore>();
    try {
      final userData = await _profileService.getUserData(widget.username);
      if (!mounted) return;
      setState(() {
        _userData = userData;
        _isLoading = false;
      });
      context.read<UserStore>().setCardOwner(userData);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
    await cardStore.loadCards(widget.username);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isEditable = _userData != null ? _isEditable(_userData!) : false;
    final cardStore = context.watch<CardStore>();

    return Portal(
      child: GestureDetector(
        onTap: () {
          // 点击页面外部区域时，清除选中状态
          if (!_isPreviewMode && isEditable && cardStore.selectedCardIds.isNotEmpty) {
            cardStore.clearSelection();
          }
        },
        behavior: HitTestBehavior.deferToChild,
        child: Stack(
          children: [
            Scaffold(
              body: Column(
                children: [
                  // const AppHeader(showAuthButtons: true),
                  NavBar(
                    onBack: () {
                      debugPrint('onBack');
                    },
                    title: const Text(
                      'Profile',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF171717),
                      ),
                    ),
                  ),
                  if (_userData != null) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                      child: _buildPreviewEditToggle(),
                    ),
                  ],
                  Expanded(
                    child: GestureDetector(
                      onHorizontalDragEnd: (details) {
                        final v = details.primaryVelocity ?? 0;
                        if (v < -100 && _isPreviewMode) {
                          setState(() => _isPreviewMode = false);
                        } else if (v > 100 && !_isPreviewMode) {
                          setState(() => _isPreviewMode = true);
                        }
                      },
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (_userData != null) ...[
                              _buildProfileHeader(context, _userData!),
                              const SizedBox(height: 24),
                              CardGridStaggered(editable: !_isPreviewMode && isEditable),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Status Modal
            if (_userData != null)
              ChangeStatusModal(
                isOpen: _isStatusModalOpen,
                onClose: _closeStatusModal,
                currentStatus: _userData!.jobStatus ?? '',
              ),
            // 编辑模式下：有卡片选中时显示 CardToolbar，否则显示 FloatingToolbar
            if (!_isPreviewMode && isEditable) ...[
              if (cardStore.selectedCardIds.isNotEmpty) ...[
                Builder(
                  builder: (context) {
                    final selectedId = cardStore.selectedCardIds.first;
                    final idx = cardStore.cards.indexWhere((c) => c.id == selectedId);
                    if (idx < 0) return const SizedBox.shrink();
                    return CardToolbar(card: cardStore.cards[idx]);
                  },
                ),
              ] else
                FloatingToolbar(
                  isMobile: true,
                  isSaving: cardStore.isSaving,
                ),
            ],
          ],
        ),
      ),
    );
  }

  /// Preview / Edit 滑动切换按钮（支持点击与左右滑动屏幕切换）
  Widget _buildPreviewEditToggle() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        const inset = 4.0;
        final segmentWidth = (w - inset * 2) / 2;
        final sliderWidth = segmentWidth - inset;
        return Container(
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Stack(
            children: [
              // 选中背景（白色滑块）
              AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                left: _isPreviewMode ? inset : segmentWidth + inset,
                top: inset,
                bottom: inset,
                width: sliderWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
              // 两个选项
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isPreviewMode = true),
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: Text(
                          'Preview',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: _isPreviewMode
                                ? const Color(0xFF171717)
                                : const Color(0xFF9CA3AF),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isPreviewMode = false),
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: Text(
                          'Edit',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: !_isPreviewMode
                                ? const Color(0xFF171717)
                                : const Color(0xFF9CA3AF),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(BuildContext context, UserData data) {
    final userStore = context.watch<UserStore>();
    final isEditable =
        userStore.isLoggedIn() &&
        userStore.user?.userData.domain == data.domain;

    // 解析标签（逗号分隔，取第一个）
    final tags = data.tags.isNotEmpty
        ? data.tags
              .split(',')
              .map((t) => t.trim())
              .where((t) => t.isNotEmpty)
              .toList()
        : <String>[];

    // 预定义的标签颜色
    const tagColors = [
      Color(0xFFFDE277), // 黄色
      Color(0xFFFED7D7), // 粉色
      Color(0xFFD6F995), // 绿色
      Color(0xFFC6E2FF), // 蓝色
      Color(0xFFE2C6FF), // 紫色
      Color(0xFFFFE4CC), // 橙色
      Color(0xFFD4F4DD), // 浅绿色
      Color(0xFFFFD6E8), // 浅粉色
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 头像
        ProfileAvatar(
          avatarUrl: data.avatarUrl,
          userName: data.name.isNotEmpty ? data.name : widget.username,
          editable: isEditable && !_isPreviewMode,
          size: 180,
          jobStatus: data.jobStatus,
          onAvatarUpdated: () {
            _loadData();
          },
          onStatusEdit: isEditable
              ? () {
                  _showStatusModal(context, data);
                }
              : null,
        ),
        const SizedBox(height: 16),
        // 用户名
        Text(
          data.name.isNotEmpty ? data.name : widget.username,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Color(0xFF171717),
          ),
        ),
        const SizedBox(height: 8),
        // 职位信息（图标 + 文本）
        if (data.fullPosition.isNotEmpty)
          Row(
            children: [
              const Icon(
                Icons.work_outline,
                size: 16,
                color: Color(0xFF6B7280),
              ),
              const SizedBox(width: 6),
              Text(
                data.fullPosition,
                style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        // 标签
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags.take(5).map((tag) {
              final colorIndex = tags.indexOf(tag) % tagColors.length;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: tagColors[colorIndex],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF171717),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
        // 底部信息
        if (data.bio.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            data.bio,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
        ],
        const SizedBox(height: 8),
        // Text(
        //   'dinq.me/${data.domain.isNotEmpty ? data.domain : widget.username}',
        //   style: const TextStyle(
        //     fontSize: 14,
        //     color: Color(0xFF6B7280),
        //   ),
        // ),
      ],
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
}
