import 'package:dinq_app/pages/admin/admin_search_page.dart';
import 'package:dinq_app/pages/admin/inbox/admin_inbox_page.dart';
import 'package:dinq_app/pages/landing/landing_page.dart';
import 'package:dinq_app/pages/me/me_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView(
          physics: const NeverScrollableScrollPhysics(),
          controller: _pageController,
          children: [
            KeepAliveWrapper(child: LandingPage()),
            KeepAliveWrapper(child: AdminSearchPage()),
            KeepAliveWrapper(child: AdminInboxPage()),
            KeepAliveWrapper(child: MePage()),
          ],
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: MainTabBottomView(
            onChanged: (mainTabType) {
              _clickTabButton(mainTabType);
            },
          ),
        ),
      ],
    );
  }

  void _clickTabButton(MainTabType mainTabType) {
    _pageController.jumpToPage(mainTabType.pageIndex);
  }
}
