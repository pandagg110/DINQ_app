import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_portal/flutter_portal.dart';
import '../../models/user_models.dart';
import '../../services/profile_service.dart';
import '../../stores/card_store.dart';
import '../../stores/user_store.dart';
import '../../widgets/cards/card_grid_staggered.dart';
import '../../widgets/layout/nav_bar.dart';
import '../../widgets/profile/profile_header.dart';
import '../../widgets/profile/change_status_modal.dart';
import '../../widgets/profile/floating_toolbar.dart';
import '../../widgets/profile/card_toolbar.dart';
import '../../widgets/profile/profile_edit_dialog.dart';

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
                    actions: isEditable && _userData != null
                        ? [
                            IconButton(
                              icon: const Icon(
                                Icons.edit_outlined,
                                color: Color(0xFF111827),
                                size: 24,
                              ),
                              onPressed: () => _openProfileEditDialog(context),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ]
                        : null,
                  ),
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
                        padding: const EdgeInsets.all(0),
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
                                  username: widget.username,
                                  isPreviewMode: _isPreviewMode,
                                  onPreviewModeChanged: (isPreview) =>
                                      setState(() => _isPreviewMode = isPreview),
                                  onAvatarUpdated: _loadData,
                                  onStatusEdit: () => _showStatusModal(context, _userData!),
                                  onDataUpdated: _loadData,
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
                FloatingToolbar(isMobile: true, isSaving: cardStore.isSaving),
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

  Future<void> _openProfileEditDialog(BuildContext context) async {
    if (_userData == null) return;
    await ProfileEditDialog.show(
      context: context,
      initialData: _userData!,
      onSaved: _loadData,
    );
  }

  bool _isEditable(UserData data) {
    final userStore = context.read<UserStore>();
    return userStore.isLoggedIn() &&
        userStore.user?.userData.domain == data.domain;
  }
}
