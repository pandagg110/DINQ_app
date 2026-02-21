import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// 网格系统配置
// ---------------------------------------------------------------------------

/// 网格布局配置
class AdminGridConfig {
  const AdminGridConfig({
    this.crossAxisCount = 4,
    this.mainAxisSpacing = 8,
    this.crossAxisSpacing = 8,
    this.padding = const EdgeInsets.all(8),
  });

  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final EdgeInsetsGeometry padding;
}

/// 解析 "WxH" 为 (widthCells, heightCells)，如 "4x4" -> (4, 4)
(int, int) _parseSize(String size) {
  final parts = size.split('x');
  if (parts.length != 2) return (1, 1);
  final w = int.tryParse(parts[0].trim()) ?? 1;
  final h = int.tryParse(parts[1].trim()) ?? 1;
  return (w, h);
}

/// 单个格子的占格与样式配置
///
/// 三种模式之一：
/// - 指定 [cellX], [cellY], [cellW], [cellH]：按格点坐标与格点尺寸摆放（与 JSON position/size 对应）
/// - 指定 [x], [y], [w], [h]（像素）：按绝对像素位置与尺寸
/// - 指定 [crossAxisCellCount], [mainAxisCellCount]：按占格数参与自动排布
class AdminGridTileData {
  const AdminGridTileData({
    this.crossAxisCellCount,
    this.mainAxisCellCount,
    this.x,
    this.y,
    this.w,
    this.h,
    this.cellX,
    this.cellY,
    this.cellW,
    this.cellH,
    required this.color,
    this.label,
  }) : assert(
         (x != null && y != null && w != null && h != null) ||
             (crossAxisCellCount != null && mainAxisCellCount != null) ||
             (cellX != null && cellY != null && cellW != null && cellH != null),
         '须指定 (x,y,w,h)、(crossAxisCellCount, mainAxisCellCount) 或 (cellX, cellY, cellW, cellH)',
       );

  /// 占格模式：横向占格数
  final int? crossAxisCellCount;
  /// 占格模式：纵向占格数
  final int? mainAxisCellCount;
  /// 绝对像素：左边距
  final double? x;
  final double? y;
  final double? w;
  final double? h;
  /// 格点模式：列索引（格点）
  final int? cellX;
  /// 格点模式：行索引（格点）
  final int? cellY;
  /// 格点模式：占列数
  final int? cellW;
  /// 格点模式：占行数
  final int? cellH;

  final Color color;
  final String? label;

  bool get isAbsolute =>
      x != null && y != null && w != null && h != null;
  bool get isCellBased =>
      cellX != null && cellY != null && cellW != null && cellH != null;
}

// ---------------------------------------------------------------------------
// 纯源码实现：交错网格（无第三方包）
// ---------------------------------------------------------------------------

/// 单个交错网格项：占格数、x,y,w,h 或 cellX,cellY,cellW,cellH + 子组件
class _StaggeredGridTile {
  const _StaggeredGridTile({
    this.crossAxisCellCount,
    this.mainAxisCellCount,
    this.x,
    this.y,
    this.w,
    this.h,
    this.cellX,
    this.cellY,
    this.cellW,
    this.cellH,
    required this.child,
  }) : assert(
         (x != null && y != null && w != null && h != null) ||
             (crossAxisCellCount != null && mainAxisCellCount != null) ||
             (cellX != null && cellY != null && cellW != null && cellH != null),
         '须指定 (x,y,w,h)、(crossAxisCellCount, mainAxisCellCount) 或 (cellX, cellY, cellW, cellH)',
       );

  final int? crossAxisCellCount;
  final int? mainAxisCellCount;
  final double? x;
  final double? y;
  final double? w;
  final double? h;
  final int? cellX;
  final int? cellY;
  final int? cellW;
  final int? cellH;
  final Widget child;

  bool get isAbsolute =>
      x != null && y != null && w != null && h != null;
  bool get isCellBased =>
      cellX != null && cellY != null && cellW != null && cellH != null;
}

/// 交错网格布局结果：每个子项的位置与尺寸
class _StaggeredPlacement {
  const _StaggeredPlacement({
    required this.offset,
    required this.size,
  });
  final Offset offset;
  final Size size;
}

/// 底层 1x1 格子：空白容器并标记 (x,y)
class _GridCellMarker extends StatelessWidget {
  const _GridCellMarker({required this.cellX, required this.cellY});

  final int cellX;
  final int cellY;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
      ),
      child: Center(
        child: Text(
          '$cellX,$cellY',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade500,
          ),
        ),
      ),
    );
  }
}

/// 使用源码实现的交错网格容器
class _StaggeredGridBody extends StatelessWidget {
  const _StaggeredGridBody({
    required this.config,
    required this.tiles,
  });

  final AdminGridConfig config;
  final List<_StaggeredGridTile> tiles;

  List<_StaggeredPlacement> _computeLayout(double contentWidth) {
    final int cols = config.crossAxisCount;
    final double mainSpacing = config.mainAxisSpacing;
    final double crossSpacing = config.crossAxisSpacing;

    final double cellWidth =
        (contentWidth - (cols - 1) * crossSpacing) / cols;
    final double cellHeight = cellWidth;

    final List<double> colTops = List.filled(cols, 0.0);
    final List<_StaggeredPlacement> placements = [];

    // 格点模式：按 (cellY, cellX) 排序后纵向紧凑排布，消除数据 y 跳跃导致的空白间隔
    final Map<int, _StaggeredPlacement> cellBasedPlacements = {};
    final List<int> cellBasedIndices = [
      for (int i = 0; i < tiles.length; i++)
        if (tiles[i].isCellBased) i
    ];
    cellBasedIndices.sort((a, b) {
      final ta = tiles[a];
      final tb = tiles[b];
      final cyCmp = ta.cellY!.compareTo(tb.cellY!);
      if (cyCmp != 0) return cyCmp;
      return ta.cellX!.compareTo(tb.cellX!);
    });
    for (final i in cellBasedIndices) {
      final tile = tiles[i];
      final int cx = tile.cellX!, cw = tile.cellW!, ch = tile.cellH!;
      double py = 0;
      for (int c = cx; c < cx + cw && c < cols; c++) {
        if (colTops[c] > py) py = colTops[c];
      }
      final double px = cx * (cellWidth + crossSpacing);
      final double pw = cw * cellWidth + (cw - 1) * crossSpacing;
      final double ph = ch * cellHeight + (ch - 1) * mainSpacing;
      cellBasedPlacements[i] = _StaggeredPlacement(
        offset: Offset(px, py),
        size: Size(pw, ph),
      );
      for (int c = cx; c < cx + cw && c < cols; c++) {
        colTops[c] = py + ph + mainSpacing;
      }
    }

    for (int i = 0; i < tiles.length; i++) {
      final tile = tiles[i];
      if (tile.isAbsolute) {
        placements.add(_StaggeredPlacement(
          offset: Offset(tile.x!, tile.y!),
          size: Size(tile.w!, tile.h!),
        ));
        continue;
      }
      if (tile.isCellBased) {
        placements.add(cellBasedPlacements[i]!);
        continue;
      }

      final int span = tile.crossAxisCellCount!;
      int bestCol = 0;
      double bestTop = colTops[0];
      for (int c = 0; c <= cols - span; c++) {
        double maxTop = colTops[c];
        for (int k = 1; k < span; k++) {
          if (colTops[c + k] > maxTop) maxTop = colTops[c + k];
        }
        if (maxTop < bestTop) {
          bestTop = maxTop;
          bestCol = c;
        }
      }

      final double w = span * cellWidth + (span - 1) * crossSpacing;
      final double h = tile.mainAxisCellCount! * cellHeight +
          (tile.mainAxisCellCount! - 1) * mainSpacing;
      final double x = bestCol * (cellWidth + crossSpacing);
      final double y = bestTop;

      placements.add(_StaggeredPlacement(offset: Offset(x, y), size: Size(w, h)));

      final double newTop = y + h + mainSpacing;
      for (int c = bestCol; c < bestCol + span; c++) {
        colTops[c] = newTop;
      }
    }

    return placements;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double contentWidth = constraints.maxWidth;
        final int cols = config.crossAxisCount;
        final double mainSpacing = config.mainAxisSpacing;
        final double crossSpacing = config.crossAxisSpacing;
        final double cellWidth =
            (contentWidth - (cols - 1) * crossSpacing) / cols;
        final double cellHeight = cellWidth;

        final List<_StaggeredPlacement> placements =
            _computeLayout(contentWidth);
        final double totalHeight = placements.isEmpty
            ? 0.0
            : placements
                .map((p) => p.offset.dy + p.size.height)
                .reduce((a, b) => a > b ? a : b);

        // 下层：1x1 格子铺满，横纵都带间距，并标记 xy
        final double rowStep = cellHeight + mainSpacing;
        final int rowCount = totalHeight <= 0
            ? 0
            : ((totalHeight + mainSpacing) / rowStep).ceil();
        final List<Widget> backgroundCells = [];
        for (int ry = 0; ry < rowCount; ry++) {
          for (int rx = 0; rx < cols; rx++) {
            final double px = rx * (cellWidth + crossSpacing);
            final double py = ry * rowStep;
            backgroundCells.add(
              Positioned(
                left: px,
                top: py,
                width: cellWidth,
                height: cellHeight,
                child: _GridCellMarker(cellX: rx, cellY: ry),
              ),
            );
          }
        }

        // 上层：实际数据块（Positioned）
        final List<Widget> dataLayer = [
          for (int i = 0; i < tiles.length && i < placements.length; i++)
            Positioned(
              left: placements[i].offset.dx,
              top: placements[i].offset.dy,
              width: placements[i].size.width,
              height: placements[i].size.height,
              child: tiles[i].child,
            ),
        ];

        return SizedBox(
          height: totalHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ...backgroundCells,
              ...dataLayer,
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// 页面：仅展示网格，无拖拽
// ---------------------------------------------------------------------------

class AdminTextPage extends StatelessWidget {
  const AdminTextPage({super.key});

  static const AdminGridConfig _gridConfig = AdminGridConfig();

  /// 按 JSON 结构：size "WxH"，position { x, y }（格点单位）
  static final List<AdminGridTileData> _tiles = _buildTilesFromJson([
    {'size': '4x4', 'position': {'x': 0, 'y': 12}},
    {'size': '4x4', 'position': {'x': 0, 'y': 22}},
    {'size': '2x4', 'position': {'x': 0, 'y': 0}},
    {'size': '4x2', 'position': {'x': 0, 'y': 6}},
    {'size': '2x2', 'position': {'x': 0, 'y': 4}},
    {'size': '2x2', 'position': {'x': 2, 'y': 0}},
    {'size': '4x4', 'position': {'x': 0, 'y': 8}},
    {'size': '4x4', 'position': {'x': 0, 'y': 16}},
  ]);

  static List<AdminGridTileData> _buildTilesFromJson(List<Map<String, dynamic>> list) {
    final colors = [
      Colors.blue.shade100,
      Colors.green.shade100,
      Colors.orange.shade100,
      Colors.purple.shade100,
      Colors.teal.shade100,
      Colors.amber.shade100,
      Colors.red.shade100,
    ];
    final out = <AdminGridTileData>[];
    for (int i = 0; i < list.length; i++) {
      final m = list[i];
      final sizeStr = m['size'] as String? ?? '1x1';
      final pos = m['position'] as Map<String, dynamic>? ?? {};
      final (cw, ch) = _parseSize(sizeStr);
      final cellX = (pos['x'] as num?)?.toInt() ?? 0;
      final cellY = (pos['y'] as num?)?.toInt() ?? 0;
      out.add(AdminGridTileData(
        cellX: cellX,
        cellY: cellY,
        cellW: cw,
        cellH: ch,
        color: colors[i % colors.length],
        label: '${i + 1}',
      ));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grid Demo'),
      ),
      body: SingleChildScrollView(
        padding: _gridConfig.padding,
        child: _StaggeredGridBody(
          config: _gridConfig,
          tiles: [
            for (int i = 0; i < _tiles.length; i++)
              _StaggeredGridTile(
                crossAxisCellCount: _tiles[i].crossAxisCellCount,
                mainAxisCellCount: _tiles[i].mainAxisCellCount,
                x: _tiles[i].x,
                y: _tiles[i].y,
                w: _tiles[i].w,
                h: _tiles[i].h,
                cellX: _tiles[i].cellX,
                cellY: _tiles[i].cellY,
                cellW: _tiles[i].cellW,
                cellH: _tiles[i].cellH,
                child: _GridTile(
                  index: i,
                  color: _tiles[i].color,
                  label: _tiles[i].label ?? '${i + 1}',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 单个格子展示（无拖拽）
class _GridTile extends StatelessWidget {
  const _GridTile({
    required this.index,
    required this.color,
    required this.label,
  });

  final int index;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}
