import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../common/asset_icon.dart';
import '../factory/card_registry.dart';
import 'placeholder_config.dart';

class PlaceholderCard extends StatelessWidget {
  const PlaceholderCard({
    super.key,
    required this.config,
    required this.onTap,
  });

  final PlaceholderCardConfig config;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final config = this.config;
    final isImage = config.type.toUpperCase() == 'IMAGE';
    final label = isImage ? 'Image/Video' : 'Analysis';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: DottedBorder(
          options: RoundedRectDottedBorderOptions(
            radius: const Radius.circular(24),
            strokeWidth: 2,
            dashPattern: const [8, 4],
            color: const Color(0xFFD8D8D8),
          ),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildIcon(context),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFD8D8D8),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    final config = this.config;
    final definition = CardRegistry().getDefinition(config.type);
    if (definition != null) {
      final icon = definition.icon;
      if (icon.startsWith('i-lucide-') || icon.startsWith('i-mdi:')) {
        final iconData = _iconDataFor(icon);
        return Icon(iconData, size: 48, color: Colors.grey[700]);
      }
      final asset = icon.startsWith('/') ? icon.substring(1) : icon;
      return AssetIcon(asset: asset, size: 48);
    }
    if (config.iconAsset != null) {
      final path = config.iconAsset!;
      if (path.endsWith('.svg')) {
        return SvgPicture.asset(
          path,
          width: 48,
          height: 48,
          fit: BoxFit.contain,
        );
      }
      return Image.asset(
        path,
        width: 48,
        height: 48,
        fit: BoxFit.contain,
      );
    }
    return Icon(Icons.add_circle_outline, size: 48, color: Colors.grey[600]);
  }

  static IconData _iconDataFor(String iconClass) {
    if (iconClass.startsWith('i-lucide-')) {
      final name = iconClass.replaceFirst('i-lucide-', '');
      return _lucideMap[name] ?? Icons.extension;
    }
    if (iconClass.startsWith('i-mdi:')) {
      final name = iconClass.replaceFirst('i-mdi:', '').replaceAll('-', '_');
      return _mdiMap[name] ?? Icons.extension;
    }
    return Icons.extension;
  }

  static const _lucideMap = <String, IconData>{
    'network': Icons.account_tree_outlined,
    'trending-up': Icons.trending_up,
    'heading': Icons.title,
    'sticky-note': Icons.note_outlined,
    'link': Icons.link,
    'image': Icons.image_outlined,
  };
  static const _mdiMap = <String, IconData>{
    'file_text_outline': Icons.summarize_outlined,
    'iframe_brackets_outline': Icons.code,
  };
}
