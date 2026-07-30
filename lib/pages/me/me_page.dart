import 'package:dinq_app/widgets/common/dash_line.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../constants/app_constants.dart';
import '../../services/upload_service.dart';
import '../../stores/user_store.dart';
import '../../utils/color_util.dart';
import '../../utils/image_utils.dart';
import '../../utils/top_toast_util.dart';
import '../../theme/dinq_tokens.dart';
import '../../theme/me_icons.dart';
import '../../widgets/common/base_page.dart';
import '../../widgets/common/dinq_svg_icon.dart';
import '../marketing/pricing_page.dart' show kPlanLabel;

class MePage extends StatefulWidget {
  const MePage({super.key});

  @override
  State<MePage> createState() => _MePageState();
}

class _MePageState extends State<MePage> {
  final UploadService _uploadService = UploadService();
  bool _isUploading = false;

  Future<void> _handleAvatarUpload() async {
    if (_isUploading) return;

    try {
      final result = await ImageUtils.pickSinglePicture(context);

      if (result != null) {
        final file = await result.readAsBytes();
        setState(() => _isUploading = true);

        try {
          final uploadedUrl = await _uploadService.uploadFile(
            bytes: file,
            filename: "image.jpg",
          );
          if (!mounted) {
            return;
          }
          final userStore = context.read<UserStore>();
          await userStore.updateUserData({'avatar_url': uploadedUrl});
          if (!mounted) {
            return;
          }
          setState(() => _isUploading = false);
          TopToastUtil.showSuccess(
            context: context,
            title: '上传成功',
            description: '头像已更新',
          );
        } catch (error) {
          if (!mounted) {
            return;
          }
          setState(() => _isUploading = false);
          TopToastUtil.showError(
            context: context,
            title: '上传失败',
            description: error.toString(),
          );
        }
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      TopToastUtil.showError(
        context: context,
        title: '选择文件失败',
        description: error.toString(),
      );
    }
  }

  String _getContentType(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  @override
  Widget build(BuildContext context) {
    final userStore = context.watch<UserStore>();
    final user = userStore.user;
    final subscription = userStore.subscription;
    final credits = subscription?.creditsBalance ?? 0;
    // 用 basePlan（去掉 _monthly/_yearly 周期后缀），显示逻辑对齐 web PLAN_LABEL
    final basePlan = subscription?.basePlan ?? 'free';

    return Scaffold(
      backgroundColor: ColorUtil.pageBgColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 主内容区
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  bottom: ConstantsTool.bottomTabHeight + 32,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    // 头像区域
                    _buildAvatarSection(user?.userData.avatarUrl ?? ''),
                    const SizedBox(height: 16),
                    // 用户名 + 编辑
                    if ((user?.userData.name ?? '').trim().isNotEmpty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              user!.userData.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Geist',
                                color: ColorUtil.textColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => context.push('/settings/profile'),
                            child: Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: ColorUtil.sub1TextColor,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 4),
                    // 域名
                    Text(
                      'dinq.me/${user?.userData.domain ?? ''}',
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Geist',
                        color: ColorUtil.sub1TextColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // 套餐卡（Free/Upgrade + Available Credits + Invite friends）
                    _buildSubscriptionCard(basePlan, credits),
                    const SizedBox(height: 16),
                    // 菜单分组卡（对齐 web my/page.tsx menuItems）
                    _menuCard([
                      _menuItem(
                        MeIcons.myDinq,
                        'My DINQ',
                        () => context.push('/admin/mydinq'),
                      ),
                      _menuItem(
                        MeIcons.organization,
                        'Organization',
                        () => context.push('/me/organization'),
                      ),
                      _menuItem(
                        MeIcons.apiPlayground,
                        'API Playground',
                        () => context.push('/me/api-keys'),
                      ),
                      _menuItem(
                        MeIcons.resume,
                        'Resume',
                        () => context.push('/admin/mydinq/resume'),
                      ),
                      _menuItem(
                        MeIcons.integration,
                        'Integration',
                        () => context.push('/me/integration'),
                      ),
                      _menuItem(
                        MeIcons.settings,
                        'Settings',
                        () => context.push('/settings'),
                        showDivider: false,
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection(String avatarUrl) {
    return Stack(
      children: [
        // 头像
        GestureDetector(
          onTap: _handleAvatarUpload,
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE0F0FF),
            ),
            child: ClipOval(
              child: _isUploading
                  ? const Center(child: CircularProgressIndicator())
                  : avatarUrl.isNotEmpty
                  ? NetworkImageView(
                      imageUrl: avatarUrl,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      placeholder: const Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.grey,
                      ),
                    )
                  : const Icon(Icons.person, size: 60, color: Colors.grey),
            ),
          ),
        ),
        // 编辑按钮
        Positioned(
          right: 2,
          bottom: 0,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: ColorUtil.textColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 1.5,
                strokeAlign: BorderSide.strokeAlignOutside,
              ),
            ),
            child: AssetImageView("edit", width: 20, height: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionCard(String basePlan, int credits) {
    // 按实际订阅档位显示（web PLAN_LABEL：free/basic/pro，plus 显示为 Pro），
    // 修复所有付费档位都显示成 "Pro" 的问题
    final isFree = basePlan == 'free';
    final displayPlan = kPlanLabel[basePlan] ?? basePlan;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      // 注意：不要给卡片加 BoxShadow。阴影会投到下方菜单卡上，中段被白色
      // 卡身遮住、只在菜单卡顶部两个圆角缺口处露出，形成「两个黑色的角」
      // （滚动时随位置闪现）。web SubscriptionCard 也是纯 border 无阴影。
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFEEEEEE), width: 1),
      ),
      child: Column(
        children: [
          // 订阅状态行
          SizedBox(
            height: 54,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  displayPlan,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Editor Note',
                    color: ColorUtil.textColor,
                  ),
                ),
                if (isFree)
                  NormalButton(
                    onTap: () => context.push('/pricing'),
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      decoration: BoxDecoration(
                        color: ColorUtil.textColor,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Center(
                        child: const Text(
                          'Upgrade',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Geist',
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          DashedLine(color: Color(0xFFECECEC)),
          // 积分行：进入 Credits 页（对齐 web，不再直接进 Subscriptions）
          NormalButton(
            onTap: () => context.push('/settings/credits'),
            child: SizedBox(
              height: 54,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Available Credits',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Geist',
                      color: Color(0xFF636363),
                    ),
                  ),
                  Row(
                    children: [
                      AssetImageView("remaining_score", width: 20, height: 20),
                      const SizedBox(width: 4),
                      Text(
                        '$credits',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Geist',
                          color: ColorUtil.textColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      AssetImageView("gray_right", width: 20, height: 20),
                    ],
                  ),
                ],
              ),
            ),
          ),
          DashedLine(color: Color(0xFFECECEC)),
          // 邀请赚积分（对齐 web：16px 图标 + gap-2，无额外占位）
          NormalButton(
            onTap: () => context.push('/me/invite'),
            child: SizedBox(
              height: 54,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const DinqSvgIcon(
                    assetName: MeIcons.gift,
                    size: 16,
                    color: Color(0xFF6B6862),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Invite friends, earn credits',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        height: 20 / 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Geist',
                        color: Color(0xFF6B6862),
                      ),
                    ),
                  ),
                  const DinqSvgIcon(
                    assetName: MeIcons.chevronRight,
                    size: 16,
                    color: Color(0xFF8A8880),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 菜单分组卡（对齐 web my/page.tsx：圆角 18 + 描边 + 图标底）
  Widget _menuCard(List<Widget> children) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEEDE9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08101828),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _menuItem(
    String iconAsset,
    String label,
    VoidCallback onTap, {
    bool showDivider = true,
  }) {
    const iconInk = Color(0xFF2A2826);
    const chevron = Color(0xFF9E9B93);

    return NormalButton(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: showDivider
              ? const Border(bottom: BorderSide(color: Color(0xFFF1EFEA)))
              : null,
        ),
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: DinqTokens.bgSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: DinqSvgIcon(
                assetName: iconAsset,
                size: 18,
                color: iconInk,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  height: 20 / 15,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Geist',
                  color: Color(0xFF171717),
                ),
              ),
            ),
            const DinqSvgIcon(
              assetName: MeIcons.chevronRight,
              size: 18,
              color: chevron,
            ),
          ],
        ),
      ),
    );
  }
}
