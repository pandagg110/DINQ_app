import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../grid-layout/grid_layout_state.dart';
import '../grid-layout/grid_layout_widget.dart';
import '../grid-layout/grid_layout_types.dart';
import '../../models/card_models.dart';
import '../../stores/card_store.dart';
import '../../stores/user_store.dart';
import '../../utils/card_layout_utils.dart';
import '../../utils/grid_layout_core.dart';
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
  GridLayoutState? _gridState;
  /// 拖拽过程中由 onMove 写入的布局，用于 PlaceholderGrid 计算 placeholderPositions；松手后清空
  List<LayoutItem>? _layoutDuringMove;

  /// [selectedIds] 编辑态下仅在此集合中的卡片可拖拽，未选中则 static_=true
  List<LayoutItem> _cardsToLayoutItems(
    List<CardItem> cards, {
    required Set<String> selectedIds,
    required bool editable,
  }) {
    return cards.map((c) {
      final pos = c.layout.mobile.position;
      final dims = CardLayoutUtils.parseSizeString(c.layout.mobile.size);
      final canDrag = editable && selectedIds.contains(c.id);
      return LayoutItem(
        i: c.id,
        x: pos.x,
        y: pos.y,
        w: dims.w.clamp(1, CardGridStaggered.gridColumns),
        h: dims.h.clamp(1, 100),
        static_: !canDrag,
      );
    }).toList();
  }

  void _syncLayoutToStore(List<LayoutItem> layout, CardStore cardStore) {
    final byId = {for (final item in layout) item.i: item};
    final changedLayouts = <String, CardLayout>{};
    for (final c in cardStore.cards) {
      final item = byId[c.id];
      if (item == null) continue;
      final oldPos = c.layout.mobile.position;
      if (oldPos.x == item.x && oldPos.y == item.y) continue;
      changedLayouts[c.id] = CardLayout(
        desktop: c.layout.desktop,
        mobile: CardLayoutState(
          size: c.layout.mobile.size,
          position: CardPosition(x: item.x, y: item.y, w: item.w, h: item.h),
        ),
      );
    }
    if (changedLayouts.isNotEmpty) {
      cardStore.updateCardLayouts(changedLayouts);
    }
  }

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
    final cards = cardStore.cards;
    final columns = CardGridStaggered.gridColumns;
    final updateCount = cardStore.updateCount;
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

    final gap = 12.0;
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
     final layoutOverrideForPlaceholders = _layoutDuringMove != null
        ? _layoutDuringMove!
            .map((e) => (x: e.x, y: e.y, w: e.w, h: e.h))
            .toList()
        : null;
    final placeholderPositions = showPlaceholders
        ? computePlaceholderPositions(
            cards: cards,
            cardsForLayout: filteredCards,
            columns: columns,
            editable: widget.editable,
            showPlaceholders: placeholderNotifier.showPlaceholders,
            hiddenPlaceholders: placeholderNotifier.hiddenPlaceholders,
            layoutOverride: layoutOverrideForPlaceholders,
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
    if (cards.isEmpty) {
      _gridState = null;
      if (!widget.editable) return const SizedBox.shrink();
      return LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          // 单格为正方形：格宽 = (宽度 - 间隙) / 列数，行高 = 格宽
          final contentSlotWidth = w > 0
              ? (w - (columns - 1) * gap) / columns
              : 80.0;
          final mainRowHeight = contentSlotWidth + gap;
          final totalGridHeight = maxGridY > 0
              ? maxGridY * contentSlotWidth + (maxGridY - 1) * gap
              : 120.0;
          return SizedBox(
            width: w,
            height: totalGridHeight,
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
      _gridState = null;
      if (!widget.editable) return const SizedBox.shrink();
      return LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final contentSlotWidth = w > 0
              ? (w - (columns - 1) * gap) / columns
              : 80.0;
          final mainRowHeight = contentSlotWidth + gap;
          final totalGridHeight = maxGridY > 0
              ? maxGridY * contentSlotWidth + (maxGridY - 1) * gap
              : 120.0;
          return SizedBox(
            width: w,
            height: totalGridHeight,
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

    final layoutItems = _cardsToLayoutItems(
      filteredCards,
      selectedIds: cardStore.selectedCardIds,
      editable: widget.editable,
    );
    // 选中卡片排在最后绘制，避免底部工具栏（bottom: -16）被下方卡片遮挡
    final selectedIds = cardStore.selectedCardIds;
    final layoutOrdered = [...layoutItems]
      ..sort((a, b) {
        final aSelected = selectedIds.contains(a.i);
        final bSelected = selectedIds.contains(b.i);
        if (aSelected && !bSelected) return 1;
        if (!aSelected && bSelected) return -1;
        if (aSelected && bSelected) {
          // y 较小的卡片（靠上）后绘制，底部 move 按钮可盖住下方卡片
          return b.y.compareTo(a.y);
        }
        return 0;
      });
    if (_gridState == null) {
      _gridState = GridLayoutState(
        layout: layoutOrdered,
        cols: columns,
        onMove: (newLayout) {
          setState(() {
            _layoutDuringMove = newLayout.map((e) => e.copyWith()).toList();
          });
        },
        onLayoutChange: (newLayout) {
          _syncLayoutToStore(newLayout, cardStore);
          if (_gridState?.dragState.activeDrag == null && _layoutDuringMove != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _layoutDuringMove = null);
            });
          }
        },
      );
    } else {
      _gridState!.setLayoutFromProps(layoutOrdered);
    }
    final cardById = {for (final c in filteredCards) c.id: c};

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        // 单格为正方形：行高 = 格宽，无需单独设置 rowHeight
        final contentSlotWidth = w > 0
            ? (w - (columns - 1) * gap) / columns
            : 80.0;
        final mainRowHeight = contentSlotWidth + gap;
        final totalGridHeight = maxGridY > 0
            ? maxGridY * contentSlotWidth + (maxGridY - 1) * gap
            : 0.0;
        final minHeight = placeholderPositions.isNotEmpty && totalGridHeight > 0
            ? totalGridHeight
            : 0.0;
        final params = GridLayoutParams(
          containerWidth: w,
          cols: columns,
          rowHeight: contentSlotWidth,
          marginX: gap,
          marginY: gap,
        );
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 0),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: ListenableBuilder(
              listenable: _gridState!,
              builder: (context, _) {
                final activeDrag = _gridState!.dragState.activeDrag;
                final dragSnapshot = activeDrag != null
                    ? GridDragSnapshot(
                        itemId: activeDrag.i,
                        x: activeDrag.x,
                        y: activeDrag.y,
                        w: activeDrag.w,
                        h: activeDrag.h,
                      )
                    : null;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // 占位符先绘制，卡片后绘制，避免选中卡片底部 move 按钮被占位符遮挡
                    if (placeholderPositions.isNotEmpty)
                      Positioned(
                        left: 0,
                        top: 0,
                        child: SizedBox(
                          width: w,
                          height: totalGridHeight > 0 ? totalGridHeight : null,
                          child: PlaceholderGrid(
                            width: w,
                            positions: placeholderPositions,
                            contentSlotWidth: contentSlotWidth,
                            mainRowHeight: mainRowHeight,
                            dragSnapshot: dragSnapshot,
                            onPlaceholderClick: (pos) =>
                                widget.onPlaceholderClick?.call(pos.config),
                            onPlaceholderDelete: (type) =>
                                placeholderNotifier.hidePlaceholder(type),
                          ),
                        ),
                      ),
                    GridLayoutWidget(
                      state: _gridState!,
                      params: params,
                      itemBuilder: (context, item) {
                        final card = cardById[item.i];
                        if (card == null) return const SizedBox.shrink();
                        final content = widget.editable
                            ? GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () =>
                                    cardStore.toggleCardSelection(card.id),
                                child: CardRenderer(
                                    card: card, editable: widget.editable),
                              )
                            : CardRenderer(
                                card: card, editable: widget.editable);
                        return content;
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
