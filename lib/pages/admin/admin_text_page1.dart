import 'package:flutter/material.dart';
import '../../utils/grid_layout_core.dart';
import '../../widgets/grid-layout/grid_layout_index.dart';

// ---------------------------------------------------------------------------
// Grid Layout 迁移组件 Demo（lib/widgets/grid-layout）
// 固定 12 列，6 个不同尺寸的格子，拖拽后自动紧凑重排
// ---------------------------------------------------------------------------

/// 初始布局：6 个不同尺寸的格子（w×h 分别为 2×2, 2×2, 2×2, 4×2, 2×2, 6×2）
List<LayoutItem> _initialLayout() => [
  LayoutItem(i: '1', x: 0, y: 0, w: 2, h: 2),
  LayoutItem(i: '2', x: 2, y: 0, w: 2, h: 2),
  LayoutItem(i: '3', x: 4, y: 0, w: 2, h: 2),
  LayoutItem(i: '4', x: 0, y: 2, w: 4, h: 2),
  LayoutItem(i: '5', x: 4, y: 2, w: 2, h: 2),
  LayoutItem(i: '6', x: 0, y: 4, w: 6, h: 2),
];

final List<Color> _tileColors = [
  Colors.blue.shade100,
  Colors.green.shade100,
  Colors.orange.shade100,
  Colors.purple.shade100,
  Colors.teal.shade100,
  Colors.amber.shade100,
];

class AdminTextPage extends StatefulWidget {
  const AdminTextPage({super.key});

  @override
  State<AdminTextPage> createState() => _AdminTextPageState();
}

class _AdminTextPageState extends State<AdminTextPage> {
  static const int _cols = 4;
  static const double _rowHeight = 80;
  static const double _marginX = 8;
  static const double _marginY = 8;

  late GridLayoutState _gridState;

  @override
  void initState() {
    super.initState();
    _gridState = GridLayoutState(
      layout: _initialLayout(),
      cols: _cols,
      onLayoutChange: (_) => setState(() {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Grid Layout Demo')),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                '固定 12 列，6 个不同尺寸（2×2、4×2、6×2 等）。拖拽可移动，松手后紧凑重排。',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // 扣除左右 padding，让网格真正占满父容器可用宽度
                  const horizontalPadding = 12.0 * 2;
                  final w = (constraints.maxWidth - horizontalPadding).clamp(
                    1.0,
                    double.infinity,
                  );
                  if (w <= 0) return const SizedBox();
                  final params = GridLayoutParams(
                    containerWidth: w,
                    cols: _cols,
                    rowHeight: _rowHeight,
                    marginX: _marginX,
                    marginY: _marginY,
                  );
                  return ListenableBuilder(
                    listenable: _gridState,
                    builder: (context, _) {
                      return SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: GridLayoutWidget(
                            state: _gridState,
                            params: params,
                            itemBuilder: (context, item) {
                              final idx = int.tryParse(item.i) ?? 0;
                              final color =
                                  _tileColors[idx % _tileColors.length];
                              return Container(
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.shade400,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    '${item.i}\n${item.w}×${item.h}',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
