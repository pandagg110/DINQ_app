import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../reorderable_staggered_scroll_view/reorderable_staggered_scroll_view.dart';
import '../../models/card_models.dart';
import '../../stores/card_store.dart';
import '../../stores/settings_store.dart';
import '../../stores/user_store.dart';
import '../../utils/card_layout_utils.dart';
import 'card_renderer.dart';
import 'placeholder/placeholder_config.dart';
import 'placeholder/placeholder_grid.dart';
import 'placeholder/use_placeholders.dart';

/// 使用 reorderable_staggered_scroll_view 的卡片网格：按 layout.mobile 的 position/size 渲染，拖拽重排
class CardGridStaggered extends StatefulWidget {
  const CardGridStaggered({
    super.key,
    this.editable = false,
    this.onPlaceholderClick,
    /// 显式传入时使用该 store 并监听其更新（用于看他人 profile 时注入 ViewerCardStore，确保 loading 完成后能正确刷新）
    this.cardStore,
  });

  final bool editable;

  /// 点击占位卡片时回调；不传则不显示占位符或点击无效果
  final void Function(PlaceholderCardConfig config)? onPlaceholderClick;

  final CardStore? cardStore;

  /// 与数据一致：4 列时 2x2=半宽并排，4x4=全宽
  static const int gridColumns = 4;

  @override
  State<CardGridStaggered> createState() => _CardGridStaggeredState();
}

class _CardGridStaggeredState extends State<CardGridStaggered> {
  @override
  Widget build(BuildContext context) {
    if (widget.cardStore != null) {
      return ListenableBuilder(
        listenable: widget.cardStore!,
        builder: (context, _) => _buildContent(context, widget.cardStore!),
      );
    }
    final cardStore = context.watch<CardStore>();
    return _buildContent(context, cardStore);
  }

  Widget _buildContent(BuildContext context, CardStore cardStore) {
    final placeholderNotifier = context.watch<PlaceholderNotifier>();
    final userStore = context.watch<UserStore>();
    final settings = context.watch<SettingsStore>();
    final cards = cardStore.cards;
    final columns = CardGridStaggered.gridColumns;
    final updateCount = cardStore.updateCount;
    debugPrint('updateCountupdateCount: ${updateCount}');
    final userId = userStore.user?.user.id;

    if (!cardStore.isInitialized) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // 同步占位符状态：userId、是否展示占位符
    WidgetsBinding.instance.addPostFrameCallback((_) {
      placeholderNotifier.setUserId(userId);
      placeholderNotifier.updateActivation(
        editable: widget.editable,
        isInitialized: cardStore.isInitialized,
        cardsLength: cards.length,
        userId: userId,
      );
    });

    final gridConfig = settings.gridConfig;
    final gap = gridConfig.mobileGap;
    final unitSize = gridConfig.mobileUnitSize;
    // 与网格显示一致：仅用实际参与排布的卡片（allowedSizes）计算占位布局，改尺寸后占位会重排
    const allowedSizes = {'2x2', '2x4', '4x2', '4x4', '4x1'};
    final filteredCards = cards.where((c) {
      final size = c.layout.mobile.size.toLowerCase().trim();
      return allowedSizes.contains(size);
    }).toList();
    final showPlaceholders =
        widget.editable &&
        widget.onPlaceholderClick != null &&
        placeholderNotifier.showPlaceholders;
    final placeholderPositions = showPlaceholders
        ? computePlaceholderPositions(
            cards: cards,
            cardsForLayout: filteredCards,
            columns: columns,
            editable: widget.editable,
            showPlaceholders: placeholderNotifier.showPlaceholders,
            hiddenPlaceholders: placeholderNotifier.hiddenPlaceholders,
          )
        : <PlaceholderPosition>[];
    int maxGridY = 0;
    for (final c in filteredCards) {
      final pos = c.layout.mobile.position;
      final dims = CardLayoutUtils.parseSizeString(c.layout.mobile.size);
      final endY = pos.y + dims.h.clamp(1, 100);
      if (endY > maxGridY) maxGridY = endY;
    }
    for (final p in placeholderPositions) {
      final endY = p.y + p.config.size.h;
      if (endY > maxGridY) maxGridY = endY;
    }
    // 与 TSX 一致：totalGridHeight = totalMaxY * unitSize + (totalMaxY - 1) * gap（行间有 gap，最后一行下无 gap）
    final mainRowHeight = unitSize + gap;
    final totalGridHeight = maxGridY > 0
        ? maxGridY * unitSize + (maxGridY - 1) * gap
        : 0.0;
    if (cards.isEmpty) {
      if (!widget.editable) return const SizedBox.shrink();
      return LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final contentSlotWidth = w > 0
              ? (w - (columns - 1) * gap) / columns
              : unitSize;
          return SizedBox(
            width: w,
            height: totalGridHeight > 0 ? totalGridHeight : 120,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (placeholderPositions.isNotEmpty)
                  PlaceholderGrid(
                    key: ValueKey(
                      '${updateCount}_${placeholderPositions.map((p) => '${p.config.type}_${p.x}_${p.y}').join(',')}',
                    ),
                    width: w,
                    positions: placeholderPositions,
                    contentSlotWidth: contentSlotWidth,
                    mainRowHeight: mainRowHeight,
                    onPlaceholderClick: (pos) =>
                        widget.onPlaceholderClick?.call(pos.config),
                    onPlaceholderDelete: (type) =>
                        placeholderNotifier.hidePlaceholder(type),
                  ),
              ],
            ),
          );
        },
      );
    }

    if (filteredCards.isEmpty) {
      if (!widget.editable) return const SizedBox.shrink();
      return LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final contentSlotWidth = w > 0
              ? (w - (columns - 1) * gap) / columns
              : unitSize;
          return SizedBox(
            width: w,
            height: totalGridHeight > 0 ? totalGridHeight : 120,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (placeholderPositions.isNotEmpty)
                  PlaceholderGrid(
                    key: ValueKey(
                      '${updateCount}_${placeholderPositions.map((p) => '${p.config.type}_${p.x}_${p.y}').join(',')}',
                    ),
                    width: w,
                    positions: placeholderPositions,
                    contentSlotWidth: contentSlotWidth,
                    mainRowHeight: mainRowHeight,
                    onPlaceholderClick: (pos) =>
                        widget.onPlaceholderClick?.call(pos.config),
                    onPlaceholderDelete: (type) =>
                        placeholderNotifier.hidePlaceholder(type),
                  ),
              ],
            ),
          );
        },
      );
    }

    // 包不支持按 (x,y) 定位，只按「列表顺序 + 每项占格数」排布。用 (y,x) 排序使顺序=左上到右下的格子顺序，等价于用 xy 布局
    final sortedCards = List<CardItem>.from(filteredCards);
    sortedCards.sort((a, b) {
      final pa = a.layout.mobile.position;
      final pb = b.layout.mobile.position;
      if (pa.y != pb.y) return pa.y.compareTo(pb.y);
      return pa.x.compareTo(pb.x);
    });

    // 包内 StaggeredGrid 无 mainAxisSpacing/crossAxisSpacing，用 Padding 包每个 item 实现 gap
    final halfGap = gap / 2;
    final gridItems = <ReorderableStaggeredScrollViewGridItem>[];
    for (final card in sortedCards) {
      final dims = CardLayoutUtils.parseSizeString(card.layout.mobile.size);
      final crossCells = dims.w.clamp(1, columns);
      final mainCells = dims.h.clamp(1, 100);
      gridItems.add(
        ReorderableStaggeredScrollViewGridCountItem(
          key: ValueKey(card.id),
          mainAxisCellCount: mainCells,
          crossAxisCellCount: crossCells,
          data: card,
          widget: Padding(
            padding: EdgeInsets.only(
              left: halfGap,
              top: 0,
              right: halfGap,
              bottom: 0,
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;

        final contentSlotWidth = w > 0
            ? (w - (columns - 1) * gap) / columns
            : unitSize;
        final minHeight = placeholderPositions.isNotEmpty && totalGridHeight > 0
            ? totalGridHeight
            : 0.0;

        final updateLayout = (orderedDataList) {
          final orderedCards = <CardItem>[];
          for (final elem in orderedDataList) {
            if (elem.data is CardItem) {
              orderedCards.add(elem.data as CardItem);
            }
          }
          if (orderedCards.isEmpty) return;
          final newPositions = CardLayoutUtils.compactPositions(
            orderedCards,
            columns,
          );
          // 收集位置有变化的卡片，批量更新
          final changedLayouts = <String, CardLayout>{};
          for (var i = 0; i < orderedCards.length; i++) {
            final c = orderedCards[i];
            final pos = newPositions[i];
            final oldPos = c.layout.mobile.position;
            // 位置无变化则跳过
            if (oldPos.x == pos.x && oldPos.y == pos.y) continue;
            final currentLayout = c.layout.mobile;
            changedLayouts[c.id] = CardLayout(
              desktop: c.layout.desktop,
              mobile: CardLayoutState(size: currentLayout.size, position: pos),
            );
          }
          cardStore.updateCardLayouts(changedLayouts);
        };
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 0),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ReorderableStaggeredScrollView.grid(
                  key: ValueKey(
                    cards
                        .map(
                          (c) =>
                              '${c.id}_${c.layout.mobile.size}_${widget.editable}_${c.data.status}_${updateCount}',
                        )
                        .join('|'),
                  ),
                  enable: widget.editable,
                  crossAxisCount: columns,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.all(0),
                  isLongPressDraggable: true,
                  children: gridItems,
                  onCompleted: (orderedDataList) {
                    updateLayout(orderedDataList);
                  },
                  onDragEnd: (details, item, orderedDataList) {
                    // 根据 orderedDataList 的顺序和每张 card 的 size，计算 x,y 并更新布局
                    updateLayout(orderedDataList);
                  },
                  onAccept: (draggedItem, targetItem, isFront) {
                    // 由 onDragEnd 根据 orderedDataList 统一计算并更新布局
                  },
                ),
                if (placeholderPositions.isNotEmpty)
                  Positioned(
                    left: 0,
                    top: 0,
                    child: SizedBox(
                      width: w,
                      height: totalGridHeight > 0 ? totalGridHeight : null,
                      child: PlaceholderGrid(
                        // key: ValueKey(
                        //   cards
                        //       .map(
                        //         (c) =>
                        //             '${c.id}_${c.layout.mobile.size}_${c.layout.mobile.position.x}_${c.layout.mobile.position.y}_${widget.editable}_${c.data.status}_${updateCount}',
                        //       )
                        //       .join('|'),
                        // ),
                        width: w,
                        positions: placeholderPositions,
                        contentSlotWidth: contentSlotWidth,
                        mainRowHeight: mainRowHeight,
                        onPlaceholderClick: (pos) =>
                            widget.onPlaceholderClick?.call(pos.config),
                        onPlaceholderDelete: (type) =>
                            placeholderNotifier.hidePlaceholder(type),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
