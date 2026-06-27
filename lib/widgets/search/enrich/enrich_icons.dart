import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../utils/onboarding_social_icons.dart';

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

/// 社媒图标：复用全量 [OnboardingSocialIcons.typeToIconFile]（22 个平台）映射到
/// `assets/icons/social-icons/*`。此前只映射 6 个平台、其余 fallback 到 Link，
/// 导致详情页大部分社媒图标缺失（显示成通用链接图标）。
String enrichSocialIconAsset(String type) {
  var key = type.toUpperCase();
  // 类型别名：后端可能用 google_scholar / x 等
  const aliases = {
    'GOOGLE_SCHOLAR': 'SCHOLAR',
    'X': 'TWITTER',
    'HOMEPAGE': 'WEBSITE',
    'PERSONAL': 'WEBSITE',
    'PERSONAL_WEBSITE': 'WEBSITE',
  };
  key = aliases[key] ?? key;
  final file = OnboardingSocialIcons.typeToIconFile[key] ?? 'link.svg';
  return OnboardingSocialIcons.assetFor(file);
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
