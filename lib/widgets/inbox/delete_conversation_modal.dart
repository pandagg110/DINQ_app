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

  /// 显示删除确认弹窗。成功删除返回 `true`，取消/关闭返回 `false`。
  static Future<bool> show({
    required BuildContext context,
    required String conversationName,
    required Future<void> Function() onConfirm,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => DeleteConversationModal(
        conversationName: conversationName,
        onConfirm: onConfirm,
      ),
    );
    return result ?? false;
  }

  @override
  State<DeleteConversationModal> createState() =>
      _DeleteConversationModalState();
}

class _DeleteConversationModalState extends State<DeleteConversationModal> {
  bool _isDeleting = false;

  Future<void> _handleDelete() async {
    if (_isDeleting) return;
    setState(() => _isDeleting = true);
    try {
      await widget.onConfirm();
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      // 保持弹窗打开，允许重试
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
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: _isDeleting
                    ? null
                    : () => Navigator.of(context).pop(false),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  margin: const EdgeInsets.only(
                    left: 12,
                    right: 12,
                    top: 12,
                    bottom: 4,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 24,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            ),
            const Text(
              'Delete Conversation',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF171717),
                fontFamily: 'Geist',
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Are you sure you want to delete this conversation?\n All messages will be permanently deleted and cannot be recovered.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF4B5563),
                  height: 1.5,
                  fontFamily: 'Geist',
                ),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _isDeleting
                          ? null
                          : () => Navigator.of(context).pop(false),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFFD8D8D8),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
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
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: _isDeleting ? null : _handleDelete,
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626),
                          borderRadius: BorderRadius.circular(8),
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
