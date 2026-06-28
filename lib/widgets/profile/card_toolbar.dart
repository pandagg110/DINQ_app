import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/card_models.dart';
import '../../stores/card_store.dart';
import '../cards/factory/card_registry.dart';

/// 卡片编辑底栏：尺寸切换 + Done（取消选中）。
class CardToolbar extends StatelessWidget {
  const CardToolbar({
    super.key,
    required this.card,
  });

  final CardItem card;

  @override
  Widget build(BuildContext context) {
    final cardStore = context.watch<CardStore>();
    final registry = CardRegistry();
    final definition = registry.getDefinition(card.data.type);
    if (definition == null) return const SizedBox.shrink();

    final sizeConfig = definition.sizes.mobile;
    final availableSizes = sizeConfig.supported;
    final currentSize = card.layout.mobile.size;
    final showSizeOptions = availableSizes.length > 1;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Center(
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF171717),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showSizeOptions) ...[
                      _buildToolbarContent(
                        context,
                        cardStore: cardStore,
                        availableSizes: availableSizes,
                        currentSize: currentSize,
                      ),
                      const SizedBox(width: 16),
                      _buildDivider(),
                      const SizedBox(width: 16),
                    ],
                    _buildDoneButton(context, cardStore),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDoneButton(BuildContext context, CardStore cardStore) {
    return Material(
      color: const Color(0xFF1487FA),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: cardStore.clearSelection,
        borderRadius: BorderRadius.circular(8),
        splashColor: Colors.white.withOpacity(0.2),
        highlightColor: Colors.white.withOpacity(0.1),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Done',
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 16,
      color: Colors.white.withOpacity(0.15),
    );
  }

  Widget _buildToolbarContent(
    BuildContext context, {
    required CardStore cardStore,
    required List<String> availableSizes,
    required String currentSize,
  }) {
    // 每个按钮 32x32，最外层不设宽高
    const optionSize = 32.0;
    const iconSize = 16.0;
    const innerRadius = 6.0;

    final selectedIndex = availableSizes.indexOf(currentSize).clamp(0, availableSizes.length - 1);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 滑块：32x32
        AnimatedPositioned(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          left: selectedIndex * optionSize,
          top: 0,
          width: optionSize,
          height: optionSize,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(innerRadius),
            ),
          ),
        ),
        // 按钮层：每个 32x32
        Row(
          mainAxisSize: MainAxisSize.min,
          children: availableSizes.map((size) {
            final isActive = currentSize == size;
            return SizedBox(
              width: optionSize,
              height: optionSize,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    final currentLayout = card.layout.mobile;
                    final newLayout = CardLayout(
                      desktop: card.layout.desktop,
                      mobile: CardLayoutState(
                        size: size,
                        position: currentLayout.position,
                      ),
                    );
                    cardStore.updateCardLayout(card.id, newLayout);
                    cardStore.compactLayoutAfterSizeChange();
                  },
                  borderRadius: BorderRadius.circular(innerRadius),
                  child: Center(
                    child: _SizeIcon(
                      size: size,
                      active: isActive,
                      iconSize: iconSize,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// 尺寸图标：按 2x2 / 4x4 / 2x4 / 4x2 画小矩形
class _SizeIcon extends StatelessWidget {
  const _SizeIcon({required this.size, this.active = false, this.iconSize = 14});

  final String size;
  final bool active;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final parts = size.toLowerCase().split('x');
    final w = (parts.length >= 1 ? int.tryParse(parts[0].trim()) : null) ?? 2;
    final h = (parts.length >= 2 ? int.tryParse(parts[1].trim()) : null) ?? 2;
    final color = active ? const Color(0xFF171717) : Colors.white.withOpacity(0.7);
    return SizedBox(
      width: iconSize,
      height: iconSize,
      child: CustomPaint(
        painter: _SizeIconPainter(w: w, h: h, color: color),
      ),
    );
  }
}

class _SizeIconPainter extends CustomPainter {
  _SizeIconPainter({required this.w, required this.h, required this.color});

  final int w;
  final int h;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rectW = size.width * (w / 4).clamp(0.25, 1.0);
    final rectH = size.height * (h / 4).clamp(0.25, 1.0);
    final left = (size.width - rectW) / 2;
    final top = (size.height - rectH) / 2;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, rectW, rectH),
      const Radius.circular(1),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant _SizeIconPainter old) =>
      old.w != w || old.h != h || old.color != color;
}
