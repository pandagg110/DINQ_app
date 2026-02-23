// ---------------------------------------------------------------------------
// 从 react-grid-layout/core/responsive 迁移：断点与响应式布局生成
// ---------------------------------------------------------------------------

import 'grid_layout_types.dart';
import 'grid_layout_core.dart' as core;

/// 按宽度升序排列的断点名
List<String> sortBreakpoints(Map<String, int> breakpoints) {
  final keys = breakpoints.keys.toList();
  keys.sort((a, b) => (breakpoints[a] ?? 0).compareTo(breakpoints[b] ?? 0));
  return keys;
}

/// 根据宽度得到当前断点（取满足 width > breakpoint 的最大断点）
/// width <= 0 时返回最大断点，避免首帧用 2 列把尺寸压扁
String getBreakpointFromWidth(Map<String, int> breakpoints, double width) {
  final sorted = sortBreakpoints(breakpoints);
  if (sorted.isEmpty) return 'lg';
  if (width <= 0) return sorted.last;
  var matching = sorted.first;
  for (final name in sorted) {
    if (width > (breakpoints[name] ?? 0)) matching = name;
  }
  return matching;
}

/// 某断点对应的列数
int getColsFromBreakpoint(String breakpoint, Map<String, int> cols) {
  final c = cols[breakpoint];
  if (c == null) return 12;
  return c;
}

/// 将 layout 适配到列数：只限制 w 不超过 cols、x 不越界，不把 w 强制改成 cols，以保留尺寸差异
void fitLayoutToCols(List<LayoutItem> layout, int cols) {
  for (final l in layout) {
    l.w = l.w.clamp(1, cols);
    l.x = l.x.clamp(0, cols - l.w);
  }
}

/// 查找或生成某断点的 layout；若不存在则从更大断点克隆并 compact
List<LayoutItem> findOrGenerateResponsiveLayout(
  Map<String, List<LayoutItem>> layouts,
  Map<String, int> breakpoints,
  String breakpoint,
  String lastBreakpoint,
  int cols,
  Compactor compactor,
) {
  final existing = layouts[breakpoint];
  if (existing != null && existing.isNotEmpty) {
    return core.cloneLayout(existing);
  }

  final sorted = sortBreakpoints(breakpoints);
  final idx = sorted.indexOf(breakpoint);
  List<LayoutItem>? layout = layouts[lastBreakpoint];
  if (idx >= 0) {
    for (var i = idx; i < sorted.length; i++) {
      final b = sorted[i];
      final l = layouts[b];
      if (l != null && l.isNotEmpty) {
        layout = l;
        break;
      }
    }
  }

  final cloned = core.cloneLayout(layout ?? []);
  // 从大断点生成时只做「按列数适配」，保留 w/h 差异，避免 correctBounds 把 w 全改成 cols
  fitLayoutToCols(cloned, cols);
  return compactor.compact(cloned, cols);
}
