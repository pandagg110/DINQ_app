import 'package:flutter/material.dart';
import '../../constants/landing.dart';
import '../common/asset_icon.dart';

class RolesMarquee extends StatefulWidget {
  const RolesMarquee({super.key, required this.items});

  final List<RoleItem> items;

  @override
  State<RolesMarquee> createState() => _RolesMarqueeState();
}

class _RolesMarqueeState extends State<RolesMarquee> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const itemWidth = 180.0;
    final totalWidth = itemWidth * widget.items.length;
    final repeatedItems = [...widget.items, ...widget.items];
    final rowWidth = itemWidth * repeatedItems.length;

    return SizedBox(
      height: 120,
      width: double.infinity,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final offset = (_controller.value * totalWidth) * -1;
            return Transform.translate(
              offset: Offset(offset, 0),
              child: child,
            );
          },
          child: OverflowBox(
            alignment: Alignment.centerLeft,
            minWidth: rowWidth,
            maxWidth: rowWidth,
            child: Row(
              children: repeatedItems.map((item) {
                return SizedBox(
                  width: itemWidth,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AssetIcon(asset: item.icon, size: 48),
                      const SizedBox(height: 8),
                      Text(
                        item.label,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF171717),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

