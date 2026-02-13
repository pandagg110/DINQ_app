import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../stores/chat_history_store.dart';
import 'rename_dialog.dart';

/// 遮罩路径：全屏减去 item 矩形，使选中 item 区域不模糊
class _BlurHoleClipper extends CustomClipper<Path> {
  _BlurHoleClipper(this.screenSize, this.itemRect);

  final Size screenSize;
  final Rect itemRect;

  @override
  Path getClip(Size size) {
    final screen = Rect.fromLTWH(0, 0, screenSize.width, screenSize.height);
    return Path.combine(PathOperation.difference, Path()..addRect(screen), Path()..addRect(itemRect));
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

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

  void _showContextMenu() {
    if (widget.isBlurred) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final overlay = Overlay.of(context);
    final overlayBox = overlay.context.findRenderObject() as RenderBox?;
    if (overlayBox == null) return;
    final screenSize = overlayBox.size;
    final itemTopLeft = box.localToGlobal(Offset.zero);
    const holeMargin = 2.0;
    final itemRect = Rect.fromLTWH(
      itemTopLeft.dx - holeMargin,
      itemTopLeft.dy - holeMargin,
      box.size.width + holeMargin * 2,
      box.size.height + holeMargin * 2,
    );
    const gap = 8.0;
    final menuTopLeft = box.localToGlobal(Offset(0, box.size.height + gap));
    const menuWidth = 160.0;
    const menuItemHeight = 48.0;

    // 同一 OverlayEntry：先模糊遮罩，再叠放自定义菜单，保证菜单在遮罩之上
    late final OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // 1. 模糊遮罩（挖空 item 区域）
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => overlayEntry.remove(),
              child: ClipPath(
                clipper: _BlurHoleClipper(screenSize, itemRect),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Container(
                    color: const Color(0x33000000),
                  ),
                ),
              ),
            ),
          ),
          // 2. 自定义菜单（在遮罩之上）
          Positioned(
            left: menuTopLeft.dx,
            top: menuTopLeft.dy,
            width: menuWidth,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () {
                      overlayEntry.remove();
                      _openRenameDialog();
                    },
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: SizedBox(
                      height: menuItemHeight,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 20, color: Color(0xFF171717)),
                            SizedBox(width: 12),
                            Text('Rename', style: TextStyle(fontSize: 14, color: Color(0xFF171717), fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      overlayEntry.remove();
                      _handleDelete();
                    },
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                    child: SizedBox(
                      height: menuItemHeight,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 20, color: Color(0xFFDC2626)),
                            SizedBox(width: 12),
                            Text('Delete', style: TextStyle(fontSize: 14, color: Color(0xFFDC2626), fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    overlay.insert(overlayEntry);
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
              onLongPress: widget.isBlurred ? null : _showContextMenu,
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
