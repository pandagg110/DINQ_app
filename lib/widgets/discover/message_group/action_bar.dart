import 'package:flutter/material.dart';
import '../../common/asset_icon.dart';
/// 操作栏（与 TSX 中 DinqLogoButton + thumbs 一致）
class MessageGroupActionBar extends StatelessWidget {
  const MessageGroupActionBar({
    super.key,
    required this.isLatest,
    required this.feedback,
    required this.onFeedbackUp,
    required this.onFeedbackDown,
  });

  final bool isLatest;
  final String? feedback; // 'up' | 'down'
  final VoidCallback onFeedbackUp;
  final VoidCallback onFeedbackDown;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AssetIcon(asset: 'icons/logo/dinq-black.svg', size: 14),
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
                  padding: EdgeInsets.only(top: 4),
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
