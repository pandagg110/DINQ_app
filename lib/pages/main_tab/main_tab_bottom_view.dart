import 'dart:math';
import 'dart:ui';

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
          borderRadius: BorderRadius.circular(55),
          color: Color(0xFFF7F7F7), //Colors.white.withAlpha((0.8 * 255).toInt()),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((255 * 0.16).toInt()),
              blurRadius: 20,
              offset: Offset(0, 0),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final itemW = constraints.maxWidth / buttonData.length;
            return Stack(
              children: [
                AnimatedPositioned(
                  left: itemW * _currentTabType.pageIndex,
                  top: 3,
                  bottom: 3,
                  duration: Duration(milliseconds: 200),
                  child: Stack(
                    children: [
                      Container(
                        width: itemW - 6,
                        margin: EdgeInsets.only(left: 3),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 1),
                          color: Color(0xFFF7F7F7),
                          borderRadius: BorderRadius.circular(55),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha((255 * 0.1).toInt()),
                              blurRadius: 5,
                              offset: Offset(0, 0),
                            ),
                          ],
                        ),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(40),
                        child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20)),
                      ),
                    ],
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: List.generate(buttonData.length, (index) {
                    bool isSelected = index == _currentTabType.pageIndex;
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
                              top: 10,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: AssetImageView(
                                  isSelected
                                      ? buttonData[index].selIconName
                                      : buttonData[index].iconName,
                                  width: 24,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          MainTabType currentType = MainTabType.fromIndex(index);
                          currentTabType = currentType;
                          widget.onChanged.call(currentType);
                        },
                      ),
                    );
                  }),
                ),
              ],
            );
          },
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
