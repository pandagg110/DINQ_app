import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reorderable_staggered_scroll_view/reorderable_staggered_scroll_view.dart';
import '../../models/card_models.dart';
import '../../stores/card_store.dart';
import '../../stores/settings_store.dart';
import 'card_renderer.dart';

/// 使用 reorderable_staggered_scroll_view 的卡片网格：按 layout.mobile 的 position/size 渲染，拖拽重排
class CardGridStaggered extends StatefulWidget {
  const CardGridStaggered({super.key, this.editable = false});

  final bool editable;

  /// 与数据一致：4 列时 2x2=半宽并排，4x4=全宽
  static const int gridColumns = 4;

  @override
  State<CardGridStaggered> createState() => _CardGridStaggeredState();
}

class _CardGridStaggeredState extends State<CardGridStaggered> {
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
    final rowItems = <int, List<({int w, int h})>>{};
    int y = 0, rowHeight = 0, rowUsed = 0;
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
      if (rowHeight < h) rowHeight = h;
      rowUsed += w;
    }
    final positions = <CardPosition>[];
    var cardIndex = 0;
    final rowKeys = rowItems.keys.toList()..sort();
    for (final rowY in rowKeys) {
      final items = rowItems[rowY]!;
      final rowWidth = items.fold<int>(0, (s, e) => s + e.w);
      int startX = columns - rowWidth;
      for (final _ in items) {
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

  static String? _keyToCardId(Key key) {
    if (key is ValueKey<Object?>) return key.value?.toString();
    return null;
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

    // 包不支持按 (x,y) 定位，只按「列表顺序 + 每项占格数」排布。用 (y,x) 排序使顺序=左上到右下的格子顺序，等价于用 xy 布局
    final sortedCards = List<CardItem>.from(cards);
    sortedCards.sort((a, b) {
      final pa = a.layout.mobile.position;
      final pb = b.layout.mobile.position;
      if (pa.y != pb.y) return pa.y.compareTo(pb.y);
      return pa.x.compareTo(pb.x);
    });

    // 包内 StaggeredGrid 无 mainAxisSpacing/crossAxisSpacing，用 Padding 包每个 item 实现 gap
    final halfGap = spacing / 2;
    final gridItems = <ReorderableStaggeredScrollViewGridItem>[];
    for (final card in sortedCards) {
      final dims = _sizeFromString(card.layout.mobile.size);
      final crossCells = dims.w.clamp(1, columns);
      final mainCells = dims.h.clamp(1, 100);
      gridItems.add(
        ReorderableStaggeredScrollViewGridCountItem(
          key: ValueKey(card.id),
          mainAxisCellCount: mainCells,
          crossAxisCellCount: crossCells,
          widget: Padding(
            padding: EdgeInsets.only(
              left: halfGap,
              top: halfGap,
              right: halfGap,
              bottom: halfGap,
            ),
            child: widget.editable
                ? GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => cardStore.toggleCardSelection(card.id),
                    child: CardRenderer(card: card, editable: widget.editable),
                  )
                : CardRenderer(card: card, editable: widget.editable),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ReorderableStaggeredScrollView.grid(
        key: ValueKey(
          cards
              .map(
                (c) =>
                    '${c.id}_${c.layout.mobile.size}_${c.layout.mobile.position.x}_${c.layout.mobile.position.y}_${widget.editable}',
              )
              .join('|'),
        ),
        enable: widget.editable,
        crossAxisCount: columns,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.all(halfGap),
        isLongPressDraggable: true,
        children: gridItems,
        onAccept: (draggedItem, targetItem, _) {
          if (draggedItem == null) return;
          final draggedId = _keyToCardId(draggedItem.key);
          final targetId = _keyToCardId(targetItem.key);
          if (draggedId == null || targetId == null) return;
          final currentCards = List<CardItem>.from(cardStore.cards);
          currentCards.sort((a, b) {
            final pa = a.layout.mobile.position;
            final pb = b.layout.mobile.position;
            if (pa.y != pb.y) return pa.y.compareTo(pb.y);
            return pa.x.compareTo(pb.x);
          });
          final oldIndex = currentCards.indexWhere((c) => c.id == draggedId);
          final targetIndex = currentCards.indexWhere((c) => c.id == targetId);
          if (oldIndex < 0 || targetIndex < 0) return;
          final draggedCard = currentCards[oldIndex];
          final reordered = List<CardItem>.from(currentCards);
          reordered.removeAt(oldIndex);
          final insertIndex = oldIndex < targetIndex
              ? targetIndex - 1
              : targetIndex;
          reordered.insert(insertIndex.clamp(0, reordered.length), draggedCard);
          final newPositions = _compactPositions(reordered, columns);
          for (var i = 0; i < reordered.length; i++) {
            final c = reordered[i];
            final pos = newPositions[i];
            final currentLayout = c.layout.mobile;
            final newLayout = CardLayout(
              desktop: c.layout.desktop,
              mobile: CardLayoutState(size: currentLayout.size, position: pos),
            );
            debugPrint('newLayout: ${newLayout.toJson().toString()}');
            cardStore.updateCardLayout(c.id, newLayout);
          }
        },
      ),
    );
  }
}
