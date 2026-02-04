import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/card_models.dart';
import '../../stores/card_store.dart';
import '../cards/factory/card_registry.dart';

/// 卡片工具栏：仅支持尺寸切换功能。viewMode 固定为 mobile，与 TS CardToolbar 对应。
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

    // 只有多个尺寸选项时才显示工具栏
    if (availableSizes.length <= 1) return const SizedBox.shrink();

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Center(
            child: _buildToolbarContent(
              context,
              cardStore: cardStore,
              availableSizes: availableSizes,
              currentSize: currentSize,
            ),
          ),
        ),
      ),
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
    const padding = 2.0;

    final selectedIndex = availableSizes.indexOf(currentSize).clamp(0, availableSizes.length - 1);

    return Container(
      padding: const EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: const Color(0xFF171717).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
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
      ),
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
