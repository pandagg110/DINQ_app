import '../search_panel/tool_search_progress.dart';
import 'analysis_config.dart';

/// 与 TSX `toolPhases.ts` 中 `buildAnalysisPhases` 对齐。
List<ToolSearchPhase> buildAnalysisPhases({
  required List<dynamic> rounds,
  required bool isFinished,
  int? cardCount,
  Map<String, dynamic>? cards,
  String? platform,
}) {
  const analysisPhases = [
    _PhaseDef(key: 'resolving', active: 'Resolving profile', done: 'Profile resolved'),
    _PhaseDef(key: 'analyzing', active: 'Analyzing data', done: 'Analysis generated'),
  ];

  final phases = <ToolSearchPhase>[];

  for (var ri = 0; ri < rounds.length; ri++) {
    final round = rounds[ri] is Map
        ? Map<String, dynamic>.from(rounds[ri] as Map)
        : <String, dynamic>{};
    final isLastRound = ri == rounds.length - 1;
    final roundDone = isLastRound ? isFinished : true;
    final phase = round['phase']?.toString();
    final activeIdx = phase == null ? -1 : analysisPhases.indexWhere((p) => p.key == phase);

    final nextRound = ri < rounds.length - 1 && rounds[ri + 1] is Map
        ? Map<String, dynamic>.from(rounds[ri + 1] as Map)
        : null;
    if (nextRound?['selectedCandidate'] != null) {
      phases.add(
        ToolSearchPhase(
          key: 'sel-$ri',
          label: 'Selected: ${nextRound!['selectedCandidate']}',
          status: 'done',
        ),
      );
      continue;
    }

    final maxIdx = isLastRound && roundDone ? analysisPhases.length - 1 : activeIdx;

    for (var i = 0; i <= maxIdx; i++) {
      final p = analysisPhases[i];
      final isDone = i < activeIdx || roundDone;
      final isActive = i == activeIdx && !roundDone;
      final currentAction = round['currentAction']?.toString();
      final isDisambiguation =
          isActive && (currentAction?.toLowerCase().contains('select') ?? false);

      var label = isDone
          ? p.done
          : (isActive && currentAction != null && currentAction.isNotEmpty)
              ? currentAction
              : p.active;

      if (isDone && p.key == 'analyzing' && isFinished && (cardCount ?? 0) == 0) {
        label = 'No results found';
      }

      List<ToolSearchPhaseChild>? children;
      if (p.key == 'analyzing' &&
          (isActive || isDone) &&
          isLastRound &&
          cards != null &&
          platform != null) {
        final order = switch (platform) {
          'github' => _githubOrder,
          'linkedin' => _linkedinOrder,
          _ => _scholarOrder,
        };
        final hasStarted = order.any((key) {
          final card = cards[key];
          return card is Map && card['status']?.toString() != 'pending';
        });
        if (hasStarted) {
          children = order
              .where((key) => cards[key] is Map)
              .map((key) {
                final card = cards[key] as Map;
                return ToolSearchPhaseChild(
                  key: key,
                  label: AnalysisPlatformConfig.cardLabels[key] ?? key,
                  status: card['status'] == 'completed' ? 'done' : 'active',
                );
              })
              .toList();
        }
      }

      phases.add(
        ToolSearchPhase(
          key: '$ri-${p.key}',
          label: label,
          status: isDone ? 'done' : 'active',
          waiting: isDisambiguation,
          children: children,
        ),
      );
    }
  }

  return phases;
}

class _PhaseDef {
  const _PhaseDef({required this.key, required this.active, required this.done});

  final String key;
  final String active;
  final String done;
}

const _scholarOrder = AnalysisPlatformConfig.scholarOrder;
const _githubOrder = AnalysisPlatformConfig.githubOrder;
const _linkedinOrder = AnalysisPlatformConfig.linkedinOrder;
