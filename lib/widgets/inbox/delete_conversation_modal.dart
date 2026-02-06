import 'package:flutter/material.dart';

/// 删除对话确认弹窗
class DeleteConversationModal extends StatefulWidget {
  const DeleteConversationModal({
    super.key,
    required this.conversationName,
    required this.onConfirm,
  });

  final String conversationName;
  final Future<void> Function() onConfirm;

  /// 显示删除确认弹窗
  static Future<void> show({
    required BuildContext context,
    required String conversationName,
    required Future<void> Function() onConfirm,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => DeleteConversationModal(
        conversationName: conversationName,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<DeleteConversationModal> createState() => _DeleteConversationModalState();
}

class _DeleteConversationModalState extends State<DeleteConversationModal> {
  bool _isDeleting = false;

  Future<void> _handleDelete() async {
    setState(() => _isDeleting = true);
    try {
      await widget.onConfirm();
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      // 保持弹窗打开
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
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
            // 标题和关闭按钮
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Delete Conversation',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF171717),
                        fontFamily: 'Geist',
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: const Icon(Icons.close, size: 24, color: Color(0xFF6B7280)),
                    ),
                  ),
                ],
              ),
            ),

            // 描述
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Are you sure you want to delete this conversation? All messages will be permanently deleted and cannot be recovered.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF4B5563),
                  height: 1.5,
                  fontFamily: 'Geist',
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 按钮
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  // 取消按钮
                  Expanded(
                    child: GestureDetector(
                      onTap: _isDeleting ? null : () => Navigator.of(context).pop(),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF171717), width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF171717),
                            fontFamily: 'Geist',
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 删除按钮
                  Expanded(
                    child: GestureDetector(
                      onTap: _isDeleting ? null : _handleDelete,
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _isDeleting ? 'Deleting...' : 'Delete',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                            fontFamily: 'Geist',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
