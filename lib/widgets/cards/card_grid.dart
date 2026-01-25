import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final cardStore = context.watch<CardStore>();
    final settings = context.watch<SettingsStore>();
    final cards = cardStore.cards;

    final gridConfig = settings.gridConfig;
    final columns = gridConfig.mobileColumns;
    final unitSize = gridConfig.mobileUnitSize;
    final gap = gridConfig.mobileGap;

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
    debugPrint('CardGrid: cards: ${cards.map((card) => card.toJson().toString()).join(', ')}');
    // 按位置排序卡片（先按 y，再按 x）
    final sortedCards = List<CardItem>.from(cards);
    sortedCards.sort((a, b) {
      final layoutA = a.layout.mobile;
      final layoutB = b.layout.mobile;
      if (layoutA.position.y != layoutB.position.y) {
        return layoutA.position.y.compareTo(layoutB.position.y);
      }
      return layoutA.position.x.compareTo(layoutB.position.x);
    });


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
          child: ReorderableListView(
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
                    
                    // 计算实际尺寸（像素）
                    final screenWidth = MediaQuery.of(context).size.width;
                    final cardWidth = screenWidth - 48;

                    final cardHeight = card.data.type.toUpperCase() == 'TITLE' ? 124.0 : cardWidth + 24;
                    return SizedBox(
                      width: cardWidth,
                      height: cardHeight,
                      child: CardRenderer(card: card, editable: editable),
                    );
                  },
                ),
            ],
            onReorder: (oldIndex, newIndex) {
              // 重新获取最新的卡片列表（因为 sortedCards 是 build 时的快照）
              final currentCards = List<CardItem>.from(cardStore.cards);
              
              // 按位置排序卡片（先按 y，再按 x），确保顺序与 children 列表一致
              currentCards.sort((a, b) {
                final layoutA = a.layout.mobile;
                final layoutB = b.layout.mobile;
                if (layoutA.position.y != layoutB.position.y) {
                  return layoutA.position.y.compareTo(layoutB.position.y);
                }
                return layoutA.position.x.compareTo(layoutB.position.x);
              });

              // ReorderableListView 的 onReorder 行为：
              // - oldIndex: 拖拽开始的位置
              // - newIndex: 拖拽结束的位置
              //   当向下拖拽（oldIndex < newIndex）时，newIndex 是移除元素之前的位置，需要减1
              //   当向上拖拽（oldIndex > newIndex）时，newIndex 是移除元素之后的位置，保持不变
              
              // 创建新的卡片顺序（按照拖拽后的顺序）
              final reorderedCards = List<CardItem>.from(currentCards);
              final item = reorderedCards.removeAt(oldIndex);
              // 向下拖拽时需要调整 newIndex
              final insertIndex = oldIndex < newIndex ? newIndex - 1 : newIndex;
              reorderedCards.insert(insertIndex, item);

              // 按照排序规则（先按 y，再按 x）重新计算位置
              // 在单列布局中，y 从 0 开始递增，x 保持为 0
              for (int i = 0; i < reorderedCards.length; i++) {
                final card = reorderedCards[i];
                final currentLayout = card.layout.mobile;
                final newY = i;
                final newX = 0; // 单列布局，x 始终为 0

                // 如果位置没有变化，跳过
                if (currentLayout.position.y == newY && currentLayout.position.x == newX) {
                  continue;
                }

                final newPosition = CardPosition(
                  x: newX,
                  y: newY,
                  w: currentLayout.position.w,
                  h: currentLayout.position.h,
                );

                final newLayoutState = CardLayoutState(
                  size: currentLayout.size,
                  position: newPosition,
                );

                final newLayout = CardLayout(
                  desktop: card.layout.desktop,
                  mobile: newLayoutState,
                );

                cardStore.updateCardLayout(card.id, newLayout);
              }
            },
          ),
        ),
      ),
    );
  }
}
