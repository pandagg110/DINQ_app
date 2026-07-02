import 'package:dinq_app/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../stores/messages_store.dart';
import '../../theme/dinq_tokens.dart';
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
    final buttonData = getTabBarData();
    final selectedIndex =
        currentTabType.pageIndex.clamp(0, buttonData.length - 1);
    final totalUnreadCount = context.watch<MessagesStore>().totalUnreadCount;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    // 对齐 `my_first_app` `_BottomNav`：平铺整条、背景与页面同为 bgPage 米白，
    // 顶部 0.5px 细线；激活=深色(textPrimary) fill 图标，未激活=浅灰(textTertiary) outline。
    return Container(
      decoration: const BoxDecoration(
        color: DinqTokens.bgPage,
        border: Border(top: BorderSide(color: DinqTokens.borderL, width: 0.5)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset > 0 ? bottomInset : 10),
      child: SizedBox(
        height: ConstantsTool.bottomTabHeight,
        child: Row(
          children: List.generate(buttonData.length, (index) {
            final data = buttonData[index];
            final isSelected = index == selectedIndex;
            final color =
                isSelected ? DinqTokens.textPrimary : DinqTokens.textTertiary;
            return Expanded(
              child: NormalButton(
                onTap: () => widget.onChanged(MainTabType.fromIndex(index)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        SvgPicture.asset(
                          isSelected ? data.selIconSvg! : data.iconSvg!,
                          width: 24,
                          height: 24,
                          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                        ),
                        if (data.pageType == MainTabType.inBox &&
                            totalUnreadCount > 0)
                          Positioned(
                            top: -6,
                            right: -10,
                            child: Container(
                              constraints: const BoxConstraints(minWidth: 18),
                              height: 18,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444),
                                borderRadius: BorderRadius.circular(9),
                                border: Border.all(
                                    color: DinqTokens.bgPage, width: 1.5),
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
                    const SizedBox(height: 4),
                    Text(
                      data.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        height: 1.0,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Geist',
                      ),
                    ),
                  ],
                ),
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
        pageType: MainTabType.search,
        title: "Search",
        iconName: "",
        selIconName: "",
        iconSvg: "assets/icons/nav-discover-outline.svg",
        selIconSvg: "assets/icons/nav-discover-fill.svg",
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
        iconName: "",
        selIconName: "",
        iconSvg: "assets/icons/nav-inbox-outline.svg",
        selIconSvg: "assets/icons/nav-inbox-fill.svg",
      ),
      MainTabModel(
        pageType: MainTabType.me,
        title: "My",
        iconName: "",
        selIconName: "",
        iconSvg: "assets/icons/nav-my-outline.svg",
        selIconSvg: "assets/icons/nav-my-fill.svg",
      ),
    ];
  }
}
