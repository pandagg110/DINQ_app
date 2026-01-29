import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/card_models.dart';
import '../../stores/card_store.dart';
import '../../widgets/cards/factory/card_definition.dart';
import '../../widgets/cards/factory/definitions/index.dart'
    show generalCards, isAICard, socialCards;
import '../../widgets/common/asset_icon.dart';
import '../../utils/icon_mapping.dart' as icon_mapping;

/// Add 页：仅渲染卡片类型按钮（与 TSX CardListModal 内容一致），无弹框、无添加逻辑。
class AddPage extends StatelessWidget {
  const AddPage({super.key});

  /// Recommended：前 4 个 general + 前 4 个 social，按 type 去重。
  static List<CardDefinition> get recommendedCards {
    final combined = [
      ...generalCards.take(4),
      ...socialCards.take(4),
    ];
    final seen = <String>{};
    return combined.where((c) => seen.add(c.type.toUpperCase())).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Add',
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF171717),
            ),
          ),
          centerTitle: true,
          bottom: TabBar(
            labelColor: const Color(0xFF2563EB),
            unselectedLabelColor: const Color(0xFF6B7280),
            indicatorColor: const Color(0xFF2563EB),
            labelStyle: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            tabs: const [
              Tab(text: 'Recommended'),
              Tab(text: 'General'),
              Tab(text: 'Social Media'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _AddGrid(cards: recommendedCards),
            _AddGrid(cards: generalCards),
            _AddGrid(cards: socialCards),
          ],
        ),
      ),
    );
  }
}

class _AddGrid extends StatelessWidget {
  const _AddGrid({required this.cards});

  final List<CardDefinition> cards;

  bool _isCardDisabled(String type, List<CardItem> existingCards) {
    if (type != 'ACHIEVEMENT_NETWORK' && type != 'CAREER_TRAJECTORY') {
      return false;
    }
    return existingCards
        .any((c) => c.data.type.toUpperCase() == type.toUpperCase());
  }

  @override
  Widget build(BuildContext context) {
    final cardStore = context.watch<CardStore>();
    final existingCards = cardStore.cards;

    final padding = 24.0;
    const spacing = 16.0;
    const crossAxisCount = 2;
    final w = MediaQuery.sizeOf(context).width - padding * 2;
    final itemWidth = (w - spacing * (crossAxisCount - 1)) / crossAxisCount;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: cards.asMap().entries.map((e) {
          final def = e.value;
          final disabled = _isCardDisabled(def.type, existingCards);
          return SizedBox(
            width: itemWidth,
            child: AddCardBtn(
              definition: def,
              disabled: disabled,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class AddCardBtn extends StatelessWidget {
  const AddCardBtn({
    required this.definition,
    required this.disabled,
  });

  final CardDefinition definition;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Opacity(
          opacity: disabled ? 0.5 : 1,
          child: IgnorePointer(
            ignoring: disabled,
            child: Material(
              color: Colors.transparent,
              child: Ink(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    width: 1,
                    color: const Color(0x12303030),
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).pop(definition);
                  },
                  borderRadius: BorderRadius.circular(8),
                  splashColor: Colors.black.withOpacity(0.06),
                  highlightColor: Colors.black.withOpacity(0.04),
                  child: SizedBox(
                    height: 48,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      child: Row(
                        children: [
                          _buildIcon(),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              definition.name,
                              style: const TextStyle(
                                fontFamily: 'Geist',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF171717),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (isAICard(definition.type))
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              height: 14,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F6FF),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomLeft: Radius.circular(6),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 10,
                    color: Colors.blue.shade400,
                  ),
                  const SizedBox(width: 2),
                  const Text(
                    'AI',
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.normal,
                      height: 12 / 10,
                      letterSpacing: 0,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildIcon() {
    final icon = definition.icon;
    if (icon.startsWith('i-lucide-') || icon.startsWith('i-mdi:')) {
      return _iconDataFor(icon);
    }
    final asset = icon.startsWith('/') ? icon.substring(1) : icon;
    final pathFallback = _pathIconFallback[asset];
    if (pathFallback != null) {
      return _iconWidget(pathFallback);
    }
    String finalAsset = asset;
    if (asset.contains('icons/social-icons/')) {
      finalAsset = icon_mapping.mapSvgToPng(asset);
    }
    return _iconAsset(finalAsset);
  }

  static const double _iconSize = 32;

  Widget _iconWidget(IconData data) {
    return Container(
      width: _iconSize,
      height: _iconSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(data, size: 16, color: const Color(0xFF374151)),
    );
  }

  Widget _iconAsset(String finalAsset) {
    return Container(
      width: _iconSize,
      height: _iconSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AssetIcon(asset: finalAsset, size: 20),
      ),
    );
  }

  static const _pathIconFallback = <String, IconData>{
    'icons/markdown.svg': Icons.summarize_outlined,
    'icons/image.svg': Icons.image_outlined,
    'icons/note.svg': Icons.note_outlined,
  };

  Widget _iconDataFor(String iconClass) {
    IconData? data;
    if (iconClass.startsWith('i-lucide-')) {
      final name = iconClass.replaceFirst('i-lucide-', '');
      data = _lucideMap[name];
    } else if (iconClass.startsWith('i-mdi:')) {
      final name = iconClass.replaceFirst('i-mdi:', '').replaceAll('-', '_');
      data = _mdiMap[name];
    }
    if (data != null) {
      return _iconWidget(data);
    }
    return _iconWidget(Icons.extension);
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
