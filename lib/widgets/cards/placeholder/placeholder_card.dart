import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'placeholder_config.dart';

class PlaceholderCard extends StatefulWidget {
  const PlaceholderCard({
    super.key,
    required this.config,
    required this.onTap,
    required this.onDelete,
  });

  final PlaceholderCardConfig config;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  State<PlaceholderCard> createState() => _PlaceholderCardState();
}

class _PlaceholderCardState extends State<PlaceholderCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final config = widget.config;
    final isImage = config.type.toUpperCase() == 'IMAGE';
    final label = isImage ? 'Image/Video' : 'Analysis';

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFD8D8D8),
                  width: 2,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
              ),
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFD8D8D8),
                    width: 2,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
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
                          strokeAlign: BorderSide.strokeAlignInside,
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
        ),
        Positioned(
          top: -12,
          left: -12,
          child: IgnorePointer(
            ignoring: !_hovering,
            child: AnimatedOpacity(
              opacity: _hovering ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onDelete,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE9E9E9)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(Icons.delete_outline, size: 20, color: Colors.red[400]),
                  ),
                ),
              ),
            ),
          ),
        ),
        ],
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    final config = widget.config;
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
    if (widget.config.type.toUpperCase() == 'CAREER_TRAJECTORY') {
      return Icon(Icons.trending_up, size: 48, color: Colors.grey[700]);
    }
    return Icon(Icons.add_circle_outline, size: 48, color: Colors.grey[600]);
  }
}
