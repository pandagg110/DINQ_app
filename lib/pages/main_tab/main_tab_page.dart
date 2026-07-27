import 'package:dinq_app/pages/admin/inbox/admin_inbox_page.dart';
import 'package:dinq_app/pages/search/discover_page.dart';
import 'package:dinq_app/pages/me/me_page.dart';
import 'package:dinq_app/pages/shortlist/shortlist_page.dart';
import 'package:dinq_app/pages/talent_radar/talent_radar_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../stores/main_store.dart';
import '../../stores/shortlist_store.dart';
import '../../widgets/common/keep_alive_wrapper.dart';
import 'main_tab_bottom_view.dart';
import 'main_tab_model.dart';

class MainTabPage extends StatefulWidget {
  const MainTabPage({super.key});

  @override
  State<MainTabPage> createState() => _MainTabPageState();
}

class _MainTabPageState extends State<MainTabPage> {
  PageController? _pageController;
  MainTabType _currentTabType = MainTabType.search;
  String? _lastRoutePath;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final path = GoRouterState.of(context).uri.path;
    if (_pageController == null) {
      _currentTabType = _tabTypeForRoute(path);
      _pageController = PageController(initialPage: _currentTabType.pageIndex);
      _lastRoutePath = path;
      return;
    }
    _syncTabFromRoute();
  }

  MainTabType _tabTypeForRoute(String path) {
    if (path == '/me') return MainTabType.me;
    if (path == '/shortlist') return MainTabType.shortlist;
    if (path == '/' || path.startsWith('/search')) return MainTabType.search;
    return _currentTabType;
  }

  void _syncTabFromRoute() {
    final path = GoRouterState.of(context).uri.path;
    if (path == _lastRoutePath) return;
    _lastRoutePath = path;

    if (path == '/' || path.startsWith('/search')) {
      _selectTab(MainTabType.search);
    } else if (path == '/me') {
      _selectTab(MainTabType.me);
    } else if (path == '/shortlist') {
      _selectTab(MainTabType.shortlist);
    }
  }

  void _selectTab(MainTabType tabType) {
    if (_currentTabType == tabType) return;
    // KeepAlive 会保留子页 TextField 焦点，切 tab 时若不收起，
    // 再进 Shortlist 等页会突然弹出键盘并露出光标。
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _currentTabType = tabType);
    _jumpToTabPage(tabType.pageIndex);
    _refreshShortlistOnEnter(tabType);
  }

  /// QA: shortlist 数据丢失 —— ShortlistPage 被 KeepAlive 缓存，只在首次
  /// 进入时拉一次数据；而收藏弹窗（Add to shortlist）新建的文件夹/收藏不经过
  /// ShortlistStore，导致 shortlist 页永远停留在首次快照。对齐 web「每次进入
  /// shortlist 路由都重新拉取」：每次切到该 tab 强制刷新。
  void _refreshShortlistOnEnter(MainTabType tabType) {
    if (tabType != MainTabType.shortlist) return;
    final store = context.read<ShortlistStore>();
    // 首次进入由 ShortlistPage.initState -> initialize() 负责，避免双拉。
    if (!store.projectsLoaded) return;
    store.refreshAll();
  }

  void _jumpToTabPage(int pageIndex) {
    final controller = _pageController;
    if (controller == null) return;
    if (controller.hasClients) {
      controller.jumpToPage(pageIndex);
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !controller.hasClients) return;
      controller.jumpToPage(pageIndex);
    });
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mainStore = context.watch<MainStore>();
    final pageController = _pageController;
    if (pageController == null) {
      return const SizedBox.shrink();
    }
    return ColoredBox(
      color: const Color(0xFFFAF9F6),
      child: Stack(
        children: [
          PageView(
            physics: const NeverScrollableScrollPhysics(),
            controller: pageController,
            children: [
              KeepAliveWrapper(child: SearchPage()),
              KeepAliveWrapper(child: TalentRadarPage()),
              KeepAliveWrapper(child: ShortlistPage()),
              KeepAliveWrapper(child: AdminInboxPage()),
              KeepAliveWrapper(child: MePage()),
            ],
          ),
          if (mainStore.showBottomNav)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: MainTabBottomView(
                currentTabType: _currentTabType,
                onChanged: _selectTab,
              ),
            ),
        ],
      ),
    );
  }
}
