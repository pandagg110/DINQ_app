import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/card_models.dart';
import '../../stores/card_store.dart';
import '../common/asset_icon.dart';
import '../common/edit_card_dialog.dart';
import 'factory/card_registry.dart';
import 'factory/card_definition.dart';
import 'package:flutter_portal/flutter_portal.dart';

class CardRenderer extends StatefulWidget {
  const CardRenderer({
    super.key,
    required this.card,
    this.editable = false,
    this.showBottomSizedBox = true,
  });

  final CardItem card;
  final bool editable;
  final bool? showBottomSizedBox;

  @override
  State<CardRenderer> createState() => _CardRendererState();
}

class _CardRendererState extends State<CardRenderer> {
  bool _isDrag = false;
  Timer? _dragEndTimer; // Tracks delayed drag reset after pointer release.

  @override
  void dispose() {
    _dragEndTimer?.cancel();
    super.dispose();
  }

  /// Resolve the URL to open when the card is tapped.
  String? _getJumpUrl() {
    switch (widget.card.data.type.toUpperCase()) {
      case 'IMAGE':
        return widget.card.data.metadata['link']?.toString();
      default:
        return widget.card.data.metadata['url']?.toString() ??
            widget.card.data.metadata['link']?.toString();
    }
  }

  /// 卡片内部自行处理点击（详情弹层等），外层不再参与手势竞争。
  bool _cardHandlesOwnTap(String type) {
    switch (type.toUpperCase()) {
      case 'LINKEDIN':
      case 'LINK':
        return true;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardStore = context.watch<CardStore>();
    final cardState = cardStore.cardStates[widget.card.id];
    // Only show loading when cardState explicitly marks the card as loading.
    final isLoading = cardState?.loading ?? false;
    // Cards created from placeholders can be PROCESSING before their metadata
    // has been generated. Do not render concrete card layouts until ready.
    final isProcessing = widget.card.data.status == 'PROCESSING';
    final showLoading = isLoading || isProcessing;
    final isFailed = !showLoading && widget.card.data.status == 'FAILED';
    final viewMode = cardStore.viewMode;
    final jumpUrl = _getJumpUrl();
    final VoidCallback? cardTapHandler;
    if (widget.editable) {
      cardTapHandler = () => cardStore.toggleCardSelection(widget.card.id);
    } else if (!_cardHandlesOwnTap(widget.card.data.type)) {
      cardTapHandler = () {
        if (jumpUrl != null && jumpUrl.isNotEmpty) {
          launchUrl(Uri.parse(jumpUrl), mode: LaunchMode.externalApplication);
        }
      };
    } else {
      cardTapHandler = null;
    }

    // Check card selection.
    final isSelected =
        widget.editable && cardStore.isCardSelected(widget.card.id);

    final borderColor = isSelected
        ? const Color(0xFF3B82F6)
        : const Color(0xFFE5E7EB);
    final borderWidth = isSelected ? 2.0 : 1.0;

    // Card content. Border is rendered by a separate Positioned layer.
    final cardContent = Container(
      width: double.infinity,
      height: widget.card.data.type.toUpperCase() == 'TITLE' ? 100 : null,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? const Color(0xFF3B82F6).withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: isSelected ? 8 : 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (!showLoading && !isFailed)
            Positioned.fill(
              child: _buildContent(context, viewMode, isSelected),
            ),

          if (showLoading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Analyzing with AI...',
                        style: TextStyle(color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (isFailed)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Oops!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF171717),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'The card didn\'t go through...',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        if (widget.editable) ...[
                          const SizedBox(height: 16),
                          Center(
                            child: ElevatedButton(
                              onPressed: () {
                                cardStore.regenerateCard(
                                  cardId: widget.card.id,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF171717),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                              ),
                              child: const Text(
                                'Try Again',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Render border as a separate layer without intercepting taps.
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderColor, width: borderWidth),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return Listener(
      onPointerUp: (event) {
        _dragEndTimer?.cancel();

        // Delay reset to avoid brief pointer-up events during drag.
        _dragEndTimer = Timer(const Duration(milliseconds: 400), () {
          if (mounted) {
            setState(() {
              _isDrag = false;
            });
          }
        });
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Card body.
          Column(
            mainAxisSize: widget.card.data.type.toUpperCase() == 'TITLE'
                ? MainAxisSize.min
                : MainAxisSize.max,
            children: [
              // TITLE uses Expanded to keep the 4x1 cell from overflowing.
              widget.card.data.type.toUpperCase() == 'TITLE'
                  ? Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTapUp: (details) {
                            setState(() {
                              _isDrag = false;
                            });
                          },
                          onTap: cardTapHandler,
                          child: cardContent,
                        ),
                      ),
                    )
                  : Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTapUp: (details) {
                            setState(() {
                              _isDrag = false;
                            });
                          },
                          onTap: cardTapHandler,
                          child: cardContent,
                        ),
                      ),
                    ),
              // if (widget.showBottomSizedBox ?? true) const SizedBox(height: 24),
            ],
          ),

          // Edit controls live outside ClipRRect so they are not clipped.
          if (widget.editable && isSelected) ...[
            if (!_isDrag) ...[
              Positioned(
                top: 10,
                left: 10,
                child: _buildEditButton(
                  context: context,
                  isPortal:
                      context.findAncestorWidgetOfExactType<Portal>() != null,
                  onTap: () {
                    cardStore.removeCard(widget.card.id);
                  },
                  asset: 'assets/profile/delete-card-btn.png',
                  width: 55,
                  height: 55,
                ),
              ),
              EditCardDialog.supports(widget.card.data.type)
                  ? Positioned(
                      top: 10,
                      right: 10,
                      child: _buildEditButton(
                        context: context,
                        isPortal:
                            context.findAncestorWidgetOfExactType<Portal>() !=
                            null,
                        onTap: () {
                          if (EditCardDialog.supports(widget.card.data.type)) {
                            EditCardDialog.show(
                              context: context,
                              card: widget.card,
                            );
                          }
                        },
                        asset: 'assets/icons/edit.png',
                      ),
                    )
                  : const SizedBox.shrink(),
            ],

            // 移动按钮骑在选中卡片自己的底边框上，不压下方卡片的边框
            Positioned(
              left: 0,
              right: 0,
              bottom: -16,
              child: Center(
                child: _buildCardToolbar(context, cardStore, viewMode),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEditButton({
    required BuildContext context,
    required bool isPortal,
    required VoidCallback onTap,
    required String asset,
    double? width,
    double? height,
  }) {
    final button = Material(
      color: Colors.transparent,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Image.asset(
          asset,
          width: width ?? 40,
          height: height ?? 40,
          fit: BoxFit.contain,
        ),
      ),
    );
    if (isPortal) {
      return PortalTarget(
        visible: true,
        portalFollower: Transform.translate(
          offset: const Offset(0, 0),
          child: button,
        ),
        anchor: const Aligned(
          follower: Alignment.center,
          target: Alignment.center,
        ),
        child: const SizedBox(width: 1, height: 1),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildCardToolbar(
    BuildContext context,
    CardStore cardStore,
    ViewMode viewMode,
  ) {
    final registry = CardRegistry();
    final definition = registry.getDefinition(widget.card.data.type);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Toolbar buttons can be extended here.
        if (definition != null)
          GestureDetector(
            behavior: HitTestBehavior.deferToChild,
            onTapDown: (details) {
              _dragEndTimer?.cancel();
              setState(() {
                _isDrag = true;
              });
            },
            onTapUp: (details) {
              setState(() {
                _isDrag = false;
              });
            },
            child: Image.asset(
              'assets/icons/move.png',
              width: 40,
              height: 40,
              fit: BoxFit.contain,
            ),
          ),
      ],
    );
  }

  Widget _buildContent(
    BuildContext context,
    ViewMode viewMode,
    bool isSelected,
  ) {
    final type = widget.card.data.type.toUpperCase();
    final size = widget.card.layout.mobile.size;
    return _buildCardByType(
      type,
      size,
      viewMode,
      isSelected && !_isDrag,
      context,
    );
  }

  Widget _buildCardByType(
    String type,
    String size,
    ViewMode viewMode,
    bool isSelected,
    BuildContext context,
  ) {
    final registry = CardRegistry();
    final cardStore = context.read<CardStore>();

    if (type == 'DATASOURCE' || type == 'datasource') {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading...', style: TextStyle(color: Color(0xFF6B7280))),
          ],
        ),
      );
    }

    // Resolve the card definition from the registry.
    final definition = registry.getDefinition(type);
    if (definition != null) {
      try {
        return definition.render(
          CardRenderParams(
            card: widget.card,
            size: size,
            editable: widget.editable,
            isSelected: isSelected,
            onUpdate: (data) {
              // Update card data.
              final updatedData = CardData(
                id: widget.card.data.id,
                type: widget.card.data.type,
                title: widget.card.data.title,
                description: widget.card.data.description,
                metadata: data,
                status: widget.card.data.status,
              );
              cardStore.updateCardData(widget.card.id, updatedData);
            },
          ),
        );
      } catch (error) {
        return _buildRenderErrorCard();
      }
    }

    return _buildDefaultCard();
  }

  Widget _buildRenderErrorCard() {
    return Container(
      color: Colors.white,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Oops!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF171717),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'The card is missing data.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkCard() {
    final title = widget.card.data.metadata['title']?.toString() ?? 'Link';
    final url = widget.card.data.metadata['url']?.toString() ?? '';
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AssetIcon(asset: 'icons/link-image.svg', size: 32),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            url,
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultCard() {
    final displayTitle =
        widget.card.data.metadata['title']?.toString() ??
        widget.card.data.title;
    final displayDescription =
        widget.card.data.metadata['description']?.toString() ??
        widget.card.data.description;

    // Show link fallback when metadata only has a URL.
    final url = widget.card.data.metadata['url']?.toString() ?? '';
    if (url.isNotEmpty && displayTitle.isEmpty) {
      return _buildLinkCard();
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (displayTitle.isNotEmpty)
            Text(
              displayTitle,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          if (displayDescription.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              displayDescription,
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
            ),
          ],
          if (displayTitle.isEmpty && displayDescription.isEmpty) ...[
            Text(
              widget.card.data.type,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              widget.card.data.metadata.isEmpty
                  ? 'No content available'
                  : 'Type: ${widget.card.data.type}',
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
