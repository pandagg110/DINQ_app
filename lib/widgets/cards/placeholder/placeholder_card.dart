import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import '../../common/asset_icon.dart';
import 'placeholder_config.dart';

class PlaceholderCard extends StatelessWidget {
  const PlaceholderCard({super.key, required this.config, required this.onTap});

  final PlaceholderCardConfig config;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final config = this.config;
    final isImage = config.type.toUpperCase() == 'IMAGE';
    final label = isImage ? 'Image/Video' : 'Analysis';
    final isMobile = MediaQuery.sizeOf(context).width < 768;
    final iconSize = isMobile ? 36.0 : 48.0;
    final gap = isMobile ? 12.0 : 16.0;
    final buttonHorizontalPadding = isMobile ? 16.0 : 24.0;
    final buttonVerticalPadding = isMobile ? 8.0 : 12.0;
    final buttonIconSize = isMobile ? 12.0 : 16.0;
    final buttonFontSize = isMobile ? 12.0 : 14.0;

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
                _buildIcon(context, iconSize),
                SizedBox(height: gap),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: buttonHorizontalPadding,
                    vertical: buttonVerticalPadding,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD8D8D8)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add,
                        size: buttonIconSize,
                        color: const Color(0xFF666666),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: buttonFontSize,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF666666),
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

  Widget _buildIcon(BuildContext context, double size) {
    final config = this.config;
    final icon = config.icon;
    if (icon.startsWith('i-')) {
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          _iconDataFor(icon),
          size: size / 2,
          color: const Color(0xFF171717),
        ),
      );
    }

    return AssetIcon(asset: icon, size: size);
  }

  static IconData _iconDataFor(String iconClass) {
    if (iconClass.startsWith('i-lucide-')) {
      final name = iconClass.replaceFirst('i-lucide-', '');
      return _lucideMap[name] ?? Icons.extension;
    }
    return Icons.extension;
  }

  static const _lucideMap = <String, IconData>{
    'network': Icons.account_tree_outlined,
    'trending-up': Icons.trending_up,
    'link': Icons.link,
  };
}
