import 'package:dinq_app/widgets/common/dash_line.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../constants/app_constants.dart';
import '../../services/upload_service.dart';
import '../../stores/user_store.dart';
import '../../utils/color_util.dart';
import '../../utils/top_toast_util.dart';
import '../../widgets/common/base_page.dart';

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
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp'],
      );

      if (result != null && result.files.single.bytes != null) {
        final file = result.files.single;
        setState(() => _isUploading = true);

        try {
          final uploadedUrl = await _uploadService.uploadFile(
            bytes: file.bytes!,
            filename: file.name,
            contentType: _getContentType(file.extension),
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
          TopToastUtil.showSuccess(context: context, title: '上传成功', description: '头像已更新');
        } catch (error) {
          if (!mounted) {
            return;
          }
          setState(() => _isUploading = false);
          TopToastUtil.showError(context: context, title: '上传失败', description: error.toString());
        }
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      TopToastUtil.showError(context: context, title: '选择文件失败', description: error.toString());
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
    final plan = subscription?.plan ?? 'free';

    return Scaffold(
      backgroundColor: ColorUtil.pageBgColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 顶部工具栏
            _buildTopBar(credits),
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
                    const SizedBox(height: 16),
                    // 头像区域
                    _buildAvatarSection(user?.userData.avatarUrl ?? ''),
                    const SizedBox(height: 16),
                    // 用户名
                    Text(
                      user?.userData.name ?? '',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Geist',
                        color: ColorUtil.textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // 域名
                    Text(
                      'dinq.me/${user?.userData.domain ?? ''}',
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Poppins',
                        color: ColorUtil.sub1TextColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // 订阅卡片
                    _buildSubscriptionCard(plan, credits),
                    const SizedBox(height: 16),
                    // Settings 入口
                    _buildSettingsButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(int credits) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 左侧积分和升级按钮
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Color(0xFFEBEBEB), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AssetImageView("remaining_score", width: 20, height: 20),
                const SizedBox(width: 4),
                Text(
                  '$credits',
                  style: TextStyle(fontSize: 14, fontFamily: 'Geist', color: ColorUtil.textColor),
                ),
                const SizedBox(width: 10),
                Container(height: 12, width: 1, color: Color(0xFFEAEAEA)),
                const SizedBox(width: 10),
                NormalButton(
                  onTap: () => context.push('/pricing'),
                  child: const Text(
                    'Upgrade',
                    style: TextStyle(fontSize: 14, fontFamily: 'Geist', color: Color(0xFF1487FA)),
                  ),
                ),
              ],
            ),
          ),
          // 右侧扫码图标
          GestureDetector(
            onTap: () {
              // TODO: 实现扫码功能
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              child: AssetImageView("qr_scan", width: 24, height: 24),
            ),
          ),
        ],
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
            decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFE0F0FF)),
            child: ClipOval(
              child: _isUploading
                  ? const Center(child: CircularProgressIndicator())
                  : avatarUrl.isNotEmpty
                  ? NetworkImageView(
                      imageUrl: avatarUrl,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      placeholder: const Icon(Icons.person, size: 60, color: Colors.grey),
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

  Widget _buildSubscriptionCard(String plan, int credits) {
    final isPro = plan.toLowerCase() != 'free';
    final displayPlan = isPro ? 'Pro' : 'Free';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFEEEEEE), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.05).toInt()),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
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
                if (!isPro)
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
          // 积分行
          NormalButton(
            onTap: () => context.push('/settings/subscription'),
            child: SizedBox(
              height: 54,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Credits',
                    style: TextStyle(fontSize: 14, fontFamily: 'Geist', color: Color(0xFF636363)),
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
        ],
      ),
    );
  }

  Widget _buildSettingsButton() {
    return NormalButton(
      onTap: () => context.push('/settings'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        height: 54,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          // boxShadow: [
          //   BoxShadow(
          //     color: Colors.black.withAlpha((255 * 0.05).toInt()),
          //     blurRadius: 10,
          //     offset: const Offset(0, 2),
          //   ),
          // ],
        ),
        child: Row(
          children: [
            AssetImageView("setting", width: 20, height: 20),
            const SizedBox(width: 8),
            Text(
              'Settings',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Geist',
                color: ColorUtil.textColor,
              ),
            ),
            const Spacer(),
            AssetImageView("gray_right", width: 20, height: 20),
          ],
        ),
      ),
    );
  }
}
