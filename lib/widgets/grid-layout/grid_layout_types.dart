// ---------------------------------------------------------------------------
// 从 react-grid-layout/core/types 迁移的 Flutter 类型定义
// ---------------------------------------------------------------------------

/// 调整大小手柄方向（东南西北及对角）
enum ResizeHandleAxis {
  s,
  w,
  e,
  n,
  sw,
  nw,
  se,
  ne,
}

/// 单个网格项（对应 RGL LayoutItem）
class LayoutItem {
  LayoutItem({
    required this.i,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    this.minW,
    this.minH,
    this.maxW,
    this.maxH,
    this.static_ = false,
    this.isDraggable,
    this.isResizable,
    this.resizeHandles,
    this.isBounded,
    this.moved = false,
  });

  final String i;
  int x;
  int y;
  int w;
  int h;
  final int? minW;
  final int? minH;
  final int? maxW;
  final int? maxH;
  final bool static_;
  final bool? isDraggable;
  final bool? isResizable;
  final List<ResizeHandleAxis>? resizeHandles;
  final bool? isBounded;
  bool moved;

  LayoutItem copyWith({
    String? i,
    int? x,
    int? y,
    int? w,
    int? h,
    int? minW,
    int? minH,
    int? maxW,
    int? maxH,
    bool? static_,
    bool? isDraggable,
    bool? isResizable,
    List<ResizeHandleAxis>? resizeHandles,
    bool? isBounded,
    bool? moved,
  }) {
    return LayoutItem(
      i: i ?? this.i,
      x: x ?? this.x,
      y: y ?? this.y,
      w: w ?? this.w,
      h: h ?? this.h,
      minW: minW ?? this.minW,
      minH: minH ?? this.minH,
      maxW: maxW ?? this.maxW,
      maxH: maxH ?? this.maxH,
      static_: static_ ?? this.static_,
      isDraggable: isDraggable ?? this.isDraggable,
      isResizable: isResizable ?? this.isResizable,
      resizeHandles: resizeHandles ?? this.resizeHandles,
      isBounded: isBounded ?? this.isBounded,
      moved: moved ?? this.moved,
    );
  }
}

/// 布局 = 项列表（只读语义，用 List<LayoutItem>）
typedef Layout = List<LayoutItem>;

/// 像素位置与尺寸（RGL Position）
class Position {
  const Position({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });
  final double left;
  final double top;
  final double width;
  final double height;
}

/// 拖拽事件数据（RGL GridDragEvent）
class GridDragEvent {
  const GridDragEvent({
    required this.newPosition,
  });
  final ({double left, double top}) newPosition;
}

/// 缩放事件数据（RGL GridResizeEvent）
class GridResizeEvent {
  const GridResizeEvent({
    required this.size,
    required this.handle,
  });
  final (double width, double height) size;
  final ResizeHandleAxis handle;
}

/// 网格配置（RGL GridConfig）
class GridConfig {
  const GridConfig({
    this.cols = 12,
    this.rowHeight = 150,
    this.margin = const [10, 10],
    this.containerPadding,
    this.maxRows = 999,
  });
  final int cols;
  final double rowHeight;
  final List<double> margin;
  final List<double>? containerPadding;
  final int maxRows;
}

/// 拖拽配置（RGL DragConfig）
class DragConfig {
  const DragConfig({
    this.enabled = true,
    this.bounded = false,
    this.handle,
    this.cancel,
    this.threshold = 3,
  });
  final bool enabled;
  final bool bounded;
  final String? handle;
  final String? cancel;
  final int threshold;
}

/// 缩放配置（RGL ResizeConfig）
class ResizeConfig {
  const ResizeConfig({
    this.enabled = true,
    this.handles = const [ResizeHandleAxis.se],
  });
  final bool enabled;
  final List<ResizeHandleAxis> handles;
}

/// 紧凑类型（RGL CompactType）
enum CompactType {
  vertical,
  horizontal,
  none,
}

/// 默认断点名称
typedef DefaultBreakpoints = String; // "lg" | "md" | "sm" | "xs" | "xxs"

/// 断点 → 最小宽度（像素）
typedef Breakpoints<T extends String> = Map<T, int>;

/// 断点 → 列数
typedef BreakpointCols<T extends String> = Map<T, int>;

/// 断点 → 布局
typedef ResponsiveLayouts<T extends String> = Map<T, Layout>;

/// 默认断点
const Map<String, int> defaultBreakpoints = {
  'lg': 1200,
  'md': 996,
  'sm': 768,
  'xs': 480,
  'xxs': 0,
};

/// 默认每断点列数
const Map<String, int> defaultCols = {
  'lg': 12,
  'md': 10,
  'sm': 6,
  'xs': 4,
  'xxs': 2,
};

/// 紧凑器：对 layout 做紧凑并返回（可原地修改或返回新列表）
abstract class Compactor {
  CompactType get type;
  bool get allowOverlap;
  List<LayoutItem> compact(List<LayoutItem> layout, int cols);
}
