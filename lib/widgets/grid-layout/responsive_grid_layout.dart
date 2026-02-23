// ---------------------------------------------------------------------------
// 等价 RGL ResponsiveGridLayout：按宽度选断点，用当前 layout/cols 渲染 GridLayout
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import '../../utils/grid_layout_core.dart';
import 'grid_layout_types.dart';
import 'grid_layout_state.dart';
import 'grid_layout_widget.dart';
import 'responsive_layout_state.dart';
import 'width_provider.dart';

/// 响应式网格布局：根据 [width] 选择断点与 layout，内部维护 GridLayoutState 并同步
class ResponsiveGridLayout extends StatefulWidget {
  const ResponsiveGridLayout({
    super.key,
    required this.width,
    required this.itemBuilder,
    this.breakpoints = defaultBreakpoints,
    this.cols = defaultCols,
    this.layouts,
    this.rowHeight = 150,
    this.margin = const [10.0, 10.0],
    this.containerPadding,
    this.onLayoutChange,
    this.onBreakpointChange,
  });

  final double width;
  final Widget Function(BuildContext context, LayoutItem item) itemBuilder;
  final Map<String, int> breakpoints;
  final Map<String, int> cols;
  final Map<String, List<LayoutItem>>? layouts;
  final double rowHeight;
  final List<double> margin;
  final List<double>? containerPadding;
  final void Function(Map<String, List<LayoutItem>> layouts)? onLayoutChange;
  final void Function(String breakpoint, int cols)? onBreakpointChange;

  @override
  State<ResponsiveGridLayout> createState() => _ResponsiveGridLayoutState();
}

class _ResponsiveGridLayoutState extends State<ResponsiveGridLayout> {
  late ResponsiveLayoutState _responsiveState;
  late GridLayoutState _gridState;

  @override
  void initState() {
    super.initState();
    _responsiveState = ResponsiveLayoutState(
      width: widget.width,
      breakpoints: widget.breakpoints,
      cols: widget.cols,
      layouts: widget.layouts,
      onBreakpointChange: widget.onBreakpointChange,
      onLayoutChange: (layout, layouts) {
        widget.onLayoutChange?.call(layouts);
      },
    );
    _gridState = _createGridState();
  }

  GridLayoutState _createGridState() {
    return GridLayoutState(
      layout: _responsiveState.layout,
      cols: _responsiveState.cols,
      onLayoutChange: (layout) {
        _responsiveState.setLayoutForBreakpoint(_responsiveState.breakpoint, layout);
      },
    );
  }

  @override
  void didUpdateWidget(ResponsiveGridLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    _responsiveState.setWidth(widget.width);
    if (_responsiveState.cols != _gridState.cols) {
      _gridState = _createGridState();
    } else {
      _gridState.setLayoutFromProps(_responsiveState.layout);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _responsiveState,
      builder: (context, _) {
        if (_responsiveState.cols != _gridState.cols) {
          _gridState = _createGridState();
        } else {
          _gridState.setLayoutFromProps(_responsiveState.layout);
        }
        final marginX = widget.margin.isNotEmpty ? widget.margin[0] : 10.0;
        final marginY = widget.margin.length > 1 ? widget.margin[1] : 10.0;
        final padX = widget.containerPadding?.isNotEmpty == true ? widget.containerPadding![0] : 0.0;
        final padY = (widget.containerPadding?.length ?? 0) > 1 ? widget.containerPadding![1] : 0.0;
        final params = GridLayoutParams(
          containerWidth: widget.width,
          cols: _responsiveState.cols,
          rowHeight: widget.rowHeight,
          marginX: marginX,
          marginY: marginY,
          containerPaddingX: padX,
          containerPaddingY: padY,
        );
        return ListenableBuilder(
          listenable: _gridState,
          builder: (context, _) {
            return GridLayoutWidget(
              state: _gridState,
              params: params,
              itemBuilder: widget.itemBuilder,
            );
          },
        );
      },
    );
  }
}

/// 带宽度测量的响应式网格（内部用 WidthProvider）
class ResponsiveGridLayoutWithWidth extends StatelessWidget {
  const ResponsiveGridLayoutWithWidth({
    super.key,
    required this.itemBuilder,
    this.breakpoints = defaultBreakpoints,
    this.cols = defaultCols,
    this.layouts,
    this.rowHeight = 150,
    this.margin = const [10.0, 10.0],
    this.containerPadding,
    this.onLayoutChange,
    this.onBreakpointChange,
  });

  final Widget Function(BuildContext context, LayoutItem item) itemBuilder;
  final Map<String, int> breakpoints;
  final Map<String, int> cols;
  final Map<String, List<LayoutItem>>? layouts;
  final double rowHeight;
  final List<double> margin;
  final List<double>? containerPadding;
  final void Function(Map<String, List<LayoutItem>> layouts)? onLayoutChange;
  final void Function(String breakpoint, int cols)? onBreakpointChange;

  @override
  Widget build(BuildContext context) {
    return WidthProvider(
      builder: (context, width) {
        return ResponsiveGridLayout(
          width: width,
          itemBuilder: itemBuilder,
          breakpoints: breakpoints,
          cols: cols,
          layouts: layouts,
          rowHeight: rowHeight,
          margin: margin,
          containerPadding: containerPadding,
          onLayoutChange: onLayoutChange,
          onBreakpointChange: onBreakpointChange,
        );
      },
    );
  }
}
