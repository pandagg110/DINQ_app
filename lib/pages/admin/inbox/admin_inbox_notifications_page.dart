import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../stores/notifications_store.dart';
import '../../../widgets/layout/app_header.dart';

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

  @override
  Widget build(BuildContext context) {
    final store = context.watch<NotificationsStore>();

    return Scaffold(
      body: Column(
        children: [
          const AppHeader(showAuthButtons: true),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Notifications', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Expanded(
                    child: store.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                            itemCount: store.notifications.length,
                            itemBuilder: (context, index) {
                              final notification = store.notifications[index] as Map<String, dynamic>;
                              return ListTile(
                                title: Text(notification['title']?.toString() ?? 'Notification'),
                                subtitle: Text(notification['message']?.toString() ?? ''),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

