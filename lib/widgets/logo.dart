import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../utils/asset_path.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.showText = true,
    this.size = LogoSize.md,
    this.onTap,
    this.isAnalysis = false,
  });

  final bool showText;
  final LogoSize size;
  final VoidCallback? onTap;
  final bool isAnalysis;

  @override
  Widget build(BuildContext context) {
    final config = _sizeConfig[size]!;
    final asset = isAnalysis ? 'images/analysis/dinq-black.svg' : 'logo/dinq-black.svg';

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          assetPath(asset),
          width: config.iconWidth,
          height: config.iconHeight,
          fit: BoxFit.contain,
        ),
        if (showText) ...[
          const SizedBox(width: 8),
          Text(
            'DINQ',
            style: TextStyle(
              fontSize: config.textSize,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ],
    );

    if (onTap != null) {
      return InkWell(onTap: onTap, child: content);
    }
    return content;
  }
}

enum LogoSize { sm, md, lg }

class _LogoSizeConfig {
  const _LogoSizeConfig({
    required this.iconWidth,
    required this.iconHeight,
    required this.textSize,
  });

  final double iconWidth;
  final double iconHeight;
  final double textSize;
}

const Map<LogoSize, _LogoSizeConfig> _sizeConfig = {
  LogoSize.sm: _LogoSizeConfig(iconWidth: 20, iconHeight: 21, textSize: 16),
  LogoSize.md: _LogoSizeConfig(iconWidth: 24, iconHeight: 25, textSize: 20),
  LogoSize.lg: _LogoSizeConfig(iconWidth: 32, iconHeight: 33, textSize: 24),
};


