import 'package:flutter/material.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../pages/add/add_page.dart';
import '../../stores/card_store.dart';
import '../../stores/user_store.dart';
import '../../utils/add_image_card.dart';
import '../../utils/asset_path.dart';
import '../../utils/top_toast_util.dart';
import '../cards/factory/card_definition.dart';
import '../cards/factory/card_registry.dart';
import '../cards/factory/definitions/index.dart' show isSocialCard;
import '../common/add_card_dialog.dart';
import '../common/confirm_dialog.dart';

class FloatingToolbar extends StatefulWidget {
  const FloatingToolbar({
    super.key,
    this.isMobile = false,
    this.isSaving = false,
  });

  final bool isMobile;
  final bool isSaving;

  @override
  State<FloatingToolbar> createState() => _FloatingToolbarState();
}

class _FloatingToolbarState extends State<FloatingToolbar> {
  bool _moreMenuOpen = false;
  bool _showBackdrop = false;

  void _closeMenu() {
    setState(() {
      _moreMenuOpen = false;
    });
    // 延迟隐藏 backdrop，等待动画完成
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _showBackdrop = false;
        });
      }
    });
  }

  void _openMenu() {
    setState(() {
      _moreMenuOpen = true;
      _showBackdrop = true;
    });
  }

  void _showUpdateDialog() {
    ConfirmDialog.show(
      context: context,
      title: 'Update All Cards?',
      content:
          'This will update all card information. This may take a few moments. Do you want to continue?',
      okText: 'Yes, Update All',
      okStyle: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFFA325),
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ).then((confirmed) async {
      if (confirmed != true) return;
      try {
        await context.read<CardStore>().regenerateCard();
      } catch (e) {
        if (mounted) {
          TopToastUtil.showError(
            context: context,
            title: 'Update failed',
            description: 'Please try again.',
          );
        }
      }
    });
  }

  void _showRegenerateDialog() {
    ConfirmDialog.show(
      context: context,
      title: 'Regenerate My DINQ?',
      content:
          'All current DINQ data will be lost. This action cannot be undone. Are you sure you want to continue?',
      okText: 'Yes, Regenerate',
      okStyle: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE12C2C),
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ).then((confirmed) async {
      if (confirmed != true) return;
      try {
        await context.read<UserStore>().resetFlow();
        if (mounted) {
          TopToastUtil.showSuccess(
            context: context,
            title: 'Regenerate successful',
            description: 'Redirecting...',
          );
          context.go('/generation');
        }
      } catch (e) {
        if (mounted) {
          TopToastUtil.showError(
            context: context,
            title: 'Failed to regenerate',
            description: 'Please try again.',
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 👇 点外关闭层
        if (_showBackdrop)
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeMenu,
              behavior: HitTestBehavior.translucent,
              child: Container(color: Colors.transparent),
            ),
          ),
        // Toolbar
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Center(child: _buildToolbar()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    return PortalTarget(
      visible: true,
      portalFollower: _buildMoreMenu(),
      anchor: const Aligned(
        follower: Alignment.bottomCenter,
        target: Alignment.topCenter,
        offset: Offset(0, -8),
      ),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF171717),
          borderRadius: BorderRadius.circular(16),
          border: Border(
            bottom: BorderSide(width: 1, color: Colors.white.withOpacity(0.15)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildImageIconButton(
                iconPath: 'icons/mydinq/add.png',
                onTap: () async {
                  // AddPage 对 IMAGE 会先选图上传再创建并 pop(true)，其他类型 pop(definition)
                  final result = await Navigator.of(context).push<Object?>(
                    MaterialPageRoute<Object?>(builder: (_) => const AddPage()),
                  );
                  if (result == null || !context.mounted) return;
                  if (result is! CardDefinition)
                    return; // true 表示 IMAGE 已在 AddPage 内处理
                  final cardStore = context.read<CardStore>();
                  final type = result.type.toUpperCase();
                  // 与 TSX handleCardSelect 一致：ACHIEVEMENT_NETWORK / Social/LINK/IFRAME 先弹输入框，其余直接 addCard
                  if (type == 'ACHIEVEMENT_NETWORK') {
                    AddCardDialog.show(context: context, definition: result);
                  } else if (isSocialCard(result.type) ||
                      type == 'LINK' ||
                      type == 'IFRAME') {
                    AddCardDialog.show(context: context, definition: result);
                  } else {
                    await cardStore.addCard(type: result.type);
                  }
                },
              ),

              const SizedBox(width: 12),

              _buildImageIconButton(
                iconPath: 'icons/mydinq/link.png',
                onTap: () {
                  final definition = CardRegistry().getDefinition('LINK');
                  if (definition != null) {
                    AddCardDialog.show(
                      context: context,
                      definition: definition,
                    );
                  }
                },
              ),

              const SizedBox(width: 12),

              _buildImageIconButton(
                iconPath: 'icons/mydinq/img.png',
                onTap: () => addImageCard(context),
              ),

              const SizedBox(width: 16),

              _buildDivider(),

              const SizedBox(width: 16),

              // More Button (Rightmost section)
              _buildMoreButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageIconButton({
    required String iconPath,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 32,
      height: 32,
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.antiAlias,
        children: [
          // 图片作为背景
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              assetPath(iconPath),
              width: 32,
              height: 32,
              fit: BoxFit.contain,
            ),
          ),
          // 透明 InkWell 覆盖在上层，点击效果可见
          Material(
            color: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
              splashColor: Colors.white.withOpacity(0.25),
              highlightColor: Colors.white.withOpacity(0.15),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreButton() {
    return Container(
      width: 32,
      height: 32,
      constraints: const BoxConstraints(
        minWidth: 32,
        maxWidth: 32,
        minHeight: 32,
        maxHeight: 32,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: _moreMenuOpen
            ? Colors.white.withOpacity(0.15)
            : Colors.transparent,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (_moreMenuOpen) {
              _closeMenu();
            } else {
              _openMenu();
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: const Icon(Icons.more_horiz, size: 20, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildMoreMenu() {
    return IgnorePointer(
      ignoring: !_moreMenuOpen,
      // ignoring: false,
      child:
          Container(
                width: 268,
                height: 162,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    width: 1,
                    color: Colors.black.withOpacity(0.1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMoreMenuItem(
                        iconPath: 'icons/more-btns/regenerate.png',
                        label: 'Regenerate',
                        onTap: () {
                          _closeMenu();
                          _showRegenerateDialog();
                        },
                      ),
                      _buildMoreMenuItem(
                        iconPath: 'icons/more-btns/udpate.png',
                        label: 'Update',
                        onTap: () {
                          _closeMenu();
                          _showUpdateDialog();
                        },
                      ),
                      _buildMoreMenuItem(
                        iconPath: 'icons/more-btns/setting.png',
                        label: 'Settings',
                        onTap: () {
                          debugPrint('Settings clicked');
                          _closeMenu();
                          // TODO: Handle settings
                        },
                      ),
                    ],
                  ),
                ),
              )
              .animate(target: _moreMenuOpen ? 1 : 0)
              .fade(duration: 200.ms, curve: Curves.easeOut)
              .scale(
                begin: const Offset(0.95, 0.95),
                end: const Offset(1.0, 1.0),
                duration: 200.ms,
                curve: Curves.easeOut,
              )
              .slideY(
                begin: 0.1,
                end: 0.0,
                duration: 200.ms,
                curve: Curves.easeOut,
              ),
    );
  }

  Widget _buildMoreMenuItem({
    required String iconPath,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 252,
      height: 48,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                Image.asset(
                  assetPath(iconPath),
                  width: 40,
                  height: 40,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 1.0,
                    letterSpacing: 0,
                    color: Color(0xFF171717),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 16,
      // margin: const EdgeInsets.symmetric(horizontal: 8),
      color: Colors.white.withOpacity(0.15),
    );
  }
}
