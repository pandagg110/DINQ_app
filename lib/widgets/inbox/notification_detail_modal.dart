import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../models/message_models.dart';

/// 通知详情弹窗
class NotificationDetailModal extends StatelessWidget {
  const NotificationDetailModal({
    super.key,
    required this.notification,
    required this.onClose,
  });

  final AppNotification notification;
  final VoidCallback onClose;

  static Future<void> show({
    required BuildContext context,
    required AppNotification notification,
    VoidCallback? onClose,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => NotificationDetailModal(
        notification: notification,
        onClose: () {
          Navigator.of(context).pop();
          onClose?.call();
        },
      ),
    );
  }

  String _formatTime(String timestamp) {
    final date = DateTime.tryParse(timestamp);
    if (date == null) return '';
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题区域
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                children: [
                  // 图标
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/icons/email-letter-square.svg',
                        width: 28,
                        height: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 标题
                  Expanded(
                    child: Text(
                      notification.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF171717),
                        fontFamily: 'Geist',
                      ),
                    ),
                  ),
                  // 关闭按钮
                  GestureDetector(
                    onTap: onClose,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: const Icon(Icons.close, size: 24, color: Color(0xFF6B7280)),
                    ),
                  ),
                ],
              ),
            ),

            // 内容
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  notification.content,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF4B5563),
                    height: 1.6,
                    fontFamily: 'Geist',
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 时间
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 6),
                  Text(
                    _formatTime(notification.createdAt),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                      fontFamily: 'Geist',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 确认按钮
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: onClose,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Geist',
                    ),
                  ),
                  child: const Text('OK'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
