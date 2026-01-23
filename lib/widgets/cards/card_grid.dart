import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reorderable_grid/reorderable_grid.dart';
import '../../models/card_models.dart';
import '../../stores/card_store.dart';
import '../../stores/settings_store.dart';
import 'card_renderer.dart';

class CardGrid extends StatelessWidget {
  const CardGrid({super.key, this.editable = false});

  final bool editable;

  /// 从 size 字符串（如 "2x4"）解析出宽度和高度
  Map<String, int> _getCardDimensions(String size) {
    final parts = size.toLowerCase().split('x');
    if (parts.length != 2) {
      return {'w': 2, 'h': 2}; // 默认尺寸
    }
    final w = int.tryParse(parts[0]) ?? 2;
    final h = int.tryParse(parts[1]) ?? 2;
    return {'w': w, 'h': h};
  }

  /// 压缩布局：按输入顺序从上到下、从左到右填充
  List<CardPosition> _compactLayout(
    List<CardItem> cards,
    int columns,
    bool isMobile,
  ) {
    final grid = <int, Map<int, bool>>{};
    int minY = 0;
    const maxY = 10000;
    final result = <CardPosition>[];

    // 检查位置是否可用
    bool canPlace(int x, int y, int w, int h) {
      for (int dy = 0; dy < h; dy++) {
        final row = grid[y + dy];
        if (row != null) {
          for (int dx = 0; dx < w; dx++) {
            if (row[x + dx] == true) return false;
          }
        }
      }
      return true;
    }

    // 标记占用区域
    void markOccupied(int x, int y, int w, int h) {
      for (int dy = 0; dy < h; dy++) {
        grid.putIfAbsent(y + dy, () => {});
        for (int dx = 0; dx < w; dx++) {
          grid[y + dy]![x + dx] = true;
        }
      }
    }

    // 按输入顺序逐个放置
    for (final card in cards) {
      final layout = isMobile ? card.layout.mobile : card.layout.desktop;
      final dimensions = _getCardDimensions(layout.size);
      final w = dimensions['w']!;
      final h = dimensions['h']!;
      final isTitle = card.data.type.toUpperCase() == 'TITLE';

      // 安全检查
      if (w > columns) {
        debugPrint('[compactLayout] Card ${card.id} width ($w) exceeds columns ($columns)! Skipping.');
        continue;
      }

      bool placed = false;

      // 从 minY 开始搜索
      for (int y = minY; !placed && y < maxY; y++) {
        for (int x = 0; x <= columns - w; x++) {
          if (canPlace(x, y, w, h)) {
            markOccupied(x, y, w, h);
            result.add(CardPosition(x: x, y: y, w: w, h: h));

            // 如果是 TITLE，更新 minY
            if (isTitle) {
              minY = y + h;
            }

            placed = true;
            break;
          }
        }
      }

      if (!placed) {
        debugPrint('[compactLayout] Failed to place card ${card.id} after $maxY attempts!');
      }
    }

    return result;
  }

  /// 处理布局变化 - 参考 React 版本的 handleLayoutChange
  void _handleLayoutChange(
    BuildContext context,
    CardStore cardStore,
    SettingsStore settings,
    List<CardItem> cards,
    ViewMode viewMode,
    List<int> newOrder,
  ) {
    if (!editable) return;

    final isMobile = false;
    bool hasChanged = false;

    // 更新当前视图模式的布局位置（y 坐标）
    for (int i = 0; i < newOrder.length && i < cards.length; i++) {
      final cardIndex = newOrder[i];
      if (cardIndex < 0 || cardIndex >= cards.length) continue;

      final card = cards[cardIndex];
      final currentLayout = isMobile ? card.layout.mobile : card.layout.desktop;
      final newY = i;

      // 如果位置没有变化，跳过
      if (currentLayout.position.y == newY) continue;

      final newPosition = CardPosition(
        x: currentLayout.position.x,
        y: newY,
        w: currentLayout.position.w,
        h: currentLayout.position.h,
      );

      final newLayoutState = CardLayoutState(
        size: currentLayout.size,
        position: newPosition,
      );

      final newLayout = CardLayout(
        desktop: isMobile ? card.layout.desktop : newLayoutState,
        mobile: isMobile ? newLayoutState : card.layout.mobile,
      );
      debugPrint('newLayout: $newLayout');
      cardStore.updateCardLayout(card.id, newLayout);
      hasChanged = true;
    }

    // 如果是 Desktop 模式，自动更新 Mobile 布局（压缩布局）
    if (!isMobile && hasChanged) {
      // 按 Desktop 布局排序
      final desktopSortedCards = List<CardItem>.from(cards);
      desktopSortedCards.sort((a, b) {
        final layoutA = a.layout.desktop;
        final layoutB = b.layout.desktop;
        if (layoutA.position.y != layoutB.position.y) {
          return layoutA.position.y.compareTo(layoutB.position.y);
        }
        return layoutA.position.x.compareTo(layoutB.position.x);
      });

      // 获取 Mobile 列数
      final mobileColumns = settings.gridConfig.mobileColumns;

      // 使用压缩布局
      final compactedPositions = _compactLayout(
        desktopSortedCards,
        mobileColumns,
        true, // isMobile
      );

      // 更新 Mobile 布局
      for (int i = 0; i < desktopSortedCards.length && i < compactedPositions.length; i++) {
        final card = desktopSortedCards[i];
        final newPos = compactedPositions[i];
        final oldPos = card.layout.mobile.position;

        // 只有位置变化时才更新
        if (oldPos.x != newPos.x || oldPos.y != newPos.y) {
          final newMobileLayout = CardLayoutState(
            size: card.layout.mobile.size,
            position: newPos,
          );

          final newLayout = CardLayout(
            desktop: card.layout.desktop,
            mobile: newMobileLayout,
          );

          cardStore.updateCardLayout(card.id, newLayout);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardStore = context.watch<CardStore>();
    final settings = context.watch<SettingsStore>();
    final cards = cardStore.cards;
    final viewMode = cardStore.viewMode;
    final isMobile = viewMode == ViewMode.mobile;

    final gridConfig = settings.gridConfig;
    final columns = isMobile ? gridConfig.mobileColumns : gridConfig.desktopColumns;
    final unitSize = isMobile ? gridConfig.mobileUnitSize : gridConfig.desktopUnitSize;
    final gap = isMobile ? gridConfig.mobileGap : gridConfig.desktopGap;

    // 计算网格总宽度
    final gridWidth = columns * unitSize + (columns - 1) * gap;

    // 如果未初始化，显示加载状态
    if (!cardStore.isInitialized) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // 如果没有卡片，显示空状态
    if (cards.isEmpty) {
      return const SizedBox.shrink();
    }

    // 按位置排序卡片（先按 y，再按 x）
    final sortedCards = List<CardItem>.from(cards);
    sortedCards.sort((a, b) {
      final layoutA = isMobile ? a.layout.mobile : a.layout.desktop;
      final layoutB = isMobile ? b.layout.mobile : b.layout.desktop;
      if (layoutA.position.y != layoutB.position.y) {
        return layoutA.position.y.compareTo(layoutB.position.y);
      }
      return layoutA.position.x.compareTo(layoutB.position.x);
    });

    // 如果不可编辑，使用普通 Column 布局
    if (!editable) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: GestureDetector(
          onTap: () {
            if (cardStore.selectedCardIds.isNotEmpty) {
              cardStore.clearSelection();
            }
          },
          behavior: HitTestBehavior.translucent,
          child: SizedBox(
            width: gridWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < sortedCards.length; i++) ...[
                  Builder(
                    builder: (context) {
                      final card = sortedCards[i];
                      final layout = isMobile ? card.layout.mobile : card.layout.desktop;
                      final dimensions = _getCardDimensions(layout.size);
                      final h = dimensions['h']!;

                      // 计算实际尺寸（像素）
                      final screenWidth = MediaQuery.of(context).size.width;
                      final cardWidth = screenWidth - 48;

                      final cardHeight = h * unitSize + (h - 1) * gap;
                      return SizedBox(
                        width: cardWidth,
                        height: cardHeight,
                        child: CardRenderer(card: card, editable: editable),
                      );
                    },
                  ),
                  // 在卡片之间添加间距，最后一个卡片后面不添加
                  if (i < sortedCards.length - 1) SizedBox(height: gap),
                ],
              ],
            ),
          ),
        ),
      );
    }

    // 可编辑模式下，使用 ReorderableGridView 实现拖拽
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: GestureDetector(
        onTap: () {
          if (cardStore.selectedCardIds.isNotEmpty) {
            cardStore.clearSelection();
          }
        },
        behavior: HitTestBehavior.translucent,
        child: SizedBox(
          width: gridWidth,
          child: ReorderableGridView.count(
            crossAxisCount: 1, // 单列布局，垂直排列
            mainAxisSpacing: gap,
            crossAxisSpacing: 0,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            proxyDecorator: (child, index, animation) {
              // 只让背景透明，保留卡片内容可见
              return Container(
                color: Colors.transparent, // 背景透明
                child: child,
              );
            },
            children: [
              for (int i = 0; i < sortedCards.length; i++)
                Builder(
                  key: ValueKey(sortedCards[i].id),
                  builder: (context) {
                    final card = sortedCards[i];
                    final layout = isMobile ? card.layout.mobile : card.layout.desktop;
                    final dimensions = _getCardDimensions(layout.size);
                    final h = dimensions['h']!;

                    // 计算实际尺寸（像素）
                    final screenWidth = MediaQuery.of(context).size.width;
                    final cardWidth = screenWidth - 48;

                    final cardHeight = h * unitSize + (h - 1) * gap;
                    return SizedBox(
                      width: cardWidth,
                      height: cardHeight,
                      child: CardRenderer(card: card, editable: editable),
                    );
                  },
                ),
            ],
            onReorder: (oldIndex, newIndex) {
              // 处理拖拽重排
              if (oldIndex < newIndex) {
                newIndex -= 1;
              }

              // 创建新的排序索引列表
              final newOrder = List<int>.generate(sortedCards.length, (index) => index);
              final item = newOrder.removeAt(oldIndex);
              newOrder.insert(newIndex, item);

              // 调用布局变化处理函数
              _handleLayoutChange(
                context,
                cardStore,
                settings,
                sortedCards,
                viewMode,
                newOrder,
              );
            },
          ),
        ),
      ),
    );
  }
}
