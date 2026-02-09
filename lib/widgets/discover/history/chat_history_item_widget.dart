import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../stores/chat_history_store.dart';
import 'rename_dialog.dart';

/// 与 TSX ChatHistoryItem 一致：单条会话项，支持 Rename/Delete 菜单与模糊遮罩
class ChatHistoryItemWidget extends StatefulWidget {
  const ChatHistoryItemWidget({
    super.key,
    required this.conversation,
    required this.onClick,
    this.isActive = false,
    this.isBlurred = false,
    required this.onDelete,
    required this.onRename,
  });

  final ConversationItem conversation;
  final VoidCallback onClick;
  final bool isActive;
  final bool isBlurred;
  final Future<bool> Function(int id) onDelete;
  final Future<bool> Function(int id, String title) onRename;

  @override
  State<ChatHistoryItemWidget> createState() => _ChatHistoryItemWidgetState();
}

class _ChatHistoryItemWidgetState extends State<ChatHistoryItemWidget> {
  Future<void> _handleDelete() async {
    await widget.onDelete(widget.conversation.id);
  }

  void _openRenameDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => RenameDialog(
        conversation: widget.conversation,
        onClose: () => Navigator.of(ctx).pop(),
        onRename: widget.onRename,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayText = widget.conversation.title;

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.isBlurred ? null : widget.onClick,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.isActive
                      ? const Color(0xFF171717).withOpacity(0.05)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayText,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF374151),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!widget.isBlurred)
                      PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 140),
                        icon: const Icon(Icons.more_horiz, size: 16, color: Color(0xFF6B7280)),
                        onSelected: (value) {
                          if (value == 'rename') _openRenameDialog();
                          if (value == 'delete') _handleDelete();
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem<String>(
                            value: 'rename',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 16, color: Color(0xFF374151)),
                                SizedBox(width: 10),
                                Text('Rename', style: TextStyle(fontSize: 14, color: Color(0xFF374151))),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, size: 16, color: Color(0xFFDC2626)),
                                SizedBox(width: 10),
                                Text('Delete', style: TextStyle(fontSize: 14, color: Color(0xFFDC2626))),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (widget.isBlurred)
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                  child: Container(
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
