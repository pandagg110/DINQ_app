import '../search_panel/tool_search_progress.dart';

/// 与 TSX `AdvisorsList.tsx` 中 `buildPhasesFromRounds` 对齐。
List<ToolSearchPhase> buildAdvisorPhasesFromRounds({
  required List<dynamic> rounds,
  required bool isFinished,
}) {
  const advisorPhases = [
    _PhaseDef(
      key: 'analyzing',
      icon: 'i-lucide-scan-search',
      active: 'Analyzing your profile',
      done: 'Profile analyzed',
    ),
    _PhaseDef(
      key: 'searching',
      icon: 'i-lucide-globe',
      active: 'Searching for advisors',
      done: 'Advisors found',
    ),
    _PhaseDef(
      key: 'resolving',
      icon: 'i-lucide-graduation-cap',
      active: 'Resolving scholar profiles',
      done: 'Profiles resolved',
    ),
  ];

  final phases = <ToolSearchPhase>[];

  for (var ri = 0; ri < rounds.length; ri++) {
    final round = rounds[ri] is Map
        ? Map<String, dynamic>.from(rounds[ri] as Map)
        : <String, dynamic>{};
    final roundFinished = ri < rounds.length - 1 ||
        (ri == rounds.length - 1 && isFinished);
    final phase = round['phase']?.toString();
    final activeIdx =
        phase == null ? -1 : advisorPhases.indexWhere((p) => p.key == phase);

    if (ri > 0) {
      final prevRound = rounds[ri - 1] is Map
          ? Map<String, dynamic>.from(rounds[ri - 1] as Map)
          : <String, dynamic>{};
      final count = prevRound['advisorCount'] is num
          ? (prevRound['advisorCount'] as num).toInt()
          : int.tryParse(prevRound['advisorCount']?.toString() ?? '') ?? 0;
      phases.add(
        ToolSearchPhase(
          key: 'sep-$ri',
          label: 'Found $count ${count == 1 ? 'advisor' : 'advisors'}',
          status: 'done',
        ),
      );
    }

    final reachedPhases = advisorPhases
        .asMap()
        .entries
        .where((e) => e.key <= activeIdx || roundFinished)
        .map((e) => e.value)
        .toList();

    for (var i = 0; i < reachedPhases.length; i++) {
      final p = reachedPhases[i];
      final isDone = i < activeIdx || roundFinished;
      final phaseSources = round['phaseSources'];
      List<ToolSearchPhaseSource>? sources;
      if (phaseSources is Map && phaseSources[p.key] is List) {
        sources = (phaseSources[p.key] as List)
            .whereType<Map>()
            .map((s) {
              final m = Map<String, dynamic>.from(s);
              return ToolSearchPhaseSource(
                url: m['url']?.toString() ?? '',
                domain: m['domain']?.toString() ?? '',
              );
            })
            .where((s) => s.url.isNotEmpty)
            .toList();
        if (sources.isEmpty) sources = null;
      }

      phases.add(
        ToolSearchPhase(
          key: '$ri-${p.key}',
          label: isDone ? p.done : p.active,
          icon: p.icon,
          status: isDone ? 'done' : 'active',
          sources: sources,
        ),
      );
    }
  }

  return phases;
}

class _PhaseDef {
  const _PhaseDef({
    required this.key,
    required this.icon,
    required this.active,
    required this.done,
  });

  final String key;
  final String icon;
  final String active;
  final String done;
}
