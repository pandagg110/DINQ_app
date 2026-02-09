import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 与 TSX NewChatConfirmDialog 一致：Free/Basic 用户新建会话确认
class NewChatConfirmDialog extends StatelessWidget {
  const NewChatConfirmDialog({
    super.key,
    required this.isOpen,
    required this.onClose,
    required this.onConfirm,
    required this.userPlan,
  });

  final bool isOpen;
  final VoidCallback onClose;
  final VoidCallback onConfirm;
  final String userPlan; // 'free' | 'basic'

  @override
  Widget build(BuildContext context) {
    if (!isOpen) return const SizedBox.shrink();

    final isFree = userPlan == 'free';
    final title = isFree ? 'Start New Chat?' : 'Overwrite Previous History?';
    final message = isFree
        ? 'Your current chat will be cleared. As a Free user, conversations are not saved after you start a new session.'
        : 'You can only save one conversation at a time. Starting this new chat will replace your currently saved history.';
    final confirmText = isFree ? 'New Chat' : 'Overwrite & Start';
    final upgradeText = isFree ? 'Want to save your chats?' : 'Need more history slots?';
    final upgradeCta = isFree ? 'Upgrade' : 'Go Unlimited';

    return Material(
      color: Colors.black.withOpacity(0.4),
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: onClose,
              behavior: HitTestBehavior.opaque,
            ),
          ),
          Center(
            child: GestureDetector(
              onTap: () {},
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                constraints: const BoxConstraints(maxWidth: 420),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Close button
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 20, color: Color(0xFF575757)),
                        onPressed: onClose,
                        style: IconButton.styleFrom(
                          padding: const EdgeInsets.all(12),
                          minimumSize: const Size(40, 40),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF171717),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            message,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF575757),
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: onClose,
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    side: const BorderSide(color: Color(0xFFE5E5E5)),
                                    foregroundColor: const Color(0xFF171717),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text('Cancel'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton(
                                  onPressed: () {
                                    onConfirm();
                                  },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF171717),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(confirmText),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              
                              Text(
                                upgradeText,
                                style: const TextStyle(fontSize: 14, color: Color(0xFF575757)),
                              ),
                              const SizedBox(width: 4),
                              TextButton(
                                onPressed: () {
                                  onClose();
                                  context.push('/pricing');
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  upgradeCta,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF1487FA),
                                  ),
                                ),
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
        ],
      ),
    );
  }
}
