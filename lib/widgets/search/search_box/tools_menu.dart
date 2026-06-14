import 'package:flutter/material.dart';
import 'search_box_types.dart';

/// 与 TSX ToolsMenu / menuStyles 对齐
class ToolsMenu extends StatelessWidget {
  const ToolsMenu({
    super.key,
    required this.visible,
    required this.onSelect,
    required this.onClose,
    this.position = 'down',
  });

  final bool visible;
  final ValueChanged<SearchToolDefinition> onSelect;
  final VoidCallback onClose;
  final String position;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      color: Colors.white,
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD5D3CE)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: kSearchTools.map((tool) {
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onSelect(tool),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Icon(tool.icon, size: 16, color: tool.iconColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tool.label,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B6862),
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.keyboard_return,
                        size: 14,
                        color: Color(0xFF9E9B93),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// 移动端工具选择 BottomSheet（与 TSX BottomSheet Tools 对齐）
Future<void> showToolsBottomSheet(
  BuildContext context, {
  required String? activeTool,
  required ValueChanged<SearchToolDefinition> onSelect,
}) {
  final bottomInset = MediaQuery.paddingOf(context).bottom;
  // 每项约 52px + 标题区 72px + 内边距；避免第三项 Analysis 被裁切
  final sheetHeight = 72.0 + kSearchTools.length * 52.0 + bottomInset + 24;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        height: sheetHeight,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Text(
                  'Tools',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2A2826),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, size: 18, color: Color(0xFF6B6862)),
                  style: IconButton.styleFrom(
                    minimumSize: const Size(32, 32),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                itemCount: kSearchTools.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final tool = kSearchTools[index];
                  final selected = activeTool == tool.id;
                  return Material(
                    color: selected
                        ? const Color(0xFFF5F4F0)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).pop();
                        onSelect(tool);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Icon(tool.icon, size: 18, color: tool.iconColor),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                tool.label,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: selected
                                      ? const Color(0xFF2A2826)
                                      : const Color(0xFF6B6862),
                                ),
                              ),
                            ),
                            if (selected)
                              const Icon(
                                Icons.check,
                                size: 18,
                                color: Color(0xFF2A2826),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}
