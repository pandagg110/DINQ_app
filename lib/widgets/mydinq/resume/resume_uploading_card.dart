import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'resume_icons.dart';

enum UploadPhase { uploading, processing }

/// 对齐 Web `ResumeUploadingCard.tsx`。
class ResumeUploadingCard extends StatefulWidget {
  const ResumeUploadingCard({
    super.key,
    required this.fileName,
    required this.progress,
    required this.secondsLeft,
    this.phase = UploadPhase.uploading,
    required this.onCancel,
  });

  final String fileName;
  final int progress;
  final int secondsLeft;
  final UploadPhase phase;
  final VoidCallback onCancel;

  @override
  State<ResumeUploadingCard> createState() => _ResumeUploadingCardState();
}

class _ResumeUploadingCardState extends State<ResumeUploadingCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clamped = widget.progress.clamp(0, 100);
    final safeSeconds = widget.secondsLeft.clamp(0, 9999);
    final title = widget.phase == UploadPhase.uploading
        ? 'Uploading resume...'
        : 'Processing resume...';

    return Container(
      constraints: const BoxConstraints(maxWidth: 680),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      decoration: BoxDecoration(
        color: const Color(0x0D007AFF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF007AFF), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _floatController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -6 * _floatController.value),
                child: child,
              );
            },
            child: SvgPicture.asset(
              ResumeIcons.resumeUploading,
              width: 96,
              height: 128,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF171717),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.fileName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 24),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: clamped / 100,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE5E7EB),
                    color: const Color(0xFF4E91DB),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$clamped% complete',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4E91DB),
                      ),
                    ),
                    Text(
                      '~$safeSeconds seconds left',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: widget.onCancel,
            child: const Text(
              'Cancel upload',
              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
          ),
        ],
      ),
    );
  }
}
