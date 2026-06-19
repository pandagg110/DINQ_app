import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';

import '../../../widgets/common/base_page.dart';
import 'onboarding_icons.dart';

/// 对齐 Web `/onboarding/upload/page.tsx`；移动端对齐设计稿。
class OnboardingUploadView extends StatelessWidget {
  const OnboardingUploadView({
    super.key,
    required this.fileName,
    this.fileSizeBytes,
    required this.isUploading,
    required this.uploadProgress,
    required this.onPickFile,
    required this.onBack,
    required this.onContinue,
    this.canContinue = false,
  });

  final String fileName;
  final int? fileSizeBytes;
  final bool isUploading;
  final int uploadProgress;
  final VoidCallback onPickFile;
  final VoidCallback onBack;
  final VoidCallback onContinue;
  final bool canContinue;

  static bool _isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 768;

  @override
  Widget build(BuildContext context) {
    if (_isMobile(context)) {
      return _MobileUploadLayout(
        fileName: fileName,
        fileSizeBytes: fileSizeBytes,
        isUploading: isUploading,
        uploadProgress: uploadProgress,
        onPickFile: onPickFile,
        onBack: onBack,
        onContinue: onContinue,
        canContinue: canContinue,
      );
    }
    return _DesktopUploadLayout(
      fileName: fileName,
      fileSizeBytes: fileSizeBytes,
      isUploading: isUploading,
      uploadProgress: uploadProgress,
      onPickFile: onPickFile,
      onBack: onBack,
      onContinue: onContinue,
      canContinue: canContinue,
    );
  }
}

class _MobileUploadLayout extends StatelessWidget {
  const _MobileUploadLayout({
    required this.fileName,
    this.fileSizeBytes,
    required this.isUploading,
    required this.uploadProgress,
    required this.onPickFile,
    required this.onBack,
    required this.onContinue,
    required this.canContinue,
  });

  final String fileName;
  final int? fileSizeBytes;
  final bool isUploading;
  final int uploadProgress;
  final VoidCallback onPickFile;
  final VoidCallback onBack;
  final VoidCallback onContinue;
  final bool canContinue;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final continueEnabled = canContinue && !isUploading;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: _CircleBackButton(onTap: onBack),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Column(
              children: [
                const Text(
                  'Upload Resume',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: _UploadColors.textPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Please provide your most recent resume. We use this to better '
                  'understand your background and tailor your experience.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: _UploadColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 320,
                  width: double.infinity,
                  child: _UploadDropZone(
                    hasFile: fileName.isNotEmpty,
                    fileName: fileName,
                    fileSizeLabel: fileSizeBytes != null
                        ? _UploadColors.formatSize(fileSizeBytes!)
                        : null,
                    isUploading: isUploading,
                    uploadProgress: uploadProgress,
                    onTap: isUploading ? null : onPickFile,
                    emptyHint: 'PDF, DOC, DOCX (Max 10MB)',
                    iconSize: 56,
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + bottomPad),
          child: _ContinueButton(
            label: isUploading ? 'Uploading...' : 'Continue',
            onPressed: continueEnabled ? onContinue : null,
            fullWidth: true,
            height: 52,
            borderRadius: 12,
          ),
        ),
      ],
    );
  }
}

class _DesktopUploadLayout extends StatelessWidget {
  const _DesktopUploadLayout({
    required this.fileName,
    this.fileSizeBytes,
    required this.isUploading,
    required this.uploadProgress,
    required this.onPickFile,
    required this.onBack,
    required this.onContinue,
    required this.canContinue,
  });

  final String fileName;
  final int? fileSizeBytes;
  final bool isUploading;
  final int uploadProgress;
  final VoidCallback onPickFile;
  final VoidCallback onBack;
  final VoidCallback onContinue;
  final bool canContinue;

  @override
  Widget build(BuildContext context) {
    final continueEnabled = canContinue && !isUploading;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 576),
          child: Column(
            children: [
              Text(
                'Upload Resume',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: MediaQuery.sizeOf(context).width >= 768 ? 40 : 32,
                  fontWeight: FontWeight.w600,
                  color: _UploadColors.textPrimary,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Please provide your most recent resume. We'll use this to better "
                'understand your background and tailor your experience.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 14,
                  color: _UploadColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              AspectRatio(
                aspectRatio: 2 / 1,
                child: _UploadDropZone(
                  hasFile: fileName.isNotEmpty,
                  fileName: fileName,
                  fileSizeLabel: fileSizeBytes != null
                      ? _UploadColors.formatSize(fileSizeBytes!)
                      : null,
                  isUploading: isUploading,
                  uploadProgress: uploadProgress,
                  onTap: isUploading ? null : onPickFile,
                  emptyHint: 'PDF only (Max 10MB)',
                ),
              ),
              const SizedBox(height: 40),
              _UploadFooter(
                isUploading: isUploading,
                continueEnabled: continueEnabled,
                onBack: onBack,
                onContinue: onContinue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

abstract final class _UploadColors {
  static const textPrimary = Color(0xFF171717);
  static const textSecondary = Color(0xFF6B6862);
  static const textMuted = Color(0xFF9E9B93);
  static const border = Color(0xFFDCD9D2);

  static String formatSize(int bytes) {
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }
}

class _CircleBackButton extends StatelessWidget {
  const _CircleBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Center(
            child: AssetImageView('nav_back', width: 20, height: 20),
          ),
        ),
      ),
    );
  }
}

class _UploadDropZone extends StatefulWidget {
  const _UploadDropZone({
    required this.hasFile,
    required this.fileName,
    this.fileSizeLabel,
    required this.isUploading,
    required this.uploadProgress,
    required this.onTap,
    required this.emptyHint,
    this.iconSize = 48,
  });

  final bool hasFile;
  final String fileName;
  final String? fileSizeLabel;
  final bool isUploading;
  final int uploadProgress;
  final VoidCallback? onTap;
  final String emptyHint;
  final double iconSize;

  @override
  State<_UploadDropZone> createState() => _UploadDropZoneState();
}

class _UploadDropZoneState extends State<_UploadDropZone> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        onHover: (v) => setState(() => _isDragging = v),
        borderRadius: BorderRadius.circular(16),
        child: DottedBorder(
          options: RoundedRectDottedBorderOptions(
            radius: const Radius.circular(16),
            strokeWidth: 1.5,
            dashPattern: const [6, 5],
            color: _isDragging ? _UploadColors.textPrimary : _UploadColors.border,
            padding: EdgeInsets.zero,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: _isDragging ? const Color(0xFFFAF9F5) : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.hasFile) ...[
                    Container(
                      width: widget.iconSize,
                      height: widget.iconSize,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFEF2F2),
                        shape: BoxShape.circle,
                      ),
                      child: OnboardingSvgIcon(
                        OnboardingIcons.fileText,
                        size: widget.iconSize * 0.42,
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.fileName,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _UploadColors.textPrimary,
                      ),
                    ),
                    if (widget.fileSizeLabel != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.fileSizeLabel!,
                        style: const TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 12,
                          color: _UploadColors.textMuted,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    const Text(
                      'Click or drop to replace',
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 12,
                        color: _UploadColors.textMuted,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ] else ...[
                    Container(
                      width: widget.iconSize,
                      height: widget.iconSize,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF0EEE8),
                        shape: BoxShape.circle,
                      ),
                      child: OnboardingSvgIcon(
                        OnboardingIcons.upload,
                        size: widget.iconSize * 0.38,
                        color: _UploadColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Click to upload or drag & drop',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _UploadColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.emptyHint,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 13,
                        color: _UploadColors.textMuted,
                      ),
                    ),
                  ],
                  if (widget.isUploading) ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 200,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: widget.uploadProgress / 100,
                          minHeight: 6,
                          backgroundColor: const Color(0xFFEEEDE9),
                          color: _UploadColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({
    required this.label,
    required this.onPressed,
    this.fullWidth = false,
    this.height = 44,
    this.borderRadius = 12,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool fullWidth;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? const Color(0xFF171717) : const Color(0xFFE5E5E5),
          foregroundColor: enabled ? Colors.white : const Color(0xFF303030).withValues(alpha: 0.4),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Geist',
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// 桌面端：Back + Next Step。
class _UploadFooter extends StatelessWidget {
  const _UploadFooter({
    required this.isUploading,
    required this.continueEnabled,
    required this.onBack,
    required this.onContinue,
  });

  final bool isUploading;
  final bool continueEnabled;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          onPressed: onBack,
          child: const Text(
            '← Back',
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 14,
              color: Color(0xFF6B6862),
            ),
          ),
        ),
        _ContinueButton(
          label: isUploading ? 'Uploading...' : 'Next Step →',
          onPressed: continueEnabled ? onContinue : null,
        ),
      ],
    );
  }
}
