import 'package:flutter/material.dart';
import '../../pages/search/chat_history_page.dart';

/// 左侧滑出的聊天历史弹框，内容为 ChatHistoryPage，带滑入动画
class ChatHistoryMobileWidget extends StatefulWidget {
  const ChatHistoryMobileWidget({
    super.key,
    required this.isOpen,
    required this.onClose,
  });

  final bool isOpen;
  final VoidCallback onClose;

  @override
  State<ChatHistoryMobileWidget> createState() => _ChatHistoryMobileWidgetState();
}

class _ChatHistoryMobileWidgetState extends State<ChatHistoryMobileWidget>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 280);

  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration);
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(curved);
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(curved);
    if (widget.isOpen) {
      _controller.forward();
    }
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) setState(() {});
    });
  }

  @override
  void didUpdateWidget(ChatHistoryMobileWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen && !oldWidget.isOpen) {
      _controller.forward();
    } else if (!widget.isOpen && oldWidget.isOpen) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 关闭且动画已结束再隐藏，否则保持显示以播放关闭动画
    if (!widget.isOpen &&
        _controller.status == AnimationStatus.dismissed) {
      return const SizedBox.shrink();
    }

    final width = MediaQuery.of(context).size.width * 0.85;

    return Stack(
      children: [
        // 半透明遮罩，渐隐动画，点击关闭
        Positioned.fill(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onClose,
              child: Container(color: Colors.black54),
            ),
          ),
        ),
        // 左侧面板，SlideTransition 实现从左侧滑入
        Align(
          alignment: Alignment.centerLeft,
          child: SlideTransition(
            position: _slideAnimation,
            child: Material(
              elevation: 8,
              child: SizedBox(
                width: width,
                height: MediaQuery.of(context).size.height,
                child: ChatHistoryPage(onClose: widget.onClose),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
