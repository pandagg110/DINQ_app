import 'package:dinq_app/pages/admin/admin_mydinq_page.dart';
import 'package:dinq_app/pages/admin/admin_search_page.dart';
import 'package:dinq_app/pages/admin/admin_text_page1.dart';
import 'package:dinq_app/pages/admin/inbox/admin_inbox_page.dart';
import 'package:dinq_app/pages/discover/discover_page.dart';
import 'package:dinq_app/pages/me/me_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
  MainTabType _currentTabType = MainTabType.myDinq;

  @override
  void dispose() {
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
            KeepAliveWrapper(child: AdminMyDinqPage()),
            KeepAliveWrapper(child: DiscoverPage()),
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
              onChanged: (mainTabType) {
                setState(() => _currentTabType = mainTabType);
                _pageController.jumpToPage(mainTabType.pageIndex);
              },
            ),
          ),
      ],
    );
  }
}
