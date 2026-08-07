import 'package:flutter/material.dart';

import '../../services/app_update_service.dart';
import '../../utils/color_util.dart';
import 'update_required_panel.dart';

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
        builder: (dialogContext) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: EdgeInsets.zero,
          child: UpdateRequiredPanel(
            canSkip: !info.isForceUpdate,
            releaseNotes: UpdateRequiredPanel.parseReleaseNotes(
              info.releaseNotes,
            ),
            onSkip: info.isForceUpdate
                ? null
                : () => Navigator.of(dialogContext).pop(),
            onUpdateNow: () {
              if (info.downloadUrl.isEmpty) return;
              openAppUpdateUrl(info.downloadUrl);
            },
          ),
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
