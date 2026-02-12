import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_portal/flutter_portal.dart';
import '../../constants/app_constants.dart';
import '../../models/user_models.dart';
import '../../services/profile_service.dart';
import '../../stores/card_store.dart';
import '../../stores/main_store.dart';
import '../../stores/user_store.dart';
import '../../utils/add_image_card.dart';
import '../../widgets/cards/card_grid_staggered.dart';
import '../../widgets/cards/factory/card_registry.dart';
import '../../widgets/cards/factory/definitions/index.dart' show isSocialCard;
import '../../widgets/cards/placeholder/placeholder_config.dart';
import '../../widgets/common/add_card_dialog.dart';
import '../../widgets/profile/profile_header.dart';
import '../../widgets/profile/change_status_modal.dart';
import '../../widgets/profile/floating_toolbar.dart';
import '../../widgets/profile/card_toolbar.dart';
import '../../widgets/profile/preview_edit_toggle.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.username,
    this.showAppBar = false,
  });

  final String username;
  /// 为 true 时显示顶部 AppBar（含返回按钮），便于从 Discover 等 push 进入后返回
  final bool showAppBar;

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

      // 参考 tsx 逻辑：只有当是当前用户自己的 profile 且 name 为空时，弹出设置 name 的 dialog
      final userStore = context.read<UserStore>();
      final isLoggedIn = userStore.isLoggedIn();
      final currentUserDomain = userStore.user?.userData.domain;
      final userDataDomain = userData.domain;
      final isEditable = isLoggedIn && currentUserDomain == userDataDomain;
      final myFlow = userStore.myFlow;
      final flowStatus = myFlow?.status;
      final nameIsEmpty = userData.name.isEmpty || userData.name.trim().isEmpty;

      if (mounted && isEditable && flowStatus == 'success' && nameIsEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showSetNameDialog();
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
    await cardStore.loadCards(widget.username);
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

              if (mounted) {
                Navigator.of(dialogContext).pop(true);
                // 刷新数据
                await _loadData();
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: widget.showAppBar
            ? AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                title: const Text('Profile'),
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF171717),
                elevation: 0,
              )
            : null,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    

    final isEditable = _userData != null ? _isEditable(_userData!) : false;
    final cardStore = context.watch<CardStore>();
    final mainStore = context.watch<MainStore>();
    return Portal(
      child: GestureDetector(
        onTap: () {
          // 点击页面外部区域时，清除选中状态
          if (!_isPreviewMode &&
              isEditable &&
              cardStore.selectedCardIds.isNotEmpty) {
            cardStore.clearSelection();
          }
        },
        behavior: HitTestBehavior.deferToChild,
        child: Stack(
          children: [
            Scaffold(
              appBar: widget.showAppBar
                  ? AppBar(
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      title: Text(
                        (_userData?.name ?? '').isNotEmpty
                            ? _userData!.name
                            : widget.username,
                      ),
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF171717),
                      elevation: 0,
                      scrolledUnderElevation: 0,
                    )
                  : null,
              body: SafeArea(
                bottom: false, // 底部由 MainTabBottomView 处理
                child: Column(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onHorizontalDragEnd: (details) {
                          final v = details.primaryVelocity ?? 0;
                          if (v < -100 && _isPreviewMode) {
                            setState(() => _isPreviewMode = false);
                            mainStore.hideBottomNavigation();
                          } else if (v > 100 && !_isPreviewMode) {
                            setState(() => _isPreviewMode = true);
                            mainStore.showBottomNavigation();
                          }
                        },
                        child: SingleChildScrollView(
                          padding: EdgeInsets.only(
                            // showAppBar 时无顶部悬浮切换按钮，用 24；否则为切换按钮留出空间（44 + 24）= 68
                            top: widget.showAppBar ? 24 : 68,
                            bottom: ConstantsTool.bottomTabHeight + 32,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (_userData != null) ...[
                                Padding(
                                  padding: EdgeInsets.only(
                                    left: 24,
                                    right: 24,
                                    top: 24,
                                    bottom: 0,
                                  ),
                                  child: ProfileHeader(
                                    data: _userData!,
                                    username: _userData?.name ?? '',
                                    isPreviewMode: _isPreviewMode,
                                    onPreviewModeChanged: (isPreview) =>
                                        setState(
                                          () => _isPreviewMode = isPreview,
                                        ),
                                    onAvatarUpdated: _loadData,
                                    onStatusEdit: () =>
                                        _showStatusModal(context, _userData!),
                                    onDataUpdated: _loadData,
                                    onShare: () {
                                      // TODO: 打开分享
                                    },
                                    showToggle: false, // 不在 ProfileHeader 中显示，使用 Positioned 固定在顶部
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Padding(
                                  padding: EdgeInsets.only(
                                    left: 12,
                                    right: 12,
                                    top: 0,
                                    bottom: 0,
                                  ),
                                  child: CardGridStaggered(
                                    editable: !_isPreviewMode && isEditable,
                                    onPlaceholderClick: _handlePlaceholderClick,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Preview/Edit 切换按钮 - 固定在顶部
            if (isEditable && _userData != null)
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: PreviewEditToggle(
                      key: const ValueKey('preview_edit_toggle'),
                      isPreviewMode: _isPreviewMode,
                      onPreviewModeChanged: (isPreview) {
                        setState(() => _isPreviewMode = isPreview);
                        // 切换到 Edit 模式时隐藏底部导航栏
                        if (!isPreview) {
                          context.read<MainStore>().hideBottomNavigation();
                        } else {
                          context.read<MainStore>().showBottomNavigation();
                        }
                      },
                    ),
                  ),
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
                    final idx = cardStore.cards.indexWhere(
                      (c) => c.id == selectedId,
                    );
                    if (idx < 0) return const SizedBox.shrink();
                    return CardToolbar(card: cardStore.cards[idx]);
                  },
                ),
              ] else
                FloatingToolbar(
                  isMobile: true,
                  isSaving: cardStore.isSaving,
                  username: widget.username,
                  userData: _userData,
                  cards: cardStore.cards,
                ),
            ],
          ],
        ),
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

// 设置姓名的 Dialog 组件
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
