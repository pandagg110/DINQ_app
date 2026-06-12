import 'package:flutter/material.dart';
import 'dinq_logo.dart';

/// 操作栏（与 TSX 中 DinqLogoButton + thumbs 一致）
class MessageGroupActionBar extends StatelessWidget {
  const MessageGroupActionBar({
    super.key,
    required this.isLatest,
    required this.feedback,
    required this.onFeedbackUp,
    required this.onFeedbackDown,
    this.onDinqLogoTap,
  });

  final bool isLatest;
  final String? feedback; // 'up' | 'down'
  final VoidCallback onFeedbackUp;
  final VoidCallback onFeedbackDown;
  final VoidCallback? onDinqLogoTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          DinqLogoButton(
            size: 24,
            onTap: onDinqLogoTap,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      feedback == 'up'
                          ? Icons.thumb_up
                          : Icons.thumb_up_outlined,
                      size: 18,
                      color: feedback == 'up'
                          ? const Color(0xFF4B5563)
                          : const Color(0xFF9CA3AF),
                    ),
                    onPressed: onFeedbackUp,
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(6),
                      minimumSize: const Size(32, 32),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      feedback == 'down'
                          ? Icons.thumb_down
                          : Icons.thumb_down_outlined,
                      size: 18,
                      color: feedback == 'down'
                          ? const Color(0xFF4B5563)
                          : const Color(0xFF9CA3AF),
                    ),
                    onPressed: onFeedbackDown,
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(6),
                      minimumSize: const Size(32, 32),
                    ),
                  ),
                ],
              ),
              if (isLatest)
                const Padding(
                  padding: EdgeInsets.only(top: 0),
                  child: Text(
                    'DINQ can make mistakes. Verify important info.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
