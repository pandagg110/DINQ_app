import 'package:flutter/material.dart';

import '../../../../stores/chat_history_store.dart';
import 'conversation_type_config.dart';
import 'delete_conversation_confirm_dialog.dart';

/// 与 TSX MobileSearchHistory 列表项一致：类型图标 + 标题 + More 菜单删除
class ChatHistoryItemWidget extends StatefulWidget {
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

  @override
  State<ChatHistoryItemWidget> createState() => _ChatHistoryItemWidgetState();
}

class _ChatHistoryItemWidgetState extends State<ChatHistoryItemWidget> {
  static const Color _deleteRed = Color(0xFFDC2626);
  static const double _menuWidth = 128;

  final GlobalKey _moreButtonKey = GlobalKey();

  Future<void> _confirmDelete() async {
    final id = widget.conversation.id;
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

    final ok = await widget.onDelete(id);
    if (ok == false && messenger != null && mounted) {
      messenger.showSnackBar(
        const SnackBar(content: Text('删除失败，请重试')),
      );
    }
  }

  Future<void> _showDeleteMenu() async {
    final box = _moreButtonKey.currentContext?.findRenderObject() as RenderBox?;
    final overlayBox = Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (box == null || overlayBox == null || !box.hasSize) return;

    final buttonTopLeft = box.localToGlobal(Offset.zero, ancestor: overlayBox);
    final menuLeft = buttonTopLeft.dx + box.size.width - _menuWidth;
    final menuTop = buttonTopLeft.dy + box.size.height + 4;

    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(menuLeft, menuTop, _menuWidth, 0),
        Offset.zero & overlayBox.size,
      ),
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      constraints: const BoxConstraints(
        minWidth: _menuWidth,
        maxWidth: _menuWidth,
      ),
      items: const [
        PopupMenuItem<String>(
          value: 'delete',
          height: 40,
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(
                Icons.delete_outline,
                size: 14,
                color: _deleteRed,
              ),
              SizedBox(width: 8),
              Text(
                'Delete',
                style: TextStyle(
                  fontSize: 14,
                  color: _deleteRed,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (selected == 'delete' && mounted) {
      await _confirmDelete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayText = widget.conversation.title.isNotEmpty
        ? widget.conversation.title
        : 'Untitled';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: widget.isActive ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: widget.isBlurred ? null : widget.onClick,
          borderRadius: BorderRadius.circular(12),
          child: Opacity(
            opacity: widget.isBlurred ? 0.45 : 1,
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                    child: Row(
                      children: [
                        ConversationTypeIcon(type: widget.conversation.type),
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
                if (!widget.isBlurred)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Material(
                      key: _moreButtonKey,
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _showDeleteMenu,
                        borderRadius: BorderRadius.circular(8),
                        hoverColor: Colors.black.withValues(alpha: 0.05),
                        splashColor: Colors.black.withValues(alpha: 0.05),
                        child: const SizedBox(
                          width: 32,
                          height: 32,
                          child: Icon(
                            Icons.more_horiz,
                            size: 16,
                            color: Color(0xFFB5B3AE),
                          ),
                        ),
                      ),
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
