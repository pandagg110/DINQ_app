import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/app_update_service.dart';
import '../../utils/color_util.dart';

/// Help & Support → 点击 Version 触发的手动检测流程。
Future<void> showManualVersionCheckFlow(
  BuildContext context, {
  AppUpdateService? service,
}) async {
  final updateService = service ?? AppUpdateService();
  var cancelled = false;

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => _CheckingDialog(
      onCancel: () {
        cancelled = true;
        Navigator.of(dialogContext).pop();
      },
    ),
  );

  try {
    final result = await updateService.checkManually();

    if (!context.mounted || cancelled) return;
    Navigator.of(context, rootNavigator: true).pop();

    final info = result.info;
    final needsUpdate = info.updateType == AppUpdateType.optional ||
        info.updateType == AppUpdateType.force;

    if (needsUpdate) {
      await showDialog<void>(
        context: context,
        barrierDismissible: !info.isForceUpdate,
        builder: (_) => _UpdateRequiredDialog(
          currentVersion: result.currentVersion,
          requiredVersion: info.latestVersion.isNotEmpty
              ? info.latestVersion
              : info.minimumVersion,
          downloadUrl: info.downloadUrl,
          canDismiss: !info.isForceUpdate,
        ),
      );
    } else {
      final latest = info.latestVersion.isNotEmpty
          ? info.latestVersion
          : result.currentVersion;
      await showDialog<void>(
        context: context,
        builder: (_) => _UpToDateDialog(version: latest),
      );
    }
  } catch (_) {
    if (!context.mounted || cancelled) return;
    Navigator.of(context, rootNavigator: true).pop();

    final retry = await showDialog<bool>(
      context: context,
      builder: (_) => const _UpdateFailedDialog(),
    );
    if (retry == true && context.mounted) {
      await showManualVersionCheckFlow(context, service: updateService);
    }
  }
}

class _CheckingDialog extends StatelessWidget {
  const _CheckingDialog({required this.onCancel});

  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Checking for Updates',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: ColorUtil.textColor,
                fontFamily: 'Geist',
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Please wait while we check for the latest version.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: ColorUtil.sub2TextColor,
                fontFamily: 'Geist',
              ),
            ),
            const SizedBox(height: 28),
            const SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(
                strokeWidth: 3.5,
                color: Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(height: 28),
            const Divider(height: 1, color: Color(0xFFF0EEEB)),
            TextButton(
              onPressed: onCancel,
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: ColorUtil.sub3TextColor,
                  fontFamily: 'Geist',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpToDateDialog extends StatelessWidget {
  const _UpToDateDialog({required this.version});

  final String version;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F8EF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 36,
                color: Color(0xFF22C55E),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              "You're Up to Date",
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
              'DINQ $version is already the latest version.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: ColorUtil.sub2TextColor,
                fontFamily: 'Geist',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorUtil.textColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
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
    );
  }
}

class _UpdateFailedDialog extends StatelessWidget {
  const _UpdateFailedDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFFFEBEE),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                size: 34,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Update Failed',
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
              "We couldn't check for updates right now. Please check your network connection or try again later.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: ColorUtil.sub2TextColor,
                fontFamily: 'Geist',
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ColorUtil.sub3TextColor,
                        side: const BorderSide(color: Color(0xFFE5E5E5)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Geist',
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorUtil.textColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Try Again',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Geist',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UpdateRequiredDialog extends StatelessWidget {
  const _UpdateRequiredDialog({
    required this.currentVersion,
    required this.requiredVersion,
    required this.downloadUrl,
    required this.canDismiss,
  });

  final String currentVersion;
  final String requiredVersion;
  final String downloadUrl;
  final bool canDismiss;

  Future<void> _updateNow(BuildContext context) async {
    if (downloadUrl.isEmpty) return;
    await launchUrl(
      Uri.parse(downloadUrl),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: canDismiss
                    ? () => Navigator.of(context).pop()
                    : null,
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
                Text(
                  'For security and stability, updating is required.',
                  style: TextStyle(
                    fontSize: 12,
                    color: ColorUtil.sub3TextColor,
                    fontFamily: 'Geist',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => _updateNow(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorUtil.textColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text(
                  'Update Now',
                  style: TextStyle(
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
    );
  }

  Widget _versionRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: ColorUtil.sub2TextColor,
              fontFamily: 'Geist',
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor ?? ColorUtil.sub2TextColor,
              fontFamily: 'Geist',
            ),
          ),
        ],
      ),
    );
  }
}
