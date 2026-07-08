import 'package:dinq_app/theme/dinq_tokens.dart';
import 'package:dinq_app/utils/color_util.dart';
import 'package:dinq_app/widgets/common/dinq_nav_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class DefaultAppBar extends AppBar {
  DefaultAppBar(
    BuildContext context, {
    super.key,
    Color? backgroundColor,
    super.bottom,
    super.elevation = 0,
    super.scrolledUnderElevation = 0,
    String? titleString,
    TextStyle? titleStyle,
    Widget? titleWidget,
    super.titleSpacing,
    super.centerTitle = true,
    bool isShowBack = true,
    VoidCallback? backCallback,
    Widget? leading,
    double? leadingWidth,
    super.actions,
  }) : super(
         backgroundColor: backgroundColor ?? DinqTokens.bgPage,
         // Android 状态栏透明+深色图标（statusBarColor 缺省会回退成系统灰底，
         // 与米白页面割裂）；statusBarBrightness 控制 iOS 图标颜色。
         systemOverlayStyle: const SystemUiOverlayStyle(
           statusBarColor: Colors.transparent,
           statusBarIconBrightness: Brightness.dark,
           statusBarBrightness: Brightness.light,
         ),
         title:
             titleWidget ??
             Text(
               titleString ?? "",
               style:
                   titleStyle ??
                   TextStyle(
                     color: ColorUtil.textColor,
                     fontSize: 16,
                     fontWeight: FontWeight.w600,
                     fontFamily: 'Geist',
                   ),
             ),
         leadingWidth: leadingWidth ?? 60,
         leading:
             leading ??
             (isShowBack
                 ? Padding(
                     padding: const EdgeInsets.only(left: 12),
                     child: Center(
                       child: DinqCircleBackButton(
                         onTap: () {
                           if (backCallback != null) {
                             backCallback();
                           } else if (context.canPop()) {
                             context.pop();
                           }
                         },
                       ),
                     ),
                   )
                 : Container()),
       );
}
