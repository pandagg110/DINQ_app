import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../stores/messages_store.dart';
import '../../../widgets/layout/app_header.dart';

class AdminInboxConversationPage extends StatefulWidget {
  const AdminInboxConversationPage({super.key, required this.conversationId});

  final String conversationId;

  @override
  State<AdminInboxConversationPage> createState() => _AdminInboxConversationPageState();
}

class _AdminInboxConversationPageState extends State<AdminInboxConversationPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<MessagesStore>().loadMessages(widget.conversationId));
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<MessagesStore>();
    final messages = store.messagesByConversation[widget.conversationId] ?? [];

    return Scaffold(
      body: Column(
        children: [
          const AppHeader(showAuthButtons: true),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Conversation ${widget.conversationId}',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: store.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index] as Map<String, dynamic>;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(message['sender']?.toString() ?? 'User',
                                      style: const TextStyle(fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Text(message['content']?.toString() ?? ''),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

