import 'package:flutter/material.dart';

import '../../../../stores/chat_history_store.dart';
import 'conversation_type_config.dart';
import 'delete_conversation_confirm_dialog.dart';

/// 与 TSX MobileSearchHistory 列表项一致：类型图标 + 标题 + More 菜单删除
class ChatHistoryItemWidget extends StatelessWidget {
  const ChatHistoryItemWidget({
    super.key,
    required this.conversation,
    required this.onClick,
    this.isActive = false,
    this.isBlurred = false,
    required this.onDelete,
  });

  final ConversationItem conversation;
  final VoidCallback onClick;
  final bool isActive;
  final bool isBlurred;
  final Future<bool> Function(Object id) onDelete;

  Future<void> _confirmDelete(BuildContext context) async {
    final id = conversation.id;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      builder: (ctx) => DeleteConversationConfirmDialog(
        onCancel: () => Navigator.of(ctx, rootNavigator: true).pop(false),
        onConfirm: () => Navigator.of(ctx, rootNavigator: true).pop(true),
      ),
    );
    if (confirmed != true) return;

    final ok = await onDelete(id);
    if (ok == false && messenger != null && context.mounted) {
      messenger.showSnackBar(
        const SnackBar(content: Text('删除失败，请重试')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayText =
        conversation.title.isNotEmpty ? conversation.title : 'Untitled';
    final typeIcon = conversationTypeIcon(conversation.type);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: isActive ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: isBlurred ? null : onClick,
          borderRadius: BorderRadius.circular(12),
          child: Opacity(
            opacity: isBlurred ? 0.45 : 1,
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                    child: Row(
                      children: [
                        Icon(
                          typeIcon,
                          size: 16,
                          color: kConversationTypeIconColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            displayText,
                            style: const TextStyle(
                              fontFamily: 'Geist',
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF171717),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (!isBlurred)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      offset: const Offset(0, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      icon: const Icon(
                        Icons.more_horiz,
                        size: 16,
                        color: Color(0xFFB5B3AE),
                      ),
                      onSelected: (value) {
                        if (value == 'delete') {
                          _confirmDelete(context);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem<String>(
                          value: 'delete',
                          height: 40,
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                size: 14,
                                color: Colors.red.shade600,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.red.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
