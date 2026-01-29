import 'dart:math';

import 'package:dinq_app/constants/app_constants.dart';
import 'package:dinq_app/utils/color_util.dart';
import 'package:flutter/material.dart';

import '../../widgets/common/base_page.dart';
import 'main_tab_model.dart';

class MainTabBottomView extends StatefulWidget {
  final ValueChanged<MainTabType> onChanged;

  const MainTabBottomView({super.key, required this.onChanged});

  @override
  State<MainTabBottomView> createState() => _MainTabBottomViewState();
}

class _MainTabBottomViewState extends State<MainTabBottomView> {
  // int selectedButtonIndex = 0;

  MainTabType _currentTabType = MainTabType.myDinq;

  set currentTabType(MainTabType value) {
    if (mounted && value != _currentTabType) {
      setState(() {
        _currentTabType = value;
      });
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<MainTabModel> buttonData = getTabBarData();
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white.withAlpha(0), Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Container(
        height: ConstantsTool.bottomTabHeight,
        margin: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: max(16, MediaQuery.of(context).padding.bottom),
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((255 * 0.16).toInt()),
              blurRadius: 20,
              offset: Offset(0, 0),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(buttonData.length, (index) {
            bool isSelected = index == _currentTabType.pageIndex;
            bool isTrade = index == 2;
            return Expanded(
              child: NormalButton(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: 2 + 24),
                          Text(
                            buttonData[index].title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isSelected ? Color(0xFF1487FA) : ColorUtil.textColor,
                              fontSize: 10,
                              height: 1.0,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Geist',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 13,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: AssetImageView(
                          isSelected ? buttonData[index].selIconName : buttonData[index].iconName,
                          width: 24,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  // if ((index == 4) && UserRepo.shared.currentUser == null) {
                  //   CYGetRouter.pushRoute(Routes.signIn);
                  //   return;
                  // }
                  MainTabType currentType = MainTabType.fromIndex(index);
                  currentTabType = currentType;
                  widget.onChanged.call(currentType);
                },
              ),
            );
          }),
        ),
      ),
    );
  }

  List<MainTabModel> getTabBarData() {
    return [
      MainTabModel(
        pageType: MainTabType.myDinq,
        title: "My DINQ",
        iconName: "tab_dinq",
        selIconName: "tab_dinq_sel",
      ),
      MainTabModel(
        pageType: MainTabType.discover,
        title: "Discover",
        iconName: "tab_discover",
        selIconName: "tab_discover_sel",
      ),
      MainTabModel(
        pageType: MainTabType.inBox,
        title: "Inbox",
        iconName: "tab_inbox",
        selIconName: "tab_inbox_sel",
      ),
      MainTabModel(
        pageType: MainTabType.me,
        title: "Me",
        iconName: "tab_me",
        selIconName: "tab_me_sel",
      ),
    ];
  }
}
