import 'package:flutter/material.dart';
import '../../../../stores/chat_history_store.dart';

/// 与 TSX RenameDialog 一致：重命名会话
class RenameDialog extends StatefulWidget {
  const RenameDialog({
    super.key,
    required this.conversation,
    required this.onClose,
    required this.onRename,
  });

  final ConversationItem conversation;
  final VoidCallback onClose;
  final Future<bool> Function(int id, String title) onRename;

  @override
  State<RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<RenameDialog> {
  late TextEditingController _controller;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.conversation.title);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final title = _controller.text.trim();
    if (title.isEmpty || _isLoading) return;

    setState(() => _isLoading = true);
    final success = await widget.onRename(widget.conversation.id, title);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      widget.onClose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: InkWell(
        onTap: widget.onClose,
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
                child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GestureDetector(
                  onTap: () {}, // 吸收点击，避免关闭
                  child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                        child: Row(
                          children: [
                            const Text(
                              'Rename',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF171717),
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.close, size: 20, color: Color(0xFF6B7280)),
                              onPressed: widget.onClose,
                              style: IconButton.styleFrom(
                                padding: const EdgeInsets.all(4),
                                minimumSize: const Size(32, 32),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      // Form
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              controller: _controller,
                              decoration: const InputDecoration(
                                hintText: 'Enter a title...',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _handleSubmit(),
                              autofocus: true,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: _isLoading ? null : widget.onClose,
                                  child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B7280))),
                                ),
                                const SizedBox(width: 8),
                                FilledButton(
                                  onPressed: (_isLoading || _controller.text.trim().isEmpty)
                                      ? null
                                      : _handleSubmit,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF171717),
                                    foregroundColor: Colors.white,
                                  ),
                                  child: Text(_isLoading ? 'Saving...' : 'Save'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
