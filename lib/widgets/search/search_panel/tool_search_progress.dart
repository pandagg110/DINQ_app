import 'package:flutter/material.dart';

/// 与 TSX ToolSearchProgress 简化对齐。
class ToolSearchProgress extends StatelessWidget {
  const ToolSearchProgress({
    super.key,
    required this.phases,
    required this.isFinished,
    required this.finishedLabel,
  });

  final List<ToolSearchPhase> phases;
  final bool isFinished;
  final String finishedLabel;

  @override
  Widget build(BuildContext context) {
    if (phases.isEmpty && !isFinished) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final phase in phases)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    phase.status == 'done'
                        ? Icons.check_circle
                        : Icons.autorenew,
                    size: 14,
                    color: phase.status == 'done'
                        ? const Color(0xFF5F9670)
                        : const Color(0xFF9E9B93),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      phase.label,
                      style: TextStyle(
                        fontSize: 13,
                        color: phase.status == 'done'
                            ? const Color(0xFF6B6862)
                            : const Color(0xFF9E9B93),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (isFinished)
            Text(
              finishedLabel,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B6862),
              ),
            ),
        ],
      ),
    );
  }
}

class ToolSearchPhase {
  const ToolSearchPhase({
    required this.key,
    required this.label,
    required this.status,
  });

  final String key;
  final String label;
  final String status;
}

List<ToolSearchPhase> buildCitationPhases(String? currentPhase, bool isFinished) {
  if (currentPhase == null && !isFinished) return [];
  return [
    ToolSearchPhase(
      key: 'searching',
      label: isFinished ? 'Citations found' : 'Searching citations',
      status: isFinished ? 'done' : 'active',
    ),
  ];
}
