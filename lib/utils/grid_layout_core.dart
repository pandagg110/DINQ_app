// ---------------------------------------------------------------------------
// 纯布局算法：从 react-grid-layout/core 的 calculate.ts / position 逻辑转换
// 格点与像素互算、统一公式，避免布局与拖拽格点不一致
// ---------------------------------------------------------------------------

/// 网格布局参数（对应 RGL PositionParams）
class GridLayoutParams {
  const GridLayoutParams({
    required this.containerWidth,
    required this.cols,
    required this.rowHeight,
    this.marginX = 0.0,
    this.marginY = 0.0,
    this.containerPaddingX = 0.0,
    this.containerPaddingY = 0.0,
    this.maxRows = 999,
  });

  final double containerWidth;
  final int cols;
  final double rowHeight;
  final double marginX;
  final double marginY;
  final double containerPaddingX;
  final double containerPaddingY;
  final int maxRows;

  /// 单列宽度（像素），RGL calcGridColWidth
  double get colWidth =>
      (containerWidth - marginX * (cols - 1) - containerPaddingX * 2) / cols;

  /// 单格宽度（含一侧间距），用于像素↔格点换算
  double get colStep => colWidth + marginX;

  /// 单格高度（含一侧间距）
  double get rowStep => rowHeight + marginY;
}

/// 像素矩形（对应 RGL Position: top, left, width, height）
class GridItemPixelRect {
  const GridItemPixelRect({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });
  final double left;
  final double top;
  final double width;
  final double height;
  double get right => left + width;
  double get bottom => top + height;
}

/// 将 grid 单位尺寸转为像素尺寸，RGL calcGridItemWHPx
double calcGridItemWHPx(int gridUnits, double colOrRowSize, double marginPx) {
  if (gridUnits <= 0) return 0;
  return colOrRowSize * gridUnits + (gridUnits - 1) * marginPx;
}

/// 格点位置 + 占格 → 像素矩形，RGL calcGridItemPosition（无 drag/resize 偏移）
GridItemPixelRect calcGridItemPosition(
  GridLayoutParams params,
  int x,
  int y,
  int w,
  int h,
) {
  final colWidth = params.colWidth;
  final width = calcGridItemWHPx(w, colWidth, params.marginX);
  final height = calcGridItemWHPx(h, params.rowHeight, params.marginY);
  final left = params.containerPaddingX + x * params.colStep;
  final top = params.containerPaddingY + y * params.rowStep;
  return GridItemPixelRect(left: left, top: top, width: width, height: height);
}

/// 像素坐标 → 格点 (x,y)，带边界钳位，RGL calcXY
(int x, int y) calcXY(
  GridLayoutParams params,
  double leftPx,
  double topPx,
  int w,
  int h, {
  double toleranceX = 0,
  double toleranceY = 0,
}) {
  final left = leftPx + toleranceX;
  final top = topPx + toleranceY;
  int x = ((left - params.containerPaddingX) / params.colStep).round();
  int y = ((top - params.containerPaddingY) / params.rowStep).round();
  x = x.clamp(0, params.cols - w);
  y = y.clamp(0, params.maxRows - h);
  return (x, y);
}
