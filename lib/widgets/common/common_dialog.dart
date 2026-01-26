import 'package:dinq_app/utils/color_util.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'base_page.dart';

class CommonDialogGetxTool {
  static Future<bool?> showAlert({
    required BuildContext context,
    required Widget customAlert,
    Color? barrierColor,
    bool barrierDismissible = true,
    bool useSafeArea = true,
  }) {
    return showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return customAlert;
      },
      useSafeArea: useSafeArea,
      barrierColor: barrierColor,
      barrierDismissible: barrierDismissible,
    );
  }

  static Future<bool?> showBottomSheet({
    required BuildContext context,
    List<(String, VoidCallback?)>? titles,
    Widget? customChild,
    Color? maskBgColor,
    double topMargin = 0,
    double radius = 15.0,
    bool hasBottomMargin = false,
    bool hasHorMargin = false,
    bool handleKeyboard = false,
    bool enableDrag = true,
    bool isDismissible = true,
    Duration? enterBottomSheetDuration,
    Duration? exitBottomSheetDuration,
  }) {
    Widget? child = customChild;
    if ((titles?.length ?? 0) > 0) {
      child = SizedBox(
        height: titles!.length * 55 + (titles.length - 1) * 0.5,
        child: ListView.builder(
          itemCount: titles.length,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (BuildContext itemContext, int index) {
            List<Widget> widgets = [
              SizedBox(
                height: 55,
                child: Center(
                  child: Text(
                    titles[index].$1,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, height: 1, color: ColorUtil.textColor),
                  ),
                ),
              ),
            ];
            if (index != titles.length - 1) {
              widgets.add(
                Container(
                  margin: const EdgeInsets.only(left: 36, right: 36),
                  height: 0.5,
                  color: Colors.grey,
                ),
              );
            }
            return NormalButton(
              onTap: () {
                CommonDialogGetxTool.closeDialog(context);
                if (titles[index].$2 != null) {
                  titles[index].$2!();
                }
              },
              child: Column(children: widgets),
            );
          },
        ),
      );
    } else {
      child = customChild;
    }
    return showModalBottomSheet(
      context: context,
      builder: (ctl) {
        return Container(
          color: Colors.transparent,
          margin: EdgeInsets.only(top: topMargin, bottom: 0),
          child: AnimatedPadding(
            padding: EdgeInsets.zero,
            duration: const Duration(milliseconds: 100),
            child: Container(
              margin: EdgeInsets.only(
                left: hasHorMargin ? 16 : 0,
                right: hasHorMargin ? 16 : 0,
                bottom: hasBottomMargin
                    ? (MediaQuery.of(context).padding.bottom == 0
                          ? 20
                          : MediaQuery.of(context).padding.bottom)
                    : 0,
              ),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: hasBottomMargin == true
                    ? BorderRadius.all(Radius.circular(radius))
                    : BorderRadius.only(
                        topLeft: Radius.circular(radius),
                        topRight: Radius.circular(radius),
                      ),
              ),
              child: child ?? Container(),
            ),
          ),
        );
      },
      isScrollControlled: true,
      barrierColor: maskBgColor ?? Color(0x65000000),
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      useRootNavigator: true,
      shape: RoundedRectangleBorder(
        borderRadius: hasBottomMargin == false
            ? BorderRadius.only(topLeft: Radius.circular(radius), topRight: Radius.circular(radius))
            : BorderRadius.all(Radius.circular(radius)),
      ),
    );
  }

  static void closeDialog(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    }
  }
}

class BaseBottomSheet extends StatelessWidget {
  final Widget child;

  const BaseBottomSheet({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        Container(
          width: 36,
          height: 5,
          decoration: BoxDecoration(
            color: const Color(0xFF3C3C43).withAlpha((255 * 0.3).toInt()),
            borderRadius: BorderRadius.circular(2.5),
          ),
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }
}
