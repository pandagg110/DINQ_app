import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/card_models.dart';
import '../../stores/card_store.dart';
import '../cards/factory/card_registry.dart';
import '../cards/factory/card_definition.dart';

/// 卡片工具栏：尺寸切换、链接编辑等。viewMode 固定为 mobile，与 TS CardToolbar 对应。
class CardToolbar extends StatelessWidget {
  const CardToolbar({
    super.key,
    required this.card,
  });

  final CardItem card;

  /// 是否为“可链接”类型（显示链接按钮）
  static bool _isLinkable(String type) {
    return type.toUpperCase() == 'LINK' ||
        type.toUpperCase() == 'IMAGE' ||
        type.toUpperCase() == 'MARKDOWN';
  }

  @override
  Widget build(BuildContext context) {
    final cardStore = context.watch<CardStore>();
    final registry = CardRegistry();
    final definition = registry.getDefinition(card.data.type);
    if (definition == null) return const SizedBox.shrink();

    final sizeConfig = definition.sizes.mobile;
    final availableSizes = sizeConfig.supported;
    final currentSize = card.layout.mobile.size;
    final linkable = _isLinkable(card.data.type);

    final hasToolbar =
        availableSizes.length > 1 || linkable;

    if (!hasToolbar) return const SizedBox.shrink();

    final cardUIState = cardStore.cardStates[card.id];
    final isEditingLink = cardUIState?.isEditingLink ?? false;
    final linkUrl = (card.data.metadata['link'] ?? card.data.metadata['url'] ?? '').toString();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
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
                  definition: definition,
                  availableSizes: availableSizes,
                  currentSize: currentSize,
                  linkable: linkable,
                  isEditingLink: isEditingLink,
                  onToggleLink: () {
                    final state = cardStore.cardStates[card.id] ?? CardState();
                    cardStore.setCardState(
                      card.id,
                      state.copyWith(isEditingLink: !isEditingLink),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        if (linkable && isEditingLink)
          Positioned(
            left: 24,
            right: 24,
            bottom: 72,
            child: _LinkInputOverlay(
              initialValue: linkUrl,
              onSave: (value) {
                final idx = cardStore.cards.indexWhere((c) => c.id == card.id);
                if (idx < 0) return;
                final current = cardStore.cards[idx];
                final meta = Map<String, dynamic>.from(current.data.metadata);
                if (current.data.type.toUpperCase() == 'LINK') {
                  meta['url'] = value;
                } else {
                  meta['link'] = value;
                }
                cardStore.updateCardData(
                  card.id,
                  CardData(
                    id: current.data.id,
                    type: current.data.type,
                    title: current.data.title,
                    description: current.data.description,
                    metadata: meta,
                    status: current.data.status,
                  ),
                );
                final state = cardStore.cardStates[card.id] ?? CardState();
                cardStore.setCardState(card.id, state.copyWith(isEditingLink: false));
              },
              onClose: () {
                final state = cardStore.cardStates[card.id] ?? CardState();
                cardStore.setCardState(card.id, state.copyWith(isEditingLink: false));
              },
            ),
          ),
      ],
    );
  }

  Widget _buildToolbarContent(
    BuildContext context, {
    required CardStore cardStore,
    required CardDefinition definition,
    required List<String> availableSizes,
    required String currentSize,
    required bool linkable,
    required bool isEditingLink,
    required VoidCallback onToggleLink,
  }) {
    // 整体高度 36px（2+32+2），padding 2px，内部按钮 32x32，滑块动画参考 PreviewEditToggle
    const toolbarHeight = 36.0;
    const toolbarPadding = 2.0;
    const selectedButtonSize = 32.0;
    const iconSize = 16.0;
    const innerRadius = 6.0;

    final numSegments = (availableSizes.length > 1 ? availableSizes.length : 0) + (linkable ? 1 : 0);
    // 每段等宽，与滑块对齐：segmentWidth = 按钮宽 + 间距
    const segmentWidth = selectedButtonSize + toolbarPadding; // 34
    final totalWidth = numSegments == 0
        ? 0.0
        : toolbarPadding * 2 + numSegments * segmentWidth;

    int selectedIndex = 0;
    if (linkable && isEditingLink) {
      selectedIndex = availableSizes.length > 1 ? availableSizes.length : 0;
    } else if (availableSizes.length > 1) {
      final idx = availableSizes.indexOf(currentSize);
      selectedIndex = idx >= 0 ? idx : 0;
    }

    final sliderWidth = segmentWidth - toolbarPadding; // 32，与按钮同宽

    return Container(
      height: toolbarHeight,
      padding: const EdgeInsets.all(toolbarPadding),
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
      child: numSegments == 0
          ? const SizedBox.shrink()
          : SizedBox(
              width: totalWidth,
              child: Stack(
                children: [
                  // 滑块动画（与 PreviewEditToggle 一致）
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    left: toolbarPadding + selectedIndex * segmentWidth,
                    top: toolbarPadding,
                    bottom: toolbarPadding,
                    width: sliderWidth,
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
                  // 按钮层：每段等宽 segmentWidth，与滑块对齐
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: toolbarPadding),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (availableSizes.length > 1) ...[
                          ...availableSizes.map((size) {
                            final isActive = currentSize == size;
                            return SizedBox(
                              width: segmentWidth,
                              height: selectedButtonSize,
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
                          }),
                        ],
                        if (linkable)
                          SizedBox(
                            width: segmentWidth,
                            height: selectedButtonSize,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: onToggleLink,
                                borderRadius: BorderRadius.circular(innerRadius),
                                child: Center(
                                  child: Icon(
                                    Icons.link,
                                    size: iconSize,
                                    color: isEditingLink
                                        ? const Color(0xFF171717)
                                        : Colors.white.withOpacity(0.7),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
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

/// 链接输入浮层（类似 TS LinkInputToolbar）
class _LinkInputOverlay extends StatefulWidget {
  const _LinkInputOverlay({
    required this.initialValue,
    required this.onSave,
    required this.onClose,
  });

  final String initialValue;
  final void Function(String value) onSave;
  final VoidCallback onClose;

  @override
  State<_LinkInputOverlay> createState() => _LinkInputOverlayState();
}

class _LinkInputOverlayState extends State<_LinkInputOverlay> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Input URL',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
                style: const TextStyle(fontSize: 14),
                onSubmitted: (v) => widget.onSave(v.trim()),
              ),
            ),
            TextButton(
              onPressed: () => widget.onSave(_controller.text.trim()),
              child: const Text('Save'),
            ),
            TextButton(
              onPressed: widget.onClose,
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
