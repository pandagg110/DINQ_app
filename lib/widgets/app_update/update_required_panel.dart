import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/color_util.dart';

/// 强制/可选更新共用面板（门禁遮罩 & Help 弹窗）。
///
/// [canSkip] 为 true 时显示 Skip + Update；为 false 时仅显示全宽 Update。
class UpdateRequiredPanel extends StatelessWidget {
  const UpdateRequiredPanel({
    super.key,
    required this.onUpdateNow,
    this.onSkip,
    this.canSkip,
    this.releaseNotes,
    this.opening = false,
    this.error,
  });

  final VoidCallback onUpdateNow;
  final VoidCallback? onSkip;
  final bool? canSkip;
  final List<String>? releaseNotes;
  final bool opening;
  final String? error;

  bool get _skippable => canSkip ?? onSkip != null;

  /// 将接口 [release_notes] 拆成展示行；空则返回空列表（不再使用本地占位文案）。
  static List<String> parseReleaseNotes(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];
    return raw
        .split(RegExp(r'[\r\n]+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final notes = releaseNotes ?? const <String>[];
    final skippable = _skippable;

    return Material(
      color: Colors.transparent,
      child: Container(
        key: const ValueKey('update-required-panel'),
        width: 335,
        constraints: const BoxConstraints(maxHeight: 420),
        margin: const EdgeInsets.symmetric(horizontal: 28),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/app_update_mascot.png',
              width: 140,
              height: 140,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF2FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.system_update_alt_rounded,
                  size: 40,
                  color: Color(0xFF3B82F6),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'New Version Available',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                height: 24 / 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
                color: ColorUtil.textColor,
                fontFamily: 'Geist',
              ),
            ),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Flexible(
                fit: FlexFit.loose,
                child: SingleChildScrollView(
                  key: const ValueKey('update-release-notes-scroll'),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < notes.length; i++) ...[
                          if (i > 0)
                            SizedBox(
                              key: ValueKey('update-release-note-gap-$i'),
                              height: 4,
                            ),
                          Text(
                            key: ValueKey('update-release-note-$i'),
                            notes[i],
                            style: const TextStyle(
                              fontSize: 12,
                              height: 18 / 12,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF575757),
                              fontFamily: 'Geist',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
            if (error != null) ...[
              const SizedBox(height: 12),
              Text(
                error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
            const SizedBox(height: 24),
            if (skippable)
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: opening ? null : onSkip,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFB5B0A8),
                          side: const BorderSide(color: Color(0xFFE5E5E5)),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Geist',
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _buildUpdateButton()),
                ],
              )
            else
              SizedBox(width: double.infinity, child: _buildUpdateButton()),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateButton() {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: opening ? null : onUpdateNow,
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorUtil.textColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: ColorUtil.textColor.withValues(alpha: 0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          opening ? 'Opening…' : 'Update',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Geist',
          ),
        ),
      ),
    );
  }
}

Future<bool> openAppUpdateUrl(String url) {
  return launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}
