import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../analysis/analysis_theme.dart';

/// 与 TSX `ToolSearchProgress.tsx` 对齐。
class ToolSearchProgress extends StatefulWidget {
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
  State<ToolSearchProgress> createState() => _ToolSearchProgressState();
}

class _ToolSearchProgressState extends State<ToolSearchProgress> {
  bool _expanded = false;
  bool _prevFinished = false;
  int _spinnerFrame = 0;
  Timer? _spinnerTimer;

  static const _brailleFrames = ['⣷', '⣯', '⣟', '⡿', '⢿', '⣻', '⣽', '⣾'];

  @override
  void initState() {
    super.initState();
    _prevFinished = widget.isFinished;
    _startSpinner();
  }

  @override
  void didUpdateWidget(covariant ToolSearchProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFinished && !_prevFinished) {
      _expanded = false;
    }
    _prevFinished = widget.isFinished;
    if (widget.isFinished) {
      _spinnerTimer?.cancel();
    } else {
      _startSpinner();
    }
  }

  @override
  void dispose() {
    _spinnerTimer?.cancel();
    super.dispose();
  }

  void _startSpinner() {
    _spinnerTimer?.cancel();
    if (widget.isFinished) return;
    _spinnerTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      setState(() => _spinnerFrame = (_spinnerFrame + 1) % _brailleFrames.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.phases.isEmpty && widget.isFinished) {
      return const SizedBox.shrink();
    }

    final canExpand = widget.phases.isNotEmpty;
    ToolSearchPhase? activePhase;
    for (final phase in widget.phases) {
      if (phase.status == 'active') {
        activePhase = phase;
        break;
      }
    }
    final rawLabel = widget.isFinished
        ? (widget.finishedLabel.isNotEmpty ? widget.finishedLabel : 'Done')
        : (activePhase?.label ?? 'Preparing');
    final summaryText = widget.isFinished
        ? rawLabel
        : rawLabel.replaceAll(RegExp(r'\.{2,}$'), '');
    final isWaiting = activePhase?.waiting ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEAE7E0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: canExpand ? () => setState(() => _expanded = !_expanded) : null,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(36, 10, 12, 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: Center(
                        child: widget.isFinished
                            ? SvgPicture.asset(
                                AnalysisTheme.actionCheckCircle,
                                width: 14,
                                height: 14,
                                colorFilter: const ColorFilter.mode(
                                  Color(0xFF9E9A94),
                                  BlendMode.srcIn,
                                ),
                              )
                            : Text(
                                  _brailleFrames[_spinnerFrame],
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 14,
                                    color: Color(0xFF9E9A94),
                                  ),
                                ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '$summaryText${!widget.isFinished && !isWaiting ? '...' : ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: widget.isFinished || isWaiting
                              ? const Color(0xFF9E9A94)
                              : const Color(0xFF6B6862),
                        ),
                      ),
                    ),
                    if (canExpand)
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: SvgPicture.asset(
                          AnalysisTheme.actionChevronDown,
                          width: 14,
                          height: 14,
                          colorFilter: const ColorFilter.mode(
                            Color(0xFF9E9A94),
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(36, 0, 12, 12),
              child: Column(
                children: [
                  for (var i = 0; i < widget.phases.length; i++)
                    _PhaseRow(
                      phase: widget.phases[i],
                      isLast: i == widget.phases.length - 1,
                    ),
                ],
              ),
            ),
            crossFadeState:
                _expanded && canExpand ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

class _PhaseRow extends StatelessWidget {
  const _PhaseRow({required this.phase, required this.isLast});

  final ToolSearchPhase phase;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            child: phase.status == 'done'
                ? SvgPicture.asset(
                    AnalysisTheme.actionCheckCircle,
                    width: 14,
                    height: 14,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF9E9A94),
                      BlendMode.srcIn,
                    ),
                  )
                : SvgPicture.asset(
                    AnalysisTheme.actionDot,
                    width: 4,
                    height: 4,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF9E9A94),
                      BlendMode.srcIn,
                    ),
                  ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  phase.label,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.3,
                    color: phase.status == 'active'
                        ? const Color(0xFF6B6862)
                        : const Color(0xFF9E9A94),
                  ),
                ),
                if (phase.children != null && phase.children!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        for (final child in phase.children!)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              child.status == 'done'
                                  ? SvgPicture.asset(
                                      AnalysisTheme.actionCheckCircle,
                                      width: 10,
                                      height: 10,
                                      colorFilter: const ColorFilter.mode(
                                        Color(0xFF9E9A94),
                                        BlendMode.srcIn,
                                      ),
                                    )
                                  : SvgPicture.asset(
                                      AnalysisTheme.actionDot,
                                      width: 4,
                                      height: 4,
                                      colorFilter: const ColorFilter.mode(
                                        Color(0xFFD6D3CD),
                                        BlendMode.srcIn,
                                      ),
                                    ),
                              const SizedBox(width: 4),
                              Text(
                                child.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: child.status == 'done'
                                      ? const Color(0xFF9E9A94)
                                      : const Color(0xFFD6D3CD),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
              ],
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
    this.waiting = false,
    this.children,
  });

  final String key;
  final String label;
  final String status;
  final bool waiting;
  final List<ToolSearchPhaseChild>? children;
}

class ToolSearchPhaseChild {
  const ToolSearchPhaseChild({
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
