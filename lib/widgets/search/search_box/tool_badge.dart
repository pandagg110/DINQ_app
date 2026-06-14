import 'package:flutter/material.dart';
import 'search_box_types.dart';

/// 与 TSX ToolBadge 对齐
class ToolBadge extends StatelessWidget {
  const ToolBadge({
    super.key,
    required this.tool,
    required this.onClear,
  });

  final String? tool;
  final VoidCallback onClear;

  static const _configs = <String, ({Color bg, Color text, Color hover, IconData icon, String label})>{
    'find-advisor': (
      bg: Color(0xFFFFE082),
      text: Color(0xFFD97706),
      hover: Color(0xFFB45309),
      icon: Icons.school_outlined,
      label: 'Advisor',
    ),
    'who-cites-me': (
      bg: Color(0xFFDBEAFE),
      text: Color(0xFF2563EB),
      hover: Color(0xFF1D4ED8),
      icon: Icons.menu_book_outlined,
      label: 'Citations',
    ),
    'analysis': (
      bg: Color(0xFFFAF2EF),
      text: Color(0xFFCB7C5D),
      hover: Color(0xFFA85E3F),
      icon: Icons.bar_chart_outlined,
      label: 'Analysis',
    ),
  };

  @override
  Widget build(BuildContext context) {
    if (tool == null || tool == 'deep-search') return const SizedBox.shrink();
    final config = _configs[tool];
    if (config == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config.bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 14, color: config.text),
          const SizedBox(width: 6),
          Text(
            config.label,
            style: TextStyle(fontSize: 14, color: config.text),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onClear,
            child: Icon(Icons.close, size: 14, color: config.text),
          ),
        ],
      ),
    );
  }
}
