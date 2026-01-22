import 'package:dinq_app/utils/color_util.dart';
import 'package:dinq_app/widgets/common/base_page.dart';
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
    super.leadingWidth,
    super.actions,
  }) : super(
         backgroundColor: backgroundColor ?? Colors.white,
         systemOverlayStyle: const SystemUiOverlayStyle(statusBarBrightness: Brightness.light),
         title:
             titleWidget ??
             Text(
               titleString ?? "",
               style:
                   titleStyle ??
                   TextStyle(color: ColorUtil.textColor, fontSize: 16, fontWeight: FontWeight.w600),
             ),
         leading:
             leading ??
             (isShowBack
                 ? IconButton(
                     highlightColor: Colors.transparent,
                     splashColor: Colors.transparent,
                     icon: Padding(
                       padding: EdgeInsets.all(4),
                       child: AssetImageView("nav_back", width: 20, height: 20),
                     ),
                     onPressed: () {
                       if (backCallback != null) {
                         backCallback();
                       } else {
                         // Navigator.of(context).pop();
                         if (context.canPop()) {
                           context.pop();
                         } else {
                           // context.go("/");
                         }
                       }
                     },
                   )
                 : Container()),
       );
}
