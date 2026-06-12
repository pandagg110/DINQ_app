import 'dart:math';
import 'dart:ui';

import 'package:dinq_app/constants/app_constants.dart';
import 'package:dinq_app/utils/color_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../stores/messages_store.dart';
import '../../widgets/common/base_page.dart';
import 'main_tab_model.dart';

class MainTabBottomView extends StatefulWidget {
  /// 当前选中的 tab，由父组件传入，避免隐藏后重新创建时重置为默认 tab
  final MainTabType currentTabType;
  final ValueChanged<MainTabType> onChanged;

  const MainTabBottomView({
    super.key,
    required this.currentTabType,
    required this.onChanged,
  });

  @override
  State<MainTabBottomView> createState() => _MainTabBottomViewState();
}

class _MainTabBottomViewState extends State<MainTabBottomView> {
  @override
  Widget build(BuildContext context) {
    final currentTabType = widget.currentTabType;
    List<MainTabModel> buttonData = getTabBarData();
    final selectedIndex = currentTabType.pageIndex.clamp(0, buttonData.length - 1);
    final totalUnreadCount = context.watch<MessagesStore>().totalUnreadCount;
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
          left: 26,
          right: 26,
          bottom: max(26, MediaQuery.of(context).padding.bottom),
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(55),
          color: Color(0xC7FFFFFF), //Color(0xFFF7F7F7),
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
                  left: itemW * selectedIndex,
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
                          color: Color(0xC7FFFFFF), //Color(0xFFF7F7F7),
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
                    bool isSelected = index == selectedIndex;
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
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    buttonData[index].iconSvg != null
                                        ? SvgPicture.asset(
                                            isSelected
                                                ? buttonData[index].selIconSvg!
                                                : buttonData[index].iconSvg!,
                                            width: 24,
                                            height: 24,
                                            colorFilter: ColorFilter.mode(
                                              isSelected
                                                  ? const Color(0xFF1487FA)
                                                  : ColorUtil.textColor,
                                              BlendMode.srcIn,
                                            ),
                                          )
                                        : AssetImageView(
                                            isSelected
                                                ? buttonData[index].selIconName
                                                : buttonData[index].iconName,
                                            width: 24,
                                            fit: BoxFit.contain,
                                          ),
                                    // Inbox 未读数角标
                                    if (buttonData[index].pageType == MainTabType.inBox &&
                                        totalUnreadCount > 0)
                                      Positioned(
                                        top: -6,
                                        right: -10,
                                        child: Container(
                                          constraints: const BoxConstraints(minWidth: 18),
                                          height: 18,
                                          padding: const EdgeInsets.symmetric(horizontal: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEF4444),
                                            borderRadius: BorderRadius.circular(9),
                                            border: Border.all(color: Colors.white, width: 1.5),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            totalUnreadCount > 99
                                                ? '99+'
                                                : '$totalUnreadCount',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              height: 1.0,
                                              fontFamily: 'Geist',
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          final newType = MainTabType.fromIndex(index);
                          widget.onChanged(newType);
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
        pageType: MainTabType.search,
        title: "Search",
        iconName: "tab_discover",
        selIconName: "tab_discover_sel",
      ),
      MainTabModel(
        pageType: MainTabType.talentRadar,
        title: "Radar",
        iconName: "",
        selIconName: "",
        iconSvg: "assets/icons/nav-tasks-outline.svg",
        selIconSvg: "assets/icons/nav-tasks-fill.svg",
      ),
      MainTabModel(
        pageType: MainTabType.shortlist,
        title: "Shortlist",
        iconName: "",
        selIconName: "",
        iconSvg: "assets/icons/shortlist.svg",
        selIconSvg: "assets/icons/shortlist-fill.svg",
      ),
      MainTabModel(
        pageType: MainTabType.inBox,
        title: "Inbox",
        iconName: "tab_inbox",
        selIconName: "tab_inbox_sel",
      ),
      MainTabModel(
        pageType: MainTabType.me,
        title: "My",
        iconName: "tab_me",
        selIconName: "tab_me_sel",
      ),
    ];
  }
}
