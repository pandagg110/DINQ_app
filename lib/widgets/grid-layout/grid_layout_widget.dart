// ---------------------------------------------------------------------------
// 等价 RGL GridLayout：根据 layout 与 params 渲染网格，每格为 GridItemWidget
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import '../../utils/grid_layout_core.dart';
import 'grid_layout_types.dart';
import 'grid_layout_state.dart';
import 'grid_layout_core.dart' as core;
import 'grid_item_widget.dart';

/// 网格布局主组件：使用 [state] 的 layout 与回调，[itemBuilder] 为每项构建内容
class GridLayoutWidget extends StatelessWidget {
  const GridLayoutWidget({
    super.key,
    required this.state,
    required this.params,
    required this.itemBuilder,
  });

  final GridLayoutState state;
  final GridLayoutParams params;
  final Widget Function(BuildContext context, LayoutItem item) itemBuilder;

  @override
  Widget build(BuildContext context) {
    final layout = state.layout;
    final rowHeight = params.rowHeight;
    final marginY = params.marginY;
    final containerHeightRows = core.bottom(layout);
    final rowStep = rowHeight + marginY;
    final totalHeight = params.containerPaddingY * 2 +
        containerHeightRows * rowStep -
        (containerHeightRows > 0 ? marginY : 0);

    return SizedBox(
      height: totalHeight.clamp(0, double.infinity),
      width: params.containerWidth,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final item in layout)
            GridItemWidget(
              key: ValueKey(item.i),
              item: item,
              params: params,
              onDragStart: () => state.onDragStart(item.i, item.x, item.y),
              onDragUpdate: (x, y) => state.onDrag(item.i, x, y),
              onDragEnd: (x, y) => state.onDragStop(item.i, x, y),
              child: itemBuilder(context, item),
            ),
        ],
      ),
    );
  }
}
