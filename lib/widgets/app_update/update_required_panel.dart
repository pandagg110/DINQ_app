import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/color_util.dart';

/// 强制/可选更新共用面板（门禁遮罩 & Help 弹窗）。
class UpdateRequiredPanel extends StatelessWidget {
  const UpdateRequiredPanel({
    super.key,
    required this.currentVersion,
    required this.requiredVersion,
    required this.onUpdateNow,
    this.onDismiss,
    this.opening = false,
    this.error,
  });

  final String currentVersion;
  final String requiredVersion;
  final VoidCallback onUpdateNow;
  final VoidCallback? onDismiss;
  final bool opening;
  final String? error;

  bool get canDismiss => onDismiss != null;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 360,
        margin: const EdgeInsets.symmetric(horizontal: 28),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: canDismiss ? onDismiss : null,
                icon: Icon(
                  Icons.close,
                  color: canDismiss
                      ? ColorUtil.sub3TextColor
                      : Colors.transparent,
                ),
              ),
            ),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FF),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.18),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.security_update_good_rounded,
                size: 36,
                color: Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Update Required',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: ColorUtil.textColor,
                fontFamily: 'Geist',
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'This version is no longer supported. Please update to continue using DINQ.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: ColorUtil.sub2TextColor,
                fontFamily: 'Geist',
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F6F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _versionRow('Current version', currentVersion),
                  const Divider(height: 1, color: Color(0xFFE8E8E8)),
                  _versionRow(
                    'Required version',
                    requiredVersion.isEmpty ? '—' : requiredVersion,
                    valueColor: const Color(0xFF3B82F6),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 14, color: ColorUtil.sub3TextColor),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'For security and stability, updating is required.',
                    style: TextStyle(
                      fontSize: 12,
                      color: ColorUtil.sub3TextColor,
                      fontFamily: 'Geist',
                    ),
                  ),
                ),
              ],
            ),
            if (error != null) ...[
              const SizedBox(height: 12),
              Text(
                error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: opening ? null : onUpdateNow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorUtil.textColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: ColorUtil.textColor.withValues(
                    alpha: 0.6,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Text(
                  opening ? 'Opening…' : 'Update Now',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Geist',
                  ),
                ),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _versionRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: ColorUtil.sub2TextColor,
                fontFamily: 'Geist',
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor ?? ColorUtil.sub2TextColor,
                fontFamily: 'Geist',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<bool> openAppUpdateUrl(String url) {
  return launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}
