// ---------------------------------------------------------------------------
// 等价 react-grid-layout 的 WidthProvider HOC：提供容器宽度给子组件
// 子组件通过 builder 接收 width，用于 ResponsiveGridLayout 等
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';

/// 子组件构建器：接收当前容器宽度（像素）
typedef WidthProviderBuilder = Widget Function(BuildContext context, double width);

/// 提供测量后的容器宽度给 [builder]。
/// 用法：WidthProvider(builder: (context, width) => ResponsiveGridLayout(width: width, ...))
class WidthProvider extends StatelessWidget {
  const WidthProvider({
    super.key,
    required this.builder,
  });

  final WidthProviderBuilder builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return builder(context, width > 0 ? width : 0);
      },
    );
  }
}
