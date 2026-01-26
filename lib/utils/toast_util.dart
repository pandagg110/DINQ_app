import 'dart:async';

import 'package:dinq_app/utils/color_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
// import 'package:fluttertoast/fluttertoast.dart';

class ToastUtil {
  static Future<void> show(String content, {double duration = 2, bool dismissOnTap = false}) async {
    await dismiss();
    ToastUtil._config();
    EasyLoading.instance.contentPadding = const EdgeInsets.symmetric(
      vertical: 15.0,
      horizontal: 20.0,
    );
    return EasyLoading.showToast(
      content,
      duration: Duration(milliseconds: (duration * 1000).toInt()),
      dismissOnTap: dismissOnTap,
    );
  }

  static Future<void> showLoading({
    String? content,
    bool isWriteLoading = false,
    bool canTouch = false,
    bool dismissOnTap = false,
  }) async {
    await dismiss();
    ToastUtil._config(content: content);
    return EasyLoading.show(
      maskType: canTouch ? EasyLoadingMaskType.none : EasyLoadingMaskType.clear,
      dismissOnTap: dismissOnTap,
    );
  }

  static Future<void> dismiss() {
    final res = EasyLoading.dismiss();
    return res;
  }

  static void _config({String? content}) {
    EasyLoading.instance.maskColor = null;
    EasyLoading.instance.animationDuration = const Duration(milliseconds: 200);
    EasyLoading.instance.contentPadding = const EdgeInsets.symmetric(
      vertical: 0.0,
      horizontal: 0.0,
    );
    EasyLoading.instance.radius = 10;
    EasyLoading.instance.backgroundColor = Colors.black.withValues(alpha: 0.8);
    EasyLoading.instance.boxShadow = [];
    EasyLoading.instance.textColor = Colors.white;
    EasyLoading.instance.textStyle = const TextStyle(fontSize: 17, color: Colors.white);
    EasyLoading.instance.indicatorColor = ColorUtil.mainColor;
    EasyLoading.instance.indicatorWidget = _buildLoadingChild(content: content);
    EasyLoading.instance.loadingStyle = EasyLoadingStyle.custom;
  }

  static Widget _buildLoadingChild({String? content}) {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 22, bottom: 22),
      decoration: const BoxDecoration(
        borderRadius: BorderRadiusDirectional.all(Radius.circular(10)),
        color: Colors.transparent,
      ),
      constraints: const BoxConstraints(minWidth: 60, minHeight: 60, maxWidth: 250, maxHeight: 200),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          loadingView(),
          Visibility(
            visible: content?.isNotEmpty ?? false,
            child: Padding(
              padding: const EdgeInsets.only(top: 0),
              child: Text(
                content ?? "",
                maxLines: 100,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                  fontWeight: FontWeight.w400,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget loadingView({double size = 30, Color color = Colors.white}) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 3,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }

  /// 按钮上的转圈 loading
  static Widget loadingInButtonView({double size = 16, Color color = Colors.white}) {
    return Center(
      child: Container(width: size, height: size, color: color),
    );
  }
}

// /// 显示在原生视图上
// class NativeToastTool {
//   static void show(String text, {bool isShowLong = false}) {
//     try {
//       Fluttertoast.showToast(
//         msg: text,
//         gravity: ToastGravity.CENTER,
//         backgroundColor: Colors.black45,
//         textColor: Colors.white,
//         fontSize: 17.0,
//       );
//     } catch (err) {
//       if (kDebugMode) {
//         print(err);
//       }
//     }
//   }
// }
