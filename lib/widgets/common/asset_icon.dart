import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../utils/asset_path.dart';

class AssetIcon extends StatelessWidget {
  const AssetIcon({super.key, required this.asset, this.size = 24, this.fit = BoxFit.contain});

  final String asset;
  final double size;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final path = assetPath(asset);
    if (asset.toLowerCase().endsWith('.svg')) {
      return SvgPicture.asset(path, width: size, height: size, fit: fit);
    }
    return Image.asset(path, width: size, height: size, fit: fit);
  }
}

