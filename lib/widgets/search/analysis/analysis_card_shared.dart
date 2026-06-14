import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'analysis_theme.dart';

/// 与 TSX analysis 卡片内共享 UI 片段对齐。
class AnalysisInfoBanner extends StatelessWidget {
  const AnalysisInfoBanner({super.key, required this.text, this.iconAsset});

  final String text;
  final String? iconAsset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF0EB),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            iconAsset ?? 'assets/images/analysis/wrapper.svg',
            width: 16,
            height: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
            ),
          ),
        ],
      ),
    );
  }
}

class AnalysisLeftAccentPanel extends StatelessWidget {
  const AnalysisLeftAccentPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: const BoxDecoration(
        color: Color(0xFFFAF2EF),
        borderRadius: BorderRadius.all(Radius.circular(4)),
        border: Border(
          left: BorderSide(color: Color(0xFFCB7C5D), width: 4),
        ),
      ),
      child: child,
    );
  }
}

class AnalysisSectionDivider extends StatelessWidget {
  const AnalysisSectionDivider({super.key, this.accentWidth = 100});

  final double accentWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 16,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Positioned(
            top: 7,
            left: 0,
            right: 0,
            child: Container(height: 1, color: const Color(0xFFECECEC)),
          ),
          Container(
            width: accentWidth,
            height: 1,
            color: const Color(0xFFC88D75),
          ),
        ],
      ),
    );
  }
}

class AnalysisAvatar extends StatelessWidget {
  const AnalysisAvatar({super.key, this.url, this.size = 70});

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: const Color(0xFFEEEEEE),
      backgroundImage: url != null && url!.isNotEmpty ? NetworkImage(url!) : null,
      child: url == null || url!.isEmpty
          ? Image.asset(
              AnalysisTheme.defaultAvatar,
              width: size,
              height: size,
              fit: BoxFit.cover,
            )
          : null,
    );
  }
}

/// 与 TSX `defaultCompany.png` 公司 logo 占位对齐。
class AnalysisCompanyLogo extends StatelessWidget {
  const AnalysisCompanyLogo({super.key, this.url, this.radius = 21});

  final String? url;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    if (url != null && url!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          url!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(size),
        ),
      );
    }
    return _fallback(size);
  }

  Widget _fallback(double size) {
    return ClipOval(
      child: Image.asset(
        AnalysisTheme.defaultCompany,
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}

class AnalysisReasonBox extends StatelessWidget {
  const AnalysisReasonBox({
    super.key,
    required this.text,
    this.maxLines = 6,
    this.height,
  });

  final String text;
  final int maxLines;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF2EF),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        text,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 14,
          height: 1.5,
          color: Color(0xFF464646),
        ),
      ),
    );
  }
}

class AnalysisMetricBadge extends StatelessWidget {
  const AnalysisMetricBadge({
    super.key,
    required this.value,
    required this.label,
    required this.iconAsset,
  });

  final String value;
  final String label;
  final String iconAsset;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 85,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F2F1),
        borderRadius: BorderRadius.circular(AnalysisTheme.radiusMd),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  fontFamily: AnalysisTheme.fontUdc,
                  color: Colors.black,
                ),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Color(0xFF969696)),
              ),
            ],
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFFEEDFD9),
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.all(4),
              child: SvgPicture.asset(iconAsset),
            ),
          ),
        ],
      ),
    );
  }
}
