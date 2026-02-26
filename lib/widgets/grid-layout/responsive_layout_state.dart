// ---------------------------------------------------------------------------
// 等价 useResponsiveLayout：按宽度选断点、当前 layout/cols、setLayoutForBreakpoint
// ---------------------------------------------------------------------------

import 'package:flutter/foundation.dart';
import 'grid_layout_types.dart';
import 'grid_layout_state.dart';
import 'responsive_utils.dart';

/// 响应式布局状态
class ResponsiveLayoutState extends ChangeNotifier {
  ResponsiveLayoutState({
    required double width,
    Map<String, int>? breakpoints,
    Map<String, int>? cols,
    Map<String, List<LayoutItem>>? layouts,
    this.compactor,
    this.onBreakpointChange,
    this.onLayoutChange,
  })  : _width = width,
        _breakpoints = breakpoints ?? defaultBreakpoints,
        _cols = cols ?? defaultCols,
        _layouts = Map.of(layouts ?? {}) {
    _updateFromWidth();
  }

  double _width;
  final Map<String, int> _breakpoints;
  final Map<String, int> _cols;
  final Map<String, List<LayoutItem>> _layouts;
  final Compactor? compactor;
  final void Function(String breakpoint, int cols)? onBreakpointChange;
  final void Function(List<LayoutItem> layout, Map<String, List<LayoutItem>> layouts)? onLayoutChange;

  String _breakpoint = 'lg';
  int _currentCols = 12;
  List<LayoutItem> _layout = [];

  double get width => _width;
  String get breakpoint => _breakpoint;
  int get cols => _currentCols;
  List<LayoutItem> get layout => _layout;
  Map<String, List<LayoutItem>> get layouts => Map.unmodifiable(_layouts);
  List<String> get sortedBreakpoints => sortBreakpoints(_breakpoints);

  void setWidth(double w) {
    if (_width == w) return;
    _width = w;
    _updateFromWidth();
    notifyListeners();
  }

  void _updateFromWidth() {
    final newBreakpoint = getBreakpointFromWidth(_breakpoints, _width);
    final newCols = getColsFromBreakpoint(newBreakpoint, _cols);
    final lastBp = _breakpoint;
    _breakpoint = newBreakpoint;
    _currentCols = newCols;
    _layout = findOrGenerateResponsiveLayout(
      _layouts,
      _breakpoints,
      newBreakpoint,
      lastBp,
      newCols,
      compactor ?? VerticalCompactor(),
    );
    onBreakpointChange?.call(newBreakpoint, newCols);
  }

  void setLayoutForBreakpoint(String breakpoint, List<LayoutItem> layout) {
    _layouts[breakpoint] = List.from(layout);
    if (breakpoint == _breakpoint) {
      _layout = List.from(layout);
    } else {
      _updateFromWidth();
    }
    onLayoutChange?.call(_layout, _layouts);
    notifyListeners();
  }

  void setLayouts(Map<String, List<LayoutItem>> newLayouts) {
    _layouts
      ..clear()
      ..addAll(newLayouts);
    _updateFromWidth();
    onLayoutChange?.call(_layout, _layouts);
    notifyListeners();
  }
}
