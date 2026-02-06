import 'package:dinq_app/widgets/common/base_page.dart';
import 'package:dinq_app/widgets/common/default_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../models/message_models.dart';
import '../../../stores/notifications_store.dart';
import '../../../widgets/inbox/notification_detail_modal.dart';

/// 通知列表页面
class AdminInboxNotificationsPage extends StatefulWidget {
  const AdminInboxNotificationsPage({super.key});

  @override
  State<AdminInboxNotificationsPage> createState() => _AdminInboxNotificationsPageState();
}

class _AdminInboxNotificationsPageState extends State<AdminInboxNotificationsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<NotificationsStore>().loadNotifications());
  }

  String _formatTime(String timestamp) {
    final date = DateTime.tryParse(timestamp);
    if (date == null) return '';

    final now = DateTime.now();
    final diff = now.difference(date);
    final days = diff.inDays;

    if (days == 0 && date.day == now.day) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    if (days == 1) return 'Yesterday';
    if (days <= 7) return '$days days ago';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  Future<void> _handleNotificationClick(AppNotification notification) async {
    final store = context.read<NotificationsStore>();

    // 通过 store 标记本地已读 + 调用后端详情接口
    try {
      await store.loadNotificationDetail(notification.id);
    } catch (_) {}

    if (mounted) {
      await NotificationDetailModal.show(
        context: context,
        notification: notification,
        onClose: () {
          // 如果通知有 URL metadata，可以跳转
          if (notification.metadata != null && notification.metadata!['url'] != null) {
            context.push(notification.metadata!['url'].toString());
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<NotificationsStore>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: DefaultAppBar(
        context,
        titleString: "Notifications",
        actions: [
          // 全部已读按钮
          NormalButton(
            onTap: () => store.markAllRead(),
            child: Row(
              children: [
                Icon(Icons.check_box_outlined, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'All read',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                    fontFamily: 'Geist',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // 通知列表
          Expanded(
            child: store.isLoading
                ? const Center(child: CircularProgressIndicator())
                : store.notifications.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: store.notifications.length,
                    itemBuilder: (context, index) =>
                        _buildNotificationItem(store.notifications[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(AppNotification notification) {
    return InkWell(
      onTap: () => _handleNotificationClick(notification),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : const Color(0xFFEFF6FF),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 图标
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: notification.isRead ? const Color(0xFFF3F4F6) : const Color(0xFFE0EDFF),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.mail_outline, size: 22, color: Color(0xFF4B5563)),
              ),
            ),
            const SizedBox(width: 16),

            // 内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF171717),
                            fontFamily: 'Geist',
                          ),
                        ),
                      ),
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
                  const SizedBox(height: 4),
                  Text(
                    notification.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                      height: 1.5,
                      fontFamily: 'Geist',
                    ),
                  ),
                ],
              ),
            ),

            // 未读指示器
            if (!notification.isRead)
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'No notifications',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
              fontFamily: 'Geist',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "You're all caught up!",
            style: TextStyle(fontSize: 14, color: Colors.grey[400], fontFamily: 'Geist'),
          ),
        ],
      ),
    );
  }
}
