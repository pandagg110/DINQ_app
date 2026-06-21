import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../agentic_search_logic.dart';
import '../deep_search/deep_search_models.dart';
import '../deep_search/sub_agent_helpers.dart';

enum ResultEntryMode { desktop, mobile }

bool isStartSearchMarker(String text) {
  return RegExp(r'^(start search|开始搜索)$', caseSensitive: false)
      .hasMatch(text.trim());
}

DeepSearchRoundStatus groupRoundStatus(AgenticMessageGroup group) {
  if (group.roundStatus != DeepSearchRoundStatus.idle) {
    return group.roundStatus;
  }
  if (group.errorMessage != null && group.searchCompleted) {
    return DeepSearchRoundStatus.error;
  }
  if (group.loading && !group.searchCompleted) {
    return DeepSearchRoundStatus.searching;
  }
  if (group.searchCompleted) return DeepSearchRoundStatus.done;
  return DeepSearchRoundStatus.idle;
}

int getGroupToolCount(AgenticMessageGroup group) {
  var count = countToolCalls(group.contentBlocks);
  for (final agent in group.subAgents.values) {
    count += countToolCalls(agent.contentBlocks);
  }
  return count;
}

bool groupHasResultWorkspace(AgenticMessageGroup group, {required bool isSearching}) {
  if (group.toolType != null) return false;
  final hasRows = group.candidates.isNotEmpty;
  final toolCount = getGroupToolCount(group);
  return hasRows ||
      toolCount > 0 ||
      (isSearching &&
          isStartSearchMarker(group.displayQuery ?? group.userQuery));
}

/// 与 TSX `SearchPanel.tsx` result-entry-flow-card 对齐。
class ResultEntryCard extends StatelessWidget {
  const ResultEntryCard({
    super.key,
    required this.isSearching,
    required this.resultCount,
    required this.toolCount,
    required this.mode,
    this.selected = false,
    this.onTap,
    this.enabled = true,
  });

  final bool isSearching;
  final int resultCount;
  final int toolCount;
  final ResultEntryMode mode;
  final bool selected;
  final VoidCallback? onTap;
  final bool enabled;

  static const _searchingTitlesDesktop = [
    'Searching candidates.',
    'Updating the list on the right.',
  ];
  static const _completedTitlesDesktop = [
    'Expanded search completed.',
    'List updated on the right.',
  ];
  static const _searchingTitlesMobile = [
    'Preparing results.',
    'Tap to open the list.',
  ];
  static const _completedTitlesMobile = [
    'Search results ready.',
    'Tap to review candidates.',
  ];

  List<String> get _titleLines {
    if (mode == ResultEntryMode.mobile) {
      return isSearching ? _searchingTitlesMobile : _completedTitlesMobile;
    }
    return isSearching ? _searchingTitlesDesktop : _completedTitlesDesktop;
  }

  String get _subtitle {
    if (resultCount > 0) {
      final candidateLabel =
          resultCount == 1 ? '1 candidate' : '$resultCount candidates';
      final toolLabel =
          toolCount == 1 ? '1 tool call' : '$toolCount tool calls';
      return '$candidateLabel · $toolLabel';
    }
    return 'Screening profiles · ranking matches';
  }

  Color get _borderColor {
    if (selected) return const Color(0xFFD7D1C8);
    if (isSearching) return const Color(0xFFD7D1C8);
    return const Color(0xFFE5E0D8);
  }

  @override
  Widget build(BuildContext context) {
    final canTap = enabled && onTap != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: canTap ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        hoverColor: const Color(0xFFFBFAF7),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _borderColor),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CustomPaint(
              painter: const _DotGridPainter(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _StatusBadge(isSearching: isSearching),
                          const SizedBox(height: 6),
                          for (final line in _titleLines)
                            Text(
                              line,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                height: 1.35,
                                color: Color(0xFF24221F),
                              ),
                            ),
                          const SizedBox(height: 2),
                          Text(
                            _subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF8A8880),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _ResultPreviewIllustration(isSearching: isSearching),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isSearching});

  final bool isSearching;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0x73FFFFFF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFEBE7DF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSearching)
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 6),
              decoration: const BoxDecoration(
                color: Color(0xFFB8B2A7),
                shape: BoxShape.circle,
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(
                Icons.check,
                size: 12,
                color: Color(0xFF2F8F68),
              ),
            ),
          Text(
            isSearching ? 'Searching' : 'Completed',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6F6A62),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultPreviewIllustration extends StatelessWidget {
  const _ResultPreviewIllustration({required this.isSearching});

  final bool isSearching;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 126,
      height: 78,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFEFECE5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE7E2DA)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      _SkeletonRow(widthFactor: 0.66),
                      SizedBox(height: 8),
                      _SkeletonRow(widthFactor: 0.52),
                      SizedBox(height: 8),
                      _SkeletonRow(widthFactor: 0.40),
                    ],
                  ),
                ),
              ),
              if (isSearching)
                const ScanningLens()
              else
                Center(
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(42, 40, 38, 0.16),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 20,
                      color: Color(0xFF2F8F68),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow({required this.widthFactor});

  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: const Color(0xFFE3DED4),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: constraints.maxWidth * widthFactor,
              height: 6,
              decoration: BoxDecoration(
                color: const Color(0xFFE3DED4),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 与 TSX `ScanningLens` 对齐：放大镜在三行 skeleton 上扫描。
class ScanningLens extends StatefulWidget {
  const ScanningLens({super.key});

  @override
  State<ScanningLens> createState() => _ScanningLensState();
}

class _ScanningLensState extends State<ScanningLens>
    with SingleTickerProviderStateMixin {
  static const _rowY = [0.21, 0.50, 0.79];
  static const _left = 0.18;
  static const _right = 0.82;

  late Ticker _ticker;
  final _random = math.Random();
  Offset _position = Offset(_left, _rowY[0]);
  List<_ScanSegment> _segments = [];
  var _segIdx = 0;
  var _segStart = Duration.zero;

  @override
  void initState() {
    super.initState();
    _buildLoop();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  double _rand(double min, double max) => min + _random.nextDouble() * (max - min);

  double _easeInOut(double t) =>
      t < 0.5 ? 2 * t * t : 1 - math.pow(-2 * t + 2, 2) / 2;

  void _buildLoop() {
    final next = <_ScanSegment>[];
    for (var i = 0; i < 3; i++) {
      next.add(_ScanSegment(
        fromL: _left,
        toL: _right,
        fromT: _rowY[i],
        toT: _rowY[i],
        durMs: _rand(420, 980),
      ));
      next.add(_ScanSegment(
        fromL: _right,
        toL: _right,
        fromT: _rowY[i],
        toT: _rowY[i],
        durMs: _rand(40, 150),
      ));
      if (i < 2) {
        next.add(_ScanSegment(
          fromL: _right,
          toL: _left,
          fromT: _rowY[i],
          toT: _rowY[i + 1],
          durMs: _rand(110, 180),
        ));
      }
    }
    next.add(_ScanSegment(
      fromL: _right,
      toL: _left,
      fromT: _rowY[2],
      toT: _rowY[0],
      durMs: _rand(280, 400),
    ));
    _segments = next;
    _segIdx = 0;
    _segStart = Duration.zero;
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      setState(() => _position = const Offset(0.5, 0.5));
      return;
    }
    if (_segStart == Duration.zero) _segStart = elapsed;
    final seg = _segments[_segIdx];
    final p = ((elapsed - _segStart).inMilliseconds / seg.durMs).clamp(0.0, 1.0);
    final e = _easeInOut(p);
    setState(() {
      _position = Offset(
        lerpDouble(seg.fromL, seg.toL, e)!,
        lerpDouble(seg.fromT, seg.toT, e)!,
      );
    });
    if (p >= 1) {
      _segStart = elapsed;
      _segIdx += 1;
      if (_segIdx >= _segments.length) _buildLoop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return const Center(
        child: Icon(Icons.search, size: 20, color: Color(0xFF7A766E)),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        return Positioned(
          left: constraints.maxWidth * _position.dx - 10,
          top: constraints.maxHeight * _position.dy - 10,
          child: const Icon(
            Icons.search,
            size: 20,
            color: Color(0xFF7A766E),
          ),
        );
      },
    );
  }
}

class _ScanSegment {
  const _ScanSegment({
    required this.fromL,
    required this.toL,
    required this.fromT,
    required this.toT,
    required this.durMs,
  });

  final double fromL;
  final double toL;
  final double fromT;
  final double toT;
  final double durMs;
}

class _DotGridPainter extends CustomPainter {
  const _DotGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 14.0;
    final paint = Paint()..color = const Color.fromRGBO(158, 155, 147, 0.12);
    for (var x = 1.0; x < size.width; x += spacing) {
      for (var y = 1.0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
