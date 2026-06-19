import 'package:flutter/material.dart';

const _analyzeSteps = [
  'Reading source',
  'Finding profile signals',
  'Preparing your DINQ draft',
];

/// 对齐 Web `/onboarding/analyze/page.tsx`。
class OnboardingAnalyzeView extends StatelessWidget {
  const OnboardingAnalyzeView({
    super.key,
    required this.mode,
    required this.sourceLabel,
    required this.activeStep,
    this.error,
    required this.onRetry,
  });

  final String mode;
  final String? sourceLabel;
  final int activeStep;
  final String? error;
  final VoidCallback onRetry;

  bool get _isResume => mode == 'resume';

  @override
  Widget build(BuildContext context) {
    final title =
        _isResume ? 'Processing your resume' : 'Analyzing your profile';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 448),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF171717),
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "We're preparing a first draft. You can edit the basic and "
                'detailed information after this step.',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 14,
                  color: Color(0xFF6B6862),
                  height: 1.5,
                ),
              ),
              if (sourceLabel != null && sourceLabel!.isNotEmpty) ...[
                const SizedBox(height: 24),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color(0xFFEEEDE9)),
                  ),
                  child: Text(
                    sourceLabel!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 14,
                      color: Color(0xFF6B6862),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ...List.generate(_analyzeSteps.length, (index) {
                final isDone = index < activeStep;
                final isActive = index == activeStep;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDone
                              ? const Color(0xFF171717)
                              : Colors.transparent,
                          border: Border.all(
                            color: isDone || isActive
                                ? const Color(0xFF171717)
                                : const Color(0xFFEEEDE9),
                          ),
                        ),
                        child: isDone
                            ? const Icon(Icons.check,
                                size: 14, color: Colors.white)
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontFamily: 'Geist',
                                  fontSize: 12,
                                  color: isActive
                                      ? const Color(0xFF171717)
                                      : const Color(0xFF9E9B93),
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _analyzeSteps[index],
                          style: TextStyle(
                            fontFamily: 'Geist',
                            fontSize: 14,
                            color: isActive
                                ? const Color(0xFF171717)
                                : const Color(0xFF6B6862),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              if (error != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color(0xFFFECACA)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        error!,
                        style: const TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 14,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: onRetry,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF171717),
                          side: const BorderSide(color: Color(0xFFFECACA)),
                        ),
                        child: Text(
                          _isResume ? 'Upload again' : 'Try another source',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
