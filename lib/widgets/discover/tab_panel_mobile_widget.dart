import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../stores/search_store.dart';
import 'tab_bar_widget.dart';
import 'user_info_widget.dart';

/// 底部滑出的 tab 面板，与 ChatHistoryMobileWidget 同方式：由 store 控制 isOpen，带滑入/遮罩动画
class TabPanelMobileWidget extends StatefulWidget {
  const TabPanelMobileWidget({
    super.key,
    required this.isOpen,
    required this.onClose,
  });

  final bool isOpen;
  final VoidCallback onClose;

  @override
  State<TabPanelMobileWidget> createState() => _TabPanelMobileWidgetState();
}

class _TabPanelMobileWidgetState extends State<TabPanelMobileWidget>
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
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(curved);
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(curved);
    if (widget.isOpen) _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) setState(() {});
    });
  }

  @override
  void didUpdateWidget(TabPanelMobileWidget oldWidget) {
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
    if (!widget.isOpen && _controller.status == AnimationStatus.dismissed) {
      return const SizedBox.shrink();
    }

    final height = MediaQuery.of(context).size.height * 0.85;

    return Stack(
      children: [
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
        Align(
          alignment: Alignment.bottomCenter,
          child: SlideTransition(
            position: _slideAnimation,
            child: Material(
              elevation: 8,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Container(
                width: double.infinity,
                height: height,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Consumer<SearchStore>(
                  builder: (context, searchStore, _) {
                    final activeTab = searchStore.getActiveTab();
                    return Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: Color(0xFFE5E5E5))),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  activeTab?.candidate['name']?.toString() ?? 'User Profile',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF171717),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: widget.onClose,
                              ),
                            ],
                          ),
                        ),
                        const TabBarWidget(),
                        if (activeTab != null)
                          Expanded(
                            child: UserInfoWidget(
                              tabData: activeTab,
                              onClose: widget.onClose,
                              resetKey: searchStore.activeTabId,
                            ),
                          )
                        else
                          const Expanded(
                            child: Center(child: Text('No tab selected')),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
