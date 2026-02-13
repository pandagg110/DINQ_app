import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../stores/search_store.dart';

/// 发现页快捷操作一行：Find Advisor、Salary Analysis 两个圆角芯片按钮
class DiscoverQuickActionsWidget extends StatelessWidget {
  const DiscoverQuickActionsWidget({
    super.key,
    this.onFindAdvisor,
    this.onSalaryAnalysis,
  });

  final VoidCallback? onFindAdvisor;
  final VoidCallback? onSalaryAnalysis;

  static const double _chipRadius = 8;
  static const double _spacing = 12;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionChip(
          icon: Icons.school_outlined,
          label: 'Find Advisor',
          extraType: 'advisor',
          onTap: onFindAdvisor,
        ),
        const SizedBox(width: _spacing),
        _ActionChip(
          icon: Icons.bar_chart_outlined,
          label: 'Salary Analysis',
          onTap: onSalaryAnalysis,
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    this.extraType,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? extraType;
  final VoidCallback? onTap;

  static const Color _bgColor = Color(0xFFFFFFFF);
  static const Color _textColor = Color(0xFF171717);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (extraType != null) {
              final searchStore = context.read<SearchStore>();
              searchStore.setExtraType(extraType);
            }
            onTap?.call();
          },
          borderRadius: BorderRadius.circular(DiscoverQuickActionsWidget._chipRadius),
          child: Container(
            decoration: BoxDecoration(
              color: _bgColor,
              borderRadius: BorderRadius.circular(DiscoverQuickActionsWidget._chipRadius),
              border: Border.all(
                color: const Color(0xFF171717).withOpacity(0.1),
                width: 1.0,
              ),
            ),
            padding: const EdgeInsets.only(top: 2, right: 8, bottom: 2, left: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: _textColor),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
