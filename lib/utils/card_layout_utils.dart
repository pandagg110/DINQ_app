import '../models/card_models.dart';

/// 卡片布局工具类
class CardLayoutUtils {
  /// 与 image_edit_form 的 Preview 一致：根据屏幕宽度与 grid 配置计算预览/编辑用卡片宽高
  static ({double width, double height}) getPreviewCardSize(
    double screenWidth,
    double mobileGap,
    String sizeStr,
  ) {
    final cellSize = (screenWidth - 12 * 2 - mobileGap) / 2;
    final dims = parseSizeString(sizeStr);
    final width = cellSize * dims.w / 2;
    final height = cellSize * dims.h / 2;
    return (width: width, height: height);
  }

  /// 从 "2x2", "4x4" 等字符串解析宽高
  static ({int w, int h}) parseSizeString(String size) {
    final parts = size.toLowerCase().split('x');
    if (parts.length != 2) return (w: 2, h: 2);
    final w = int.tryParse(parts[0].trim()) ?? 2;
    final h = int.tryParse(parts[1].trim()) ?? 2;
    return (w: w, h: h);
  }

  /// 按新顺序紧凑放置，得到每个卡片的 (x,y)；每行内从左往右排布（startX = 0）
  static List<CardPosition> compactPositions(
    List<CardItem> ordered,
    int columns,
  ) {
    final rowItems = <int, List<({int w, int h})>>{};
    int y = 0, rowHeight = 0, rowUsed = 0;

    for (var i = 0; i < ordered.length; i++) {
      final card = ordered[i];
      final dims = parseSizeString(card.layout.mobile.size);
      final w = dims.w.clamp(1, columns);
      final h = dims.h.clamp(1, 100);

      if (rowUsed + w > columns) {
        y += rowHeight;
        rowHeight = 0;
        rowUsed = 0;
      }

      rowItems.putIfAbsent(y, () => []).add((w: w, h: h));
      if (rowHeight < h) rowHeight = h;
      rowUsed += w;
    }

    final positions = <CardPosition>[];
    var cardIndex = 0;
    final rowKeys = rowItems.keys.toList()..sort();

    for (final rowY in rowKeys) {
      final items = rowItems[rowY]!;
      int startX = 0;

      for (final _ in items) {
        final card = ordered[cardIndex];
        final dims = parseSizeString(card.layout.mobile.size);
        final w = dims.w.clamp(1, columns);
        final h = dims.h.clamp(1, 100);
        positions.add(CardPosition(x: startX, y: rowY, w: w, h: h));
        startX += w;
        cardIndex++;
      }
    }

    return positions;
  }
}
