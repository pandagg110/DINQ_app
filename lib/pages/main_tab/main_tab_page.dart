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
import '../../widgets/common/keep_alive_wrapper.dart';
import 'main_tab_bottom_view.dart';
import 'main_tab_model.dart';

class MainTabPage extends StatefulWidget {
  const MainTabPage({super.key});

  @override
  State<MainTabPage> createState() => _MainTabPageState();
}

class _MainTabPageState extends State<MainTabPage> {
  late final PageController _pageController = PageController();
  MainTabType _currentTabType = MainTabType.search;
  String? _lastRoutePath;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTabFromRoute();
  }

  void _syncTabFromRoute() {
    final path = GoRouterState.of(context).uri.path;
    if (path == _lastRoutePath) return;
    _lastRoutePath = path;

    if (path == '/' || path.startsWith('/search')) {
      _selectTab(MainTabType.search);
    }
  }

  void _selectTab(MainTabType tabType) {
    if (_currentTabType == tabType) return;
    setState(() => _currentTabType = tabType);
    _pageController.jumpToPage(tabType.pageIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mainStore = context.watch<MainStore>();
    return Stack(
      children: [
        PageView(
          physics: const NeverScrollableScrollPhysics(),
          controller: _pageController,
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
    );
  }
}
