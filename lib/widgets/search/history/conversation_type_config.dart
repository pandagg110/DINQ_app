import 'package:flutter/material.dart';

/// 与 TSX `TYPE_CONFIG`（history.ts）一致：会话类型 → 列表图标
IconData conversationTypeIcon(String type) {
  switch (type) {
    case 'analyze':
      return Icons.bar_chart_outlined;
    case 'match':
      return Icons.school_outlined;
    case 'citation':
      return Icons.menu_book_outlined;
    case 'discover':
    default:
      return Icons.search;
  }
}

const Color kConversationTypeIconColor = Color(0xFF9E9B93);
