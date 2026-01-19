import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import '../../stores/card_store.dart';
import '../../stores/settings_store.dart';
import 'card_renderer.dart';

class CardGrid extends StatelessWidget {
  const CardGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final cardStore = context.watch<CardStore>();
    final settings = context.watch<SettingsStore>();
    final cards = cardStore.cards;
    final isMobile = settings.isMobile;
    final columns = isMobile ? settings.gridConfig.mobileColumns : settings.gridConfig.desktopColumns;
    final gap = isMobile ? settings.gridConfig.mobileGap : settings.gridConfig.desktopGap;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: StaggeredGrid.count(
        crossAxisCount: columns,
        mainAxisSpacing: gap,
        crossAxisSpacing: gap,
        children: cards.map((card) {
          final size = (isMobile ? card.layout.mobile.size : card.layout.desktop.size).toLowerCase();
          final tile = _tileForSize(size);
          return StaggeredGridTile.count(
            crossAxisCellCount: tile.crossAxis,
            mainAxisCellCount: tile.mainAxis,
            child: CardRenderer(card: card),
          );
        }).toList(),
      ),
    );
  }
}

class _TileSize {
  const _TileSize(this.crossAxis, this.mainAxis);
  final int crossAxis;
  final int mainAxis;
}

_TileSize _tileForSize(String size) {
  switch (size) {
    case '2x4':
      return const _TileSize(2, 4);
    case '4x2':
      return const _TileSize(4, 2);
    case '4x4':
      return const _TileSize(4, 4);
    default:
      return const _TileSize(2, 2);
  }
}

