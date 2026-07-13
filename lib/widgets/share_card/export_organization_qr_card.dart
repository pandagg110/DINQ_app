import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/organization_share_models.dart';
import '../../utils/org_avatar.dart';

/// 组织分享 QR 码卡片，对齐 Web ShareModal organization 分支的 ExportQrCard。
class ExportOrganizationQrCard extends StatelessWidget {
  const ExportOrganizationQrCard({
    super.key,
    required this.org,
    required this.profileUrl,
    this.forExport = false,
    this.size = 210,
  });

  final OrganizationShareTarget org;
  final String profileUrl;
  final bool forExport;
  final double size;

  String get _qrValue =>
      profileUrl.isNotEmpty ? profileUrl : 'https://dinq.me/${org.slug}';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 315,
      height: 330,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: forExport ? BorderRadius.zero : BorderRadius.circular(12),
      ),
      foregroundDecoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD8D8D8)),
        borderRadius: forExport ? BorderRadius.zero : BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(child: Center(child: _buildQrWithLogo())),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(height: 1, color: const Color(0xFFD8D8D8)),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            alignment: Alignment.center,
            child: Text(
              'dinq.me/${org.slug}',
              style: const TextStyle(
                fontFamily: 'Geist',
                fontSize: 14,
                height: 1.4,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrWithLogo() {
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
                color: Colors.black.withValues(alpha: 0.04),
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
          child: ClipOval(child: _buildLogo()),
        ),
      ],
    );
  }

  Widget _buildLogo() {
    final logoUrl = org.logoUrl?.trim() ?? '';
    if (logoUrl.isNotEmpty) {
      return Image.network(
        logoUrl,
        width: 52,
        height: 52,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _logoFallback(),
      );
    }
    return _logoFallback();
  }

  Widget _logoFallback() {
    return Container(
      width: 52,
      height: 52,
      color: orgAvatarColor(org.name),
      alignment: Alignment.center,
      child: Text(
        orgInitials(org.name),
        style: const TextStyle(
          fontFamily: 'Geist',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1F1F1F),
        ),
      ),
    );
  }
}
