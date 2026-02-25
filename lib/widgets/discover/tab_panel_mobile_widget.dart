import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../stores/search_store.dart';
import 'tab_bar_widget.dart';
import 'user_info_widget.dart';

/// 按候选人姓名去重，保留每组同名中第一个 tab，避免渲染出多个重复角色
List<SearchTabData> _deduplicateTabsByName(List<SearchTabData> tabs) {
  final seen = <String>{};
  return tabs.where((tab) {
    final name = tab.candidate['name']?.toString().trim() ?? '';
    if (name.isEmpty) return true;
    if (seen.contains(name)) return false;
    seen.add(name);
    return true;
  }).toList();
}

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
                    final displayTabs = _deduplicateTabsByName(searchStore.openTabs);
                    return Column(
                      children: [
                        // 顶部拖拽条
                        Padding(
                          padding: const EdgeInsets.only(top: 12, bottom: 8),
                          child: Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: const Color(0xFFBDBDBD),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                        TabBarWidget(displayTabs: displayTabs),
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
