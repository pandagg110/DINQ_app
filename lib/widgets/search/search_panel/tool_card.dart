import 'package:flutter/material.dart';

import '../deep_search/deep_search_models.dart';

/// 与 TSX ToolCard 简化对齐：工具名、状态与结果摘要。
class ToolCard extends StatelessWidget {
  const ToolCard({super.key, required this.block});

  final ToolCallBlock block;

  @override
  Widget build(BuildContext context) {
    final isRunning = block.status == ToolCallStatus.running;
    final isError = block.status == ToolCallStatus.error;
    final inputText = _formatInput(block.input);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ToolStatusIcon(status: block.status),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  block.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
              ),
            ],
          ),
          if (isRunning)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Running...',
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
            ),
          if (!isRunning && block.result != null && block.result!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                block.result!.trim(),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: isError ? const Color(0xFFDC2626) : const Color(0xFF6B7280),
                  height: 1.4,
                ),
              ),
            ),
          if (inputText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                inputText,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF9CA3AF),
                  height: 1.35,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatInput(dynamic input) {
    if (input == null) return '';
    if (input is String) return input.trim();
    return input.toString();
  }
}

class _ToolStatusIcon extends StatelessWidget {
  const _ToolStatusIcon({required this.status});

  final ToolCallStatus status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case ToolCallStatus.running:
        return const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF5F9670)),
        );
      case ToolCallStatus.done:
        return const Icon(Icons.check_circle, size: 16, color: Color(0xFF059669));
      case ToolCallStatus.error:
        return const Icon(Icons.error_outline, size: 16, color: Color(0xFFDC2626));
    }
  }
}
