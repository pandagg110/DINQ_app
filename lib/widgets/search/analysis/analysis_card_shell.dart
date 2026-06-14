import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'analysis_theme.dart';

/// 与 TSX `CardShell.tsx` 严格对齐。
class AnalysisCardShell extends StatelessWidget {
  const AnalysisCardShell({
    super.key,
    required this.iconAsset,
    required this.title,
    required this.cardId,
    required this.child,
    this.showShareButton = true,
    this.onShare,
    this.inlineContext = true,
  });

  final String iconAsset;
  final String title;
  final String cardId;
  final Widget child;
  final bool showShareButton;
  final VoidCallback? onShare;
  final bool inlineContext;

  @override
  Widget build(BuildContext context) {
    final borderColor = inlineContext ? AnalysisTheme.borderInline : AnalysisTheme.borderDefault;

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasBoundedHeight = constraints.hasBoundedHeight && constraints.maxHeight.isFinite;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AnalysisTheme.cardBg,
            borderRadius: BorderRadius.circular(AnalysisTheme.radiusCard),
            border: Border.all(color: borderColor),
          ),
          clipBehavior: Clip.antiAlias,
          padding: const EdgeInsets.all(AnalysisTheme.paddingCard),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: hasBoundedHeight ? MainAxisSize.max : MainAxisSize.min,
            children: [
              _HeaderRow(
                iconAsset: iconAsset,
                title: title,
                showShareButton: showShareButton,
                onShare: onShare,
              ),
              const SizedBox(height: AnalysisTheme.gapCard),
              if (hasBoundedHeight)
                Expanded(child: child)
              else
                child,
              const SizedBox(height: 8),
              const _DinqWatermark(),
            ],
          ),
        );
      },
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.iconAsset,
    required this.title,
    required this.showShareButton,
    this.onShare,
  });

  final String iconAsset;
  final String title;
  final bool showShareButton;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AnalysisTheme.iconBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  iconAsset,
                  width: 16,
                  height: 16,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showShareButton) ...[
          const SizedBox(width: 8),
          Material(
            color: AnalysisTheme.primary,
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              onTap: onShare,
              borderRadius: BorderRadius.circular(999),
              child: const SizedBox(
                height: 40,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ShareIcon(),
                      SizedBox(width: 8),
                      Text(
                        'Share',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ShareIcon extends StatelessWidget {
  const _ShareIcon();

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/x-icon-white.svg',
      width: 16,
      height: 16,
    );
  }
}

/// 与 TSX `absolute bottom-5 right-5 text-xs text-right` 对齐，放在 Column 底部避免遮挡内容。
class _DinqWatermark extends StatelessWidget {
  const _DinqWatermark();

  static const _style = TextStyle(
    fontSize: AnalysisTheme.watermarkFontSize,
    height: AnalysisTheme.watermarkLineHeight,
    fontWeight: FontWeight.w400,
    fontFamily: AnalysisTheme.fontGeist,
    color: AnalysisTheme.watermark,
  );

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text.rich(
        TextSpan(
          style: _style,
          children: [
            const TextSpan(text: 'Made with '),
            TextSpan(
              text: 'DINQ',
              style: _style.copyWith(color: AnalysisTheme.primary),
            ),
            const TextSpan(text: '-AI Powered Academic Talent Analysis'),
          ],
        ),
        textAlign: TextAlign.right,
        maxLines: 2,
        softWrap: true,
        textScaler: TextScaler.noScaling,
      ),
    );
  }
}
