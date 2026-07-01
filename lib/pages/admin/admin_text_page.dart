import 'package:flutter/material.dart';

import '../../utils/card_layout_utils.dart';
import '../../utils/grid_layout_core.dart';

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
    this.id,
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
  final String? id;

  bool get isAbsolute => x != null && y != null && w != null && h != null;
  bool get isCellBased =>
      cellX != null && cellY != null && cellW != null && cellH != null;
}

// ---------------------------------------------------------------------------
// 纯源码实现：交错网格（无第三方包）
// ---------------------------------------------------------------------------

/// 单个交错网格项：占格数、x,y,w,h 或 cellX,cellY,cellW,cellH + 展示数据（用于在 Body 内按实际尺寸构建拖拽与内容）
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
    required this.index,
    required this.color,
    required this.label,
    this.id,
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
  final int index;
  final Color color;
  final String label;
  final String? id;

  bool get isAbsolute => x != null && y != null && w != null && h != null;
  bool get isCellBased =>
      cellX != null && cellY != null && cellW != null && cellH != null;
}

/// 交错网格布局结果：每个子项的位置与尺寸（含元数据 id）
class _StaggeredPlacement {
  const _StaggeredPlacement({
    required this.offset,
    required this.size,
    this.id,
  });
  final Offset offset;
  final Size size;
  final String? id;
}

/// 拖拽时传递的数据：格子索引与占格尺寸
class _TileDragData {
  const _TileDragData({
    required this.index,
    required this.cellW,
    required this.cellH,
  });
  final int index;
  final int cellW;
  final int cellH;
}

/// 显式动画：用 Controller 驱动位置过渡，不依赖隐式 AnimatedPositioned（在 LayoutBuilder 等复杂树下更可靠）
class _AnimatedPositionedTile extends StatefulWidget {
  const _AnimatedPositionedTile({
    super.key,
    required this.targetRect,
    required this.duration,
    required this.child,
  });

  final Rect targetRect;
  final Duration duration;
  final Widget child;

  @override
  State<_AnimatedPositionedTile> createState() =>
      _AnimatedPositionedTileState();
}

class _AnimatedPositionedTileState extends State<_AnimatedPositionedTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Animation<Rect?>? _animation;
  late Rect _currentRect;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _currentRect = widget.targetRect;
  }

  @override
  void didUpdateWidget(_AnimatedPositionedTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    final to = widget.targetRect;
    if (to != _currentRect) {
      _animation = RectTween(
        begin: _currentRect,
        end: to,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
      _controller.reset();
      void onStatus(AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _currentRect = to;
            _animation = null;
          });
          _controller.removeStatusListener(onStatus);
        }
      }

      _controller.addStatusListener(onStatus);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_animation == null) {
      return Positioned.fromRect(rect: _currentRect, child: widget.child);
    }
    return AnimatedBuilder(
      animation: _animation!,
      builder: (context, child) {
        final r = _animation!.value ?? _currentRect;
        return Positioned(
          left: r.left,
          top: r.top,
          width: r.width,
          height: r.height,
          child: child!,
        );
      },
      child: widget.child,
    );
  }
}

/// 底层 1x1 格子：空白容器并标记 (x,y)，不参与拖拽
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
          style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
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
    this.onTileDrop,
    this.onTileDragMove,
    this.tileKeys,
  });

  final AdminGridConfig config;
  final List<_StaggeredGridTile> tiles;

  /// 拖拽放下时回调 (index, newCellX, newCellY)，用于更新格子位置
  final void Function(int index, int cellX, int cellY)? onTileDrop;

  /// 拖拽移动过程中回调，用于实时更新格子位置（与 onTileDrop 可共用同一方法）
  final void Function(int index, int cellX, int cellY)? onTileDragMove;

  /// 按 tile id 的 GlobalKey，用于强制复用 _AnimatedPositionedTile 的 State，保证 didUpdateWidget 触发动画
  final Map<String, GlobalKey>? tileKeys;

  Widget _buildDraggableTile({
    required _StaggeredGridTile tile,
    required Size placementSize,
  }) {
    final dragData = _TileDragData(
      index: tile.index,
      cellW: tile.cellW!,
      cellH: tile.cellH!,
    );
    final content = _GridTile(
      index: tile.index,
      color: tile.color,
      label: tile.label,
    );
    return Draggable<_TileDragData>(
      data: dragData,
      // feedback 中心跟随指针，格点按「指针 - size/2」当瓦片左上角计算
      feedbackOffset: Offset(
        -placementSize.width / 2,
        -placementSize.height / 2,
      ),
      feedback: IgnorePointer(
        child: Material(
          color: Colors.transparent,
          child: SizedBox(
            width: placementSize.width,
            height: placementSize.height,
            child: content,
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.5, child: content),
      child: content,
    );
  }

  List<_StaggeredPlacement> _computeLayout(double contentWidth) {
    final int cols = config.crossAxisCount;
    final double mainSpacing = config.mainAxisSpacing;
    final double crossSpacing = config.crossAxisSpacing;

    final double cellWidth = (contentWidth - (cols - 1) * crossSpacing) / cols;
    final double cellHeight = cellWidth;

    // 使用与 RGL 一致的纯布局参数，格点↔像素统一公式
    final params = GridLayoutParams(
      containerWidth: contentWidth,
      cols: cols,
      rowHeight: cellHeight,
      marginX: crossSpacing,
      marginY: mainSpacing,
      containerPaddingX: 0,
      containerPaddingY: 0,
    );

    final List<double> colTops = List.filled(cols, 0.0);
    final List<_StaggeredPlacement> placements = [];

    // 格点模式：用 grid_layout_core 的 calcGridItemPosition，与拖拽时的 calcXY 互逆
    final Map<int, _StaggeredPlacement> cellBasedPlacements = {};
    for (int i = 0; i < tiles.length; i++) {
      if (!tiles[i].isCellBased) continue;
      final tile = tiles[i];
      final int cx = tile.cellX!,
          cy = tile.cellY!,
          cw = tile.cellW!,
          ch = tile.cellH!;
      final rect = calcGridItemPosition(params, cx, cy, cw, ch);
      cellBasedPlacements[i] = _StaggeredPlacement(
        offset: Offset(rect.left, rect.top),
        size: Size(rect.width, rect.height),
        id: tile.id,
      );
      for (int c = cx; c < cx + cw && c < cols; c++) {
        colTops[c] = rect.bottom + mainSpacing;
      }
    }

    for (int i = 0; i < tiles.length; i++) {
      final tile = tiles[i];
      if (tile.isAbsolute) {
        placements.add(
          _StaggeredPlacement(
            offset: Offset(tile.x!, tile.y!),
            size: Size(tile.w!, tile.h!),
            id: tile.id,
          ),
        );
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
      final double h =
          tile.mainAxisCellCount! * cellHeight +
          (tile.mainAxisCellCount! - 1) * mainSpacing;
      final double x = bestCol * (cellWidth + crossSpacing);
      final double y = bestTop;

      placements.add(
        _StaggeredPlacement(
          offset: Offset(x, y),
          size: Size(w, h),
          id: tile.id,
        ),
      );

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

        final List<_StaggeredPlacement> placements = _computeLayout(
          contentWidth,
        );
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

        // 上层：显式动画 _AnimatedPositionedTile，用 tileKeys 强制复用 State，松手后 didUpdateWidget 触发动画
        const _kTileAnimDuration = Duration(milliseconds: 280);
        final List<Widget> dataLayer = [
          for (int i = 0; i < tiles.length && i < placements.length; i++) ...[
            _AnimatedPositionedTile(
              key:
                  tileKeys?[placements[i].id ?? 'grid_tile_$i'] ??
                  ValueKey(placements[i].id ?? 'grid_tile_$i'),
              duration: _kTileAnimDuration,
              targetRect: Rect.fromLTWH(
                placements[i].offset.dx,
                placements[i].offset.dy,
                placements[i].size.width,
                placements[i].size.height,
              ),
              child: _buildDraggableTile(
                tile: tiles[i],
                placementSize: placements[i].size,
              ),
            ),
          ],
        ];

        final stackContent = Stack(
          key: const ValueKey('grid_stack'),
          clipBehavior: Clip.none,
          children: [...backgroundCells, ...dataLayer],
        );

        if (onTileDrop == null) {
          return SizedBox(height: totalHeight, child: stackContent);
        }

        final stackKey = GlobalKey();

        /// 与 _computeLayout 同一套参数，保证格点↔像素互算一致
        final gridParams = GridLayoutParams(
          containerWidth: contentWidth,
          cols: cols,
          rowHeight: cellHeight,
          marginX: crossSpacing,
          marginY: mainSpacing,
          containerPaddingX: 0,
          containerPaddingY: 0,
        );

        /// 容错：仅松手时用，落点稍微越过格线即算进入该格
        const double _cellToleranceDrop = 8.0;

        /// onMove：用「指针所在格」作为落点（中心格点），与视觉一致；内部会转成左上角再放置
        void reportCellPosition(
          DragTargetDetails<_TileDragData> details,
          Offset globalPointer,
        ) {
          final box = stackKey.currentContext?.findRenderObject() as RenderBox?;
          if (box == null) return;
          final localPointer = box.globalToLocal(globalPointer);
          final (int cellX, int cellY) = calcXY(
            gridParams,
            localPointer.dx,
            localPointer.dy,
            1,
            1,
            toleranceX: 0,
            toleranceY: 0,
          );
          onTileDragMove?.call(details.data.index, cellX, cellY);
        }

        return DragTarget<_TileDragData>(
          onMove: onTileDragMove != null
              ? (DragTargetDetails<_TileDragData> details) =>
                    reportCellPosition(details, details.offset)
              : null,
          onAcceptWithDetails: (DragTargetDetails<_TileDragData> details) {
            final box =
                stackKey.currentContext?.findRenderObject() as RenderBox?;
            if (box == null) return;
            final localPointer = box.globalToLocal(details.offset);
            final (int cellX, int cellY) = calcXY(
              gridParams,
              localPointer.dx,
              localPointer.dy,
              1,
              1,
              toleranceX: _cellToleranceDrop,
              toleranceY: _cellToleranceDrop,
            );
            onTileDrop!(details.data.index, cellX, cellY);
          },
          builder: (context, candidateData, rejectedData) =>
              SizedBox(key: stackKey, height: totalHeight, child: stackContent),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// 页面：网格 + 数据块拖拽（底层 1x1 不拖拽）
// ---------------------------------------------------------------------------

class AdminTextPage extends StatefulWidget {
  const AdminTextPage({super.key});

  @override
  State<AdminTextPage> createState() => _AdminTextPageState();
}

class _AdminTextPageState extends State<AdminTextPage> {
  static const AdminGridConfig _gridConfig = AdminGridConfig();

  /// 按 JSON 结构：id，size "WxH"，position { x, y }（格点单位）
  static List<AdminGridTileData> _buildInitialTiles() => _buildTilesFromJson([
    {
      'id': '1',
      'size': '4x4',
      'position': {'x': 0, 'y': 12},
    },
    {
      'id': '2',
      'size': '4x4',
      'position': {'x': 0, 'y': 22},
    },
    {
      'id': '3',
      'size': '2x4',
      'position': {'x': 0, 'y': 0},
    },
    {
      'id': '4',
      'size': '4x2',
      'position': {'x': 0, 'y': 6},
    },
    {
      'id': '5',
      'size': '2x2',
      'position': {'x': 0, 'y': 4},
    },
    {
      'id': '6',
      'size': '2x2',
      'position': {'x': 2, 'y': 0},
    },
    {
      'id': '7',
      'size': '4x4',
      'position': {'x': 0, 'y': 8},
    },
    {
      'id': '8',
      'size': '4x4',
      'position': {'x': 0, 'y': 16},
    },
  ]);

  static List<AdminGridTileData> _buildTilesFromJson(
    List<Map<String, dynamic>> list,
  ) {
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
      out.add(
        AdminGridTileData(
          cellX: cellX,
          cellY: cellY,
          cellW: cw,
          cellH: ch,
          color: colors[i % colors.length],
          label: '${i + 1}',
          id: m['id'] as String?,
        ),
      );
    }
    return out;
  }

  late List<AdminGridTileData> _tiles = _buildInitialTiles();

  /// 每个格子 id 对应一个 GlobalKey，强制 Flutter 复用 _AnimatedPositionedTile 的 State，保证松手后 didUpdateWidget 被调用并播动画
  late final Map<String, GlobalKey> _tileKeys = _initTileKeys();

  static Map<String, GlobalKey> _initTileKeys() {
    final tiles = _buildInitialTiles();
    return {
      for (int i = 0; i < tiles.length; i++)
        (tiles[i].id ?? 'grid_tile_$i'): GlobalKey(),
    };
  }

  /// AnimatedPositioned 示例：点击切换位置，用于测试过渡动画是否生效
  bool _demoRight = false;

  Widget _buildAnimatedPositionedDemo() {
    return Container(
      height: 100,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOut,
            left: _demoRight ? 180 : 8,
            top: 8,
            width: 80,
            height: 84,
            child: Material(
              color: Colors.orange.shade200,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: () => setState(() => _demoRight = !_demoRight),
                borderRadius: BorderRadius.circular(8),
                child: const Center(
                  child: Text(
                    '点我\n移动',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const int _maxCellY = 999;

  /// 将 cellX/cellY 限制在网格内，避免块越界或与背景格错位
  int _clampCellX(int cellX, int cellW) =>
      cellX.clamp(0, _gridConfig.crossAxisCount - cellW);
  int _clampCellY(int cellY, int cellH) => cellY.clamp(0, _maxCellY);

  /// 两矩形在格点上是否重叠 [x, x+w) x [y, y+h)
  bool _rectsOverlap(
    int x1,
    int y1,
    int w1,
    int h1,
    int x2,
    int y2,
    int w2,
    int h2,
  ) {
    return x1 < x2 + w2 && x2 < x1 + w1 && y1 < y2 + h2 && y2 < y1 + h1;
  }

  /// 找到与矩形 (x,y,w,h) 重叠的格点块索引（排除 excludeIndex），若无则 null
  int? _findTileOverlapping(
    List<AdminGridTileData> tiles,
    int excludeIndex,
    int x,
    int y,
    int w,
    int h,
  ) {
    for (int i = 0; i < tiles.length; i++) {
      if (i == excludeIndex) continue;
      final o = tiles[i];
      if (!o.isCellBased) continue;
      if (_rectsOverlap(x, y, w, h, o.cellX!, o.cellY!, o.cellW!, o.cellH!))
        return i;
    }
    return null;
  }

  /// 更新格子位置：中心格点→左上角；若落点与某块重叠则互换，否则只移动当前块，再整表紧凑
  void _onTilePositionUpdate(int index, int cellX, int cellY) {
    if (index < 0 || index >= _tiles.length) return;

    final t = _tiles[index];
    if (!t.isCellBased) return;

    final cw = t.cellW!;
    final ch = t.cellH!;
    // 中心格点 → 左上角格点（2x2 中心在 (2,0) 则左上角在 (1,0)）
    final topLeftX = cellX - cw ~/ 2;
    final topLeftY = cellY - ch ~/ 2;
    final safeX = _clampCellX(topLeftX, cw);
    final safeY = _clampCellY(topLeftY, ch);

    final targetIndex = _findTileOverlapping(
      _tiles,
      index,
      safeX,
      safeY,
      cw,
      ch,
    );

    setState(() {
      _tiles = List.from(_tiles);

      if (targetIndex != null && targetIndex != index) {
        // 落在已有块上：与对方互换位置
        final other = _tiles[targetIndex];
        if (other.isCellBased) {
          final ow = other.cellW!;
          final oh = other.cellH!;
          final safeTileX = _clampCellX(other.cellX!, cw);
          final safeTileY = _clampCellY(other.cellY!, ch);
          final safeOtherX = _clampCellX(t.cellX!, ow);
          final safeOtherY = _clampCellY(t.cellY!, oh);
          _tiles[index] = AdminGridTileData(
            crossAxisCellCount: t.crossAxisCellCount,
            mainAxisCellCount: t.mainAxisCellCount,
            x: t.x,
            y: t.y,
            w: t.w,
            h: t.h,
            cellX: safeTileX,
            cellY: safeTileY,
            cellW: t.cellW,
            cellH: t.cellH,
            color: t.color,
            label: t.label,
            id: t.id,
          );
          _tiles[targetIndex] = AdminGridTileData(
            crossAxisCellCount: other.crossAxisCellCount,
            mainAxisCellCount: other.mainAxisCellCount,
            x: other.x,
            y: other.y,
            w: other.w,
            h: other.h,
            cellX: safeOtherX,
            cellY: safeOtherY,
            cellW: other.cellW,
            cellH: other.cellH,
            color: other.color,
            label: other.label,
            id: other.id,
          );
        } else {
          _tiles[index] = AdminGridTileData(
            crossAxisCellCount: t.crossAxisCellCount,
            mainAxisCellCount: t.mainAxisCellCount,
            x: t.x,
            y: t.y,
            w: t.w,
            h: t.h,
            cellX: safeX,
            cellY: safeY,
            cellW: t.cellW,
            cellH: t.cellH,
            color: t.color,
            label: t.label,
            id: t.id,
          );
        }
      } else {
        // 落在空白或自己上：只移动当前块
        _tiles[index] = AdminGridTileData(
          crossAxisCellCount: t.crossAxisCellCount,
          mainAxisCellCount: t.mainAxisCellCount,
          x: t.x,
          y: t.y,
          w: t.w,
          h: t.h,
          cellX: safeX,
          cellY: safeY,
          cellW: t.cellW,
          cellH: t.cellH,
          color: t.color,
          label: t.label,
          id: t.id,
        );
      }

      // 对整表做垂直紧凑重排（与 card_layout_utils 同一套 RGL 逻辑）
      final cellIndices = [
        for (int i = 0; i < _tiles.length; i++)
          if (_tiles[i].isCellBased) i,
      ];
      if (cellIndices.isEmpty) return;
      final items = [
        for (var i = 0; i < cellIndices.length; i++)
          (
            i: '$i',
            x: _tiles[cellIndices[i]].cellX!,
            y: _tiles[cellIndices[i]].cellY!,
            w: _tiles[cellIndices[i]].cellW!,
            h: _tiles[cellIndices[i]].cellH!,
          ),
      ];
      final compacted = CardLayoutUtils.compactGridLayout(
        items,
        _gridConfig.crossAxisCount,
      );
      for (var i = 0; i < cellIndices.length; i++) {
        final idx = cellIndices[i];
        final tile = _tiles[idx];
        _tiles[idx] = AdminGridTileData(
          crossAxisCellCount: tile.crossAxisCellCount,
          mainAxisCellCount: tile.mainAxisCellCount,
          x: tile.x,
          y: tile.y,
          w: tile.w,
          h: tile.h,
          cellX: compacted[i].x,
          cellY: compacted[i].y,
          cellW: tile.cellW,
          cellH: tile.cellH,
          color: tile.color,
          label: tile.label,
          id: tile.id,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Grid Demo')),
      body: SingleChildScrollView(
        padding: _gridConfig.padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildAnimatedPositionedDemo(),
            _StaggeredGridBody(
              config: _gridConfig,
              onTileDrop: _onTilePositionUpdate,
              onTileDragMove: _onTilePositionUpdate,
              tileKeys: _tileKeys,
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
                    index: i,
                    color: _tiles[i].color,
                    label: _tiles[i].label ?? '${i + 1}',
                    id: _tiles[i].id,
                  ),
              ],
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
