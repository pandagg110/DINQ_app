import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../utils/asset_path.dart';
import '../../utils/icon_mapping.dart';

class AssetIcon extends StatelessWidget {
  const AssetIcon({super.key, required this.asset, this.size = 24, this.fit = BoxFit.contain});

  final String asset;
  final double size;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    // If it's a social-icons SVG, map it to logo PNG
    String finalAsset = asset;
    if (asset.contains('icons/social-icons/')) {
      finalAsset = mapSvgToPng(asset);
    }
    
    final path = assetPath(finalAsset);
    
    // PNG files are handled by Image.asset
    if (finalAsset.toLowerCase().endsWith('.png')) {
      return Image.asset(path, width: size, height: size, fit: fit);
    }
    
    // SVG files are handled by SvgPicture.asset
    if (finalAsset.toLowerCase().endsWith('.svg')) {
      return SvgPicture.asset(path, width: size, height: size, fit: fit);
    }
    
    // Default to Image.asset for other formats
    return Image.asset(path, width: size, height: size, fit: fit);
  }
}

