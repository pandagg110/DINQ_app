import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reorderable_staggered_grid_view/reorderable_staggered_grid_view.dart';
import '../../models/card_models.dart';
import '../../stores/card_store.dart';
import '../../stores/settings_store.dart';
import 'card_renderer.dart';

/// 使用 reorderable_staggered_grid_view 的卡片网格：按 layout.mobile 的 position/size 渲染，拖拽重排
class CardGridStaggered extends StatefulWidget {
  const CardGridStaggered({super.key, this.editable = false});

  final bool editable;

  /// 与数据一致：4 列时 2x2=半宽并排，4x4=全宽
  static const int gridColumns = 4;

  @override
  State<CardGridStaggered> createState() => _CardGridStaggeredState();
}

class _CardGridStaggeredState extends State<CardGridStaggered> {
  final Map<String, GlobalKey<State<StatefulWidget>>> _animationKeys = {};

  GlobalKey<State<StatefulWidget>> _keyFor(String cardId) {
    return _animationKeys.putIfAbsent(
      cardId,
      () => GlobalKey<State<StatefulWidget>>(),
    );
  }

  static ({int w, int h}) _sizeFromString(String size) {
    final parts = size.toLowerCase().split('x');
    if (parts.length != 2) return (w: 2, h: 2);
    final w = int.tryParse(parts[0].trim()) ?? 2;
    final h = int.tryParse(parts[1].trim()) ?? 2;
    return (w: w, h: h);
  }

  /// 按新顺序紧凑放置，得到每个卡片的 (x,y)；每行内靠右排布，左侧为空
  static List<CardPosition> _compactPositions(
    List<CardItem> ordered,
    int columns,
  ) {
    // 第一遍：确定每张卡所在行及 (w,h)，行内顺序不变
    final rowItems = <int, List<({int w, int h})>>{}; // y -> [(w,h), ...]
    int y = 0, rowHeight = 0, rowUsed = 0;
    final rowOrder = <int>[]; // 每行在 ordered 中的起始索引
    for (var i = 0; i < ordered.length; i++) {
      final card = ordered[i];
      final dims = _sizeFromString(card.layout.mobile.size);
      final w = dims.w.clamp(1, columns);
      final h = dims.h.clamp(1, 100);
      if (rowUsed + w > columns) {
        y += rowHeight;
        rowHeight = 0;
        rowUsed = 0;
      }
      rowItems.putIfAbsent(y, () => []).add((w: w, h: h));
      rowOrder.add(y);
      if (rowHeight < h) rowHeight = h;
      rowUsed += w;
    }
    // 第二遍：按行右对齐算 x
    final positions = <CardPosition>[];
    var cardIndex = 0;
    final rowKeys = rowItems.keys.toList()..sort();
    for (final rowY in rowKeys) {
      final items = rowItems[rowY]!;
      final rowWidth = items.fold<int>(0, (s, e) => s + e.w);
      int startX = columns - rowWidth; // 靠右：左侧留空
      for (final item in items) {
        final card = ordered[cardIndex];
        final dims = _sizeFromString(card.layout.mobile.size);
        final w = dims.w.clamp(1, columns);
        final h = dims.h.clamp(1, 100);
        positions.add(CardPosition(x: startX, y: rowY, w: w, h: h));
        startX += w;
        cardIndex++;
      }
    }
    return positions;
  }

  @override
  Widget build(BuildContext context) {
    final cardStore = context.watch<CardStore>();
    final settings = context.watch<SettingsStore>();
    final cards = cardStore.cards;

    final gridConfig = settings.gridConfig;
    final columns = CardGridStaggered.gridColumns;
    final spacing = gridConfig.mobileGap;

    if (!cardStore.isInitialized) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (cards.isEmpty) {
      return const SizedBox.shrink();
    }

    // 按数据中的 (y, x) 排序，与 JSON 的 position 一致
    final sortedCards = List<CardItem>.from(cards);
    sortedCards.sort((a, b) {
      final pa = a.layout.mobile.position;
      final pb = b.layout.mobile.position;
      if (pa.y != pb.y) return pa.y.compareTo(pb.y);
      return pa.x.compareTo(pb.x);
    });

    final items = <ReorderableStaggeredGridViewItem<CardItem>>[];
    for (final card in sortedCards) {
      final dims = _sizeFromString(card.layout.mobile.size);
      // w=列数(2 或 4)，h=行数；与数据 2x2 / 4x4 一致
      final crossCells = dims.w.clamp(1, columns);
      final mainCells = dims.h.clamp(1, 100);
      items.add(
        ReorderableStaggeredGridViewItem<CardItem>(
          data: card,
          animationKey: _keyFor(card.id),
          crossAxisCellCount: crossCells,
          mainAxisCellCount: mainCells,
          // proxyDecoratorBuilder: (child, index, animation) {
          //   return Container(
          //     color: Colors.transparent,
          //     child: child,
          //   );
          // },
          child: CardRenderer(card: card, editable: widget.editable),
          // child: Text(
          //   '${card.id}',
          //   style: TextStyle(backgroundColor: Colors.transparent),
          // ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: GestureDetector(
        onTap: () {
          if (cardStore.selectedCardIds.isNotEmpty) {
            cardStore.clearSelection();
          }
        },
        behavior: HitTestBehavior.translucent,
        child: ReorderableStaggeredGridView(
          key: ValueKey(
            cards
                .map(
                  (c) =>
                      '${c.id}_${c.layout.mobile.size}_${c.layout.mobile.position.x}_${c.layout.mobile.position.y}',
                )
                .join('|'),
          ),
          crossAxisCount: columns,
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          enable: widget.editable,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          items: items,

          onAcceptWithDetails: (details, newIndex) {
            final card = details.data as CardItem?;
            if (card == null) return;
            final currentCards = List<CardItem>.from(cardStore.cards);
            currentCards.sort((a, b) {
              final pa = a.layout.mobile.position;
              final pb = b.layout.mobile.position;
              if (pa.y != pb.y) return pa.y.compareTo(pb.y);
              return pa.x.compareTo(pb.x);
            });
            final oldIndex = currentCards.indexWhere((c) => c.id == card.id);
            if (oldIndex < 0) return;
            final reordered = List<CardItem>.from(currentCards);
            reordered.removeAt(oldIndex);
            final insertIndex = oldIndex < newIndex ? newIndex - 1 : newIndex;
            reordered.insert(insertIndex.clamp(0, reordered.length), card);

            // 按新顺序算出每个卡片的实际网格 (x,y,w,h)，全部写回 store 以触发保存
            final newPositions = _compactPositions(reordered, columns);
            for (var i = 0; i < reordered.length; i++) {
              final c = reordered[i];
              final pos = newPositions[i];
              final currentLayout = c.layout.mobile;
              final newLayout = CardLayout(
                desktop: c.layout.desktop,
                mobile: CardLayoutState(
                  size: currentLayout.size,
                  position: pos,
                ),
              );
              cardStore.updateCardLayout(c.id, newLayout);
            }
          },
        ),
      ),
    );
  }
}
