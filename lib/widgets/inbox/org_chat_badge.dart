import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/me_icons.dart';

/// 组织群聊标识，对齐 web ConversationList：
/// `org_id` 存在时显示 Building2 + "Org"（bg #F0EEE8 / text #6b6862）。
class OrgChatBadge extends StatelessWidget {
  const OrgChatBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EEE8),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            MeIcons.organization,
            width: 12,
            height: 12,
            colorFilter: const ColorFilter.mode(
              Color(0xFF6B6862),
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            'Org',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B6862),
              fontFamily: 'Geist',
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
