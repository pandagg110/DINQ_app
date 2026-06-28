import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 对齐 Web `EnrichProfileView.tsx` lucide-react 图标 + social-icons 资源。
abstract final class EnrichIcons {
  static const briefcase = 'assets/icons/search/enrich/briefcase.svg';
  static const graduationCap = 'assets/icons/search/enrich/graduation-cap.svg';
  static const mapPin = 'assets/icons/search/enrich/map-pin.svg';
  static const mail = 'assets/icons/search/enrich/mail.svg';
  static const externalLink = 'assets/icons/search/enrich/external-link.svg';
  static const bookmark = 'assets/icons/search/enrich/bookmark.svg';
  static const bookmarkFilled = 'assets/icons/search/enrich/bookmark-filled.svg';
  static const refresh = 'assets/icons/search/enrich/rotate-ccw.svg';
  static const chevronDown = 'assets/icons/search/enrich/chevron-down.svg';
  static const chevronUp = 'assets/icons/search/enrich/chevron-up.svg';
  static const check = 'assets/icons/search/enrich/check.svg';
  static const alertCircle = 'assets/icons/search/enrich/alert-circle.svg';
  static const copy = 'assets/icons/search/enrich/copy.svg';
  static const globe = 'assets/icons/search/enrich/globe.svg';
  static const zap = 'assets/icons/search/enrich/zap.svg';
}

/// 对齐 Web `socialIconPath()` → `/icons/social-icons/{mapped}.svg`
String enrichSocialIconAsset(String type) {
  const map = {
    'google_scholar': 'assets/icons/social-icons/Scholar.svg',
    'linkedin': 'assets/icons/social-icons/LinkedIn.svg',
    'github': 'assets/icons/social-icons/Github.svg',
    'openreview': 'assets/icons/social-icons/OpenReview.svg',
    'twitter': 'assets/icons/social-icons/Twitter.svg',
    'huggingface': 'assets/icons/social-icons/HuggingFace.svg',
  };
  return map[type] ?? 'assets/icons/social-icons/Link.svg';
}

class EnrichSvgIcon extends StatelessWidget {
  const EnrichSvgIcon(
    this.asset, {
    super.key,
    this.size = 14,
    this.color = const Color(0xFF9E9A94),
  });

  final String asset;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.asset(
        asset,
        width: size,
        height: size,
        fit: BoxFit.contain,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      ),
    );
  }
}
