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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF171717).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (availableSizes.length > 1) ...[
            ...availableSizes.map((size) {
              final isActive = currentSize == size;
              return Padding(
                padding: const EdgeInsets.only(right: 4),
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
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isActive ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: _SizeIcon(size: size, active: isActive),
                    ),
                  ),
                ),
              );
            }),
            if (linkable) const SizedBox(width: 8),
          ],
          if (linkable)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onToggleLink,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isEditingLink ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.link,
                    size: 14,
                    color: isEditingLink
                        ? const Color(0xFF171717)
                        : Colors.white.withOpacity(0.7),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 尺寸图标：按 2x2 / 4x4 / 2x4 / 4x2 画小矩形
class _SizeIcon extends StatelessWidget {
  const _SizeIcon({required this.size, this.active = false});

  final String size;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final parts = size.toLowerCase().split('x');
    final w = (parts.length >= 1 ? int.tryParse(parts[0].trim()) : null) ?? 2;
    final h = (parts.length >= 2 ? int.tryParse(parts[1].trim()) : null) ?? 2;
    final color = active ? const Color(0xFF171717) : Colors.white.withOpacity(0.7);
    return SizedBox(
      width: 14,
      height: 14,
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
