import 'package:flutter/material.dart';

import '../../common/asset_icon.dart';

/// 会话类型 SVG 路径，与 TSX `TYPE_CONFIG`（history.ts）一致。
///
/// 渲染方式与 search 模块其他 UI 对齐（[AssetIcon] + 相对路径），
/// 同 [user_info_widget]、`dinq_results_view` 中的 `icons/search/*.svg` 用法。
abstract final class ConversationHistoryAssets {
  ConversationHistoryAssets._();

  static const analyze = 'icons/search/history/analyze.svg';
  static const match = 'icons/search/history/match.svg';
  static const citation = 'icons/search/history/citation.svg';
  static const discover = 'icons/search/history/discover.svg';

  static String forType(String type) {
    return switch (type) {
      'analyze' => analyze,
      'match' => match,
      'citation' => citation,
      'discover' => discover,
      _ => discover,
    };
  }
}

/// 列表项类型图标色，与 TSX `text-[#9e9b93]` 一致。
const Color kConversationTypeIconColor = Color(0xFF9E9B93);

/// 会话类型图标（16px，#9E9B93，与 TSX `h-4 w-4 text-[#9e9b93]` 一致）
class ConversationTypeIcon extends StatelessWidget {
  const ConversationTypeIcon({
    super.key,
    required this.type,
    this.size = 16,
    this.color = kConversationTypeIconColor,
  });

  final String type;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AssetIcon(
      asset: ConversationHistoryAssets.forType(type),
      size: size,
      color: color,
    );
  }
}
