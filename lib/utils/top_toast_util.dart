import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

/// Toast 工具类
/// 提供统一的 Toast 提示功能
class TopToastUtil {
  /// 显示自定义 Toast
  ///
  /// [context] BuildContext
  /// [icon] 图标
  /// [iconColor] 图标颜色
  /// [title] 标题
  /// [description] 描述
  /// [duration] 自动关闭时长，默认 3 秒
  static void showCustom({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    Duration duration = const Duration(seconds: 3),
  }) {
    toastification.showCustom(
      context: context,
      alignment: Alignment.topCenter,
      autoCloseDuration: duration,
      builder: (context, cancel) {
        return Center(
          child: Container(
            margin: const EdgeInsets.only(top: 8),
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D2D), // 深灰色背景
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle),
                  child: Icon(icon, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Visibility(
                        visible: title.isNotEmpty,
                        child: Text(
                          title,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                      Visibility(
                        visible: description.isNotEmpty,
                        child: Text(
                          description,
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 显示成功 Toast
  static void showSuccess({
    required BuildContext context,
    required String title,
    required String description,
    Duration duration = const Duration(seconds: 3),
  }) {
    showCustom(
      context: context,
      icon: Icons.check,
      iconColor: Colors.green,
      title: title,
      description: description,
      duration: duration,
    );
  }

  /// 显示错误 Toast
  static void showError({
    required BuildContext context,
    required String title,
    required String description,
    Duration duration = const Duration(seconds: 5),
  }) {
    showCustom(
      context: context,
      icon: Icons.close,
      iconColor: Colors.red,
      title: title,
      description: description,
      duration: duration,
    );
  }

  /// 显示信息 Toast
  static void showInfo({
    required BuildContext context,
    required String title,
    required String description,
    Duration duration = const Duration(seconds: 3),
  }) {
    showCustom(
      context: context,
      icon: Icons.info,
      iconColor: Colors.blue,
      title: title,
      description: description,
      duration: duration,
    );
  }

  /// 显示警告 Toast
  static void showWarning({
    required BuildContext context,
    required String title,
    required String description,
    Duration duration = const Duration(seconds: 3),
  }) {
    showCustom(
      context: context,
      icon: Icons.warning,
      iconColor: Colors.orange,
      title: title,
      description: description,
      duration: duration,
    );
  }
}
