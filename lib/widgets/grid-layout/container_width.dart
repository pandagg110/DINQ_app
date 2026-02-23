// ---------------------------------------------------------------------------
// 等价 react-grid-layout 的 useContainerWidth / 容器宽度测量
// Flutter 用 LayoutBuilder 获取约束宽度并回调或提供给子组件
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';

/// 当容器宽度可用时回调（等价 useContainerWidth 的 setWidth）
typedef OnContainerWidth = void Function(double width);

/// 通过 [LayoutBuilder] 测量容器宽度并调用 [onWidth]。
/// 用于需要根据宽度计算列数或布局的场景。
class ContainerWidth extends StatelessWidget {
  const ContainerWidth({
    super.key,
    required this.onWidth,
    required this.child,
  });

  final OnContainerWidth onWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        if (w > 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) => onWidth(w));
        }
        return child;
      },
    );
  }
}
