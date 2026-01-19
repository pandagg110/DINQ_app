import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../stores/messages_store.dart';
import '../../../widgets/layout/app_header.dart';

class AdminInboxPage extends StatefulWidget {
  const AdminInboxPage({super.key});

  @override
  State<AdminInboxPage> createState() => _AdminInboxPageState();
}

class _AdminInboxPageState extends State<AdminInboxPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<MessagesStore>().loadConversations());
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<MessagesStore>();

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
                  const Text('Inbox', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Expanded(
                    child: store.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                            itemCount: store.conversations.length,
                            itemBuilder: (context, index) {
                              final convo = store.conversations[index] as Map<String, dynamic>;
                              final id = convo['id']?.toString() ?? '';
                              return ListTile(
                                title: Text(convo['title']?.toString() ?? 'Conversation'),
                                subtitle: Text(convo['last_message']?.toString() ?? ''),
                                onTap: () => context.go('/admin/inbox/$id'),
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

