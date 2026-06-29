import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

class TopToastUtil {
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
      builder: (context, item) {
        return Center(
          child: Container(
            margin: const EdgeInsets.only(top: 8, left: 20, right: 20),
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xCC171717),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (title.isNotEmpty)
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      if (description.isNotEmpty)
                        Text(
                          description,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                InkWell(
                  onTap: () => toastification.dismiss(item),
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(
                      Icons.close,
                      color: Color(0xFFBDBDBD),
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static void showSuccess({
    required BuildContext context,
    required String title,
    String description = '',
    Duration duration = const Duration(seconds: 3),
  }) {
    showCustom(
      context: context,
      icon: Icons.check_circle_rounded,
      iconColor: const Color(0xFF22C55E),
      title: title,
      description: description,
      duration: duration,
    );
  }

  static void showError({
    required BuildContext context,
    required String title,
    String description = '',
    Duration duration = const Duration(seconds: 5),
  }) {
    showCustom(
      context: context,
      icon: Icons.error_rounded,
      iconColor: const Color(0xFFEF4444),
      title: title,
      description: description,
      duration: duration,
    );
  }

  static void showInfo({
    required BuildContext context,
    required String title,
    String description = '',
    Duration duration = const Duration(seconds: 3),
  }) {
    showCustom(
      context: context,
      icon: Icons.info_rounded,
      iconColor: const Color(0xFF0EA5E9),
      title: title,
      description: description,
      duration: duration,
    );
  }

  static void showWarning({
    required BuildContext context,
    required String title,
    String description = '',
    Duration duration = const Duration(seconds: 3),
  }) {
    showCustom(
      context: context,
      icon: Icons.warning_rounded,
      iconColor: const Color(0xFFFACC15),
      title: title,
      description: description,
      duration: duration,
    );
  }
}
