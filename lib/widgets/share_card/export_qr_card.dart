/**
 * ExportQrCard - Flutter 迁移自 Web example/src/app/[username]/components/shareCard/ExportQrCard.tsx
 * 分享卡片 QR 码组件：QR 码 + 中心头像 + dinq.me/username
 */

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/user_models.dart';
import '../../utils/asset_path.dart';

/// 分享 Profile 的 QR 码卡片，对应 Web [ExportQrCard](example/.../ExportQrCard.tsx)
/// 包含 QR 码、中心头像叠加、底部 dinq.me/username
class ExportQrCard extends StatelessWidget {
  const ExportQrCard({
    super.key,
    required this.userInfo,
    required this.username,
    required this.profileUrl,
    this.forExport = false,
    this.size = 210,
  });

  final UserData userInfo;
  final String username;
  final String profileUrl;
  /// 是否用于导出（无圆角）
  final bool forExport;
  /// QR 码尺寸，默认 210
  final double size;

  String get _qrValue => profileUrl.isNotEmpty ? profileUrl : 'https://mydinq.com/$username';

  String get _avatarUrl =>
      userInfo.avatarUrl.isNotEmpty ? userInfo.avatarUrl : assetPath('images/default-avatar.svg');

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 315,
      height: 330,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD8D8D8)),
        borderRadius: forExport ? BorderRadius.zero : BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Center(
              child: _buildQrWithAvatar(),
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Column(
              children: [
                Container(
                  height: 1,
                  color: const Color(0xFFD8D8D8),
                ),
                const SizedBox(height: 12),
                Text(
                  'dinq.me/$username',
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 14,
                    height: 1.4,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrWithAvatar() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: QrImageView(
            data: _qrValue,
            version: QrVersions.auto,
            size: size,
            backgroundColor: Colors.white,
            gapless: true,
          ),
        ),
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: ClipOval(
            child: _avatarUrl.startsWith('http')
                ? Image.network(_avatarUrl, fit: BoxFit.cover)
                : SvgPicture.asset(
                    _avatarUrl,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                  ),
          ),
        ),
      ],
    );
  }
}
