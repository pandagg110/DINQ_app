import 'package:flutter/material.dart';

/// 全屏叠层页的右滑返回：左侧边缘跟手拖拽 + 系统返回（[PopScope]）。
/// 对齐 Shortlist 进入详情后的返回体验。
class SwipeBackPage extends StatefulWidget {
  const SwipeBackPage({
    super.key,
    required this.onBack,
    required this.child,
    this.enabled = true,
    this.shouldHandlePop,
  });

  final VoidCallback onBack;
  final Widget child;
  final bool enabled;

  /// 为 false 时不拦截系统返回（例如上层还有 Enrich 详情时）。
  final bool Function()? shouldHandlePop;

  @override
  State<SwipeBackPage> createState() => _SwipeBackPageState();
}

class _SwipeBackPageState extends State<SwipeBackPage>
    with SingleTickerProviderStateMixin {
  static const _dismissFraction = 0.28;
  static const _dismissVelocity = 900.0;
  static const _edgeWidth = 28.0;

  late final AnimationController _settleController;
  Animation<double>? _settleAnimation;
  double _dragDx = 0;
  bool _dragging = false;

  bool get _handlesPop =>
      widget.enabled && (widget.shouldHandlePop?.call() ?? true);

  @override
  void initState() {
    super.initState();
    _settleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(() {
        final animation = _settleAnimation;
        if (!_dragging && animation != null) {
          setState(() => _dragDx = animation.value);
        }
      });
  }

  @override
  void dispose() {
    _settleController.dispose();
    super.dispose();
  }

  void _animateBackToOrigin() {
    _settleAnimation = Tween<double>(begin: _dragDx, end: 0).animate(
      CurvedAnimation(parent: _settleController, curve: Curves.easeOutCubic),
    );
    _settleController
      ..value = 0
      ..forward().whenComplete(() {
        if (mounted && !_dragging) setState(() => _dragDx = 0);
      });
  }

  void _onEdgeDragStart(DragStartDetails details) {
    if (!widget.enabled) return;
    _dragging = true;
    _settleController.stop();
  }

  void _onEdgeDragUpdate(DragUpdateDetails details) {
    if (!widget.enabled || !_dragging) return;
    final width = MediaQuery.sizeOf(context).width;
    setState(() {
      _dragDx = (_dragDx + details.delta.dx).clamp(0.0, width);
    });
  }

  void _onEdgeDragEnd(DragEndDetails details) {
    if (!widget.enabled || !_dragging) {
      _dragging = false;
      return;
    }
    _dragging = false;
    final width = MediaQuery.sizeOf(context).width;
    final velocity = details.primaryVelocity ?? 0;
    final shouldDismiss =
        _dragDx > width * _dismissFraction || velocity > _dismissVelocity;
    if (shouldDismiss) {
      widget.onBack();
      return;
    }
    _animateBackToOrigin();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_handlesPop,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || !_handlesPop) return;
        widget.onBack();
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          Transform.translate(
            offset: Offset(_dragDx, 0),
            child: widget.child,
          ),
          // 左侧边缘热区：不与列表纵向滚动抢手势
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: _edgeWidth,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragStart: _onEdgeDragStart,
              onHorizontalDragUpdate: _onEdgeDragUpdate,
              onHorizontalDragEnd: _onEdgeDragEnd,
            ),
          ),
        ],
      ),
    );
  }
}
