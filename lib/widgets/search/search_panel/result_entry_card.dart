import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../agentic_search_logic.dart';
import '../deep_search/deep_search_models.dart';
import '../deep_search/sub_agent_helpers.dart';

enum ResultEntryMode { desktop, mobile }

bool isStartSearchMarker(String text) {
  return RegExp(
    r'^(start search|开始搜索)$',
    caseSensitive: false,
  ).hasMatch(text.trim());
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

bool groupHasResultWorkspace(
  AgenticMessageGroup group, {
  required bool isSearching,
  bool backgroundProcessing = false,
}) {
  if (group.toolType != null) return false;
  final hasRows = group.candidates.isNotEmpty;
  if (hasRows) return true;
  // RoundSection 卡片在 result-entry 模式下可用 backgroundProcessing 撑起；
  // 是否进入该模式由 AgenticChat 的 hasResultWorkspaceRound（不含此项）决定，
  // 对齐 Web：仅后台 processing、尚无 tool/结果时不展示 Preparing results 卡。
  if (backgroundProcessing) return true;
  if (!isSearching) return false;
  final toolCount = getGroupToolCount(group);
  return toolCount > 0 ||
      isStartSearchMarker(group.displayQuery ?? group.userQuery);
}

/// 对齐 Web `AgenticChat.hasResultWorkspace`：不含 backgroundProcessing。
/// 用于决定是否进入 mobile result-entry 模式（showInlineResults=false）。
bool groupHasResultWorkspaceRound(AgenticMessageGroup group) {
  if (group.toolType != null) return false;
  final status = groupRoundStatus(group);
  final isSearching = status == DeepSearchRoundStatus.searching;
  if (group.candidates.isNotEmpty) return true;
  final toolCount = getGroupToolCount(group);
  if (toolCount > 0) return true;
  return isSearching &&
      isStartSearchMarker(group.displayQuery ?? group.userQuery);
}

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
    this.backgroundProcessing = false,
  });

  final bool isSearching;
  final int resultCount;
  final int toolCount;
  final ResultEntryMode mode;
  final bool selected;
  final VoidCallback? onTap;
  final bool enabled;
  final bool backgroundProcessing;

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
      final candidateLabel = resultCount == 1
          ? '1 candidate'
          : '$resultCount candidates';
      final toolLabel = toolCount == 1
          ? '1 tool call'
          : '$toolCount tool calls';
      return '$candidateLabel · $toolLabel';
    }
    if (backgroundProcessing) {
      return 'Running in the background — this page will update when results are ready';
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
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
              child: Icon(Icons.check, size: 12, color: Color(0xFF2F8F68)),
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
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth <= 360;
    final isWideMobile = screenWidth >= 430;
    final isDesktop = screenWidth >= 640;

    final width = isDesktop
        ? 140.0
        : isWideMobile
        ? 126.0
        : isCompact
        ? 96.0
        : 112.0;
    final height = isDesktop
        ? 84.0
        : isWideMobile
        ? 78.0
        : isCompact
        ? 64.0
        : 72.0;
    final horizontalPadding = isCompact
        ? 8.0
        : isWideMobile || isDesktop
        ? 12.0
        : 10.0;
    final rowGap = isCompact ? 6.0 : 8.0;
    final iconGap = isDesktop
        ? 6.0
        : isCompact
        ? 4.0
        : 5.0;
    final badgeSize = isDesktop
        ? 16.0
        : isCompact
        ? 12.0
        : 14.0;
    final badgeRadius = isDesktop ? 4.0 : 3.5;
    final lineHeight = isCompact ? 5.0 : 6.0;
    final coinSize = isCompact ? 32.0 : 36.0;
    final checkSize = isCompact ? 18.0 : 20.0;

    return SizedBox(
      width: width,
      height: height,
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
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _SkeletonRow(
                        widthFactor: 0.66,
                        badgeSize: badgeSize,
                        badgeRadius: badgeRadius,
                        lineHeight: lineHeight,
                        gap: iconGap,
                      ),
                      SizedBox(height: rowGap),
                      _SkeletonRow(
                        widthFactor: 0.52,
                        badgeSize: badgeSize,
                        badgeRadius: badgeRadius,
                        lineHeight: lineHeight,
                        gap: iconGap,
                      ),
                      SizedBox(height: rowGap),
                      _SkeletonRow(
                        widthFactor: 0.40,
                        badgeSize: badgeSize,
                        badgeRadius: badgeRadius,
                        lineHeight: lineHeight,
                        gap: iconGap,
                      ),
                    ],
                  ),
                ),
              ),
              if (isSearching)
                const ScanningLens()
              else
                Center(
                  child: Container(
                    width: coinSize,
                    height: coinSize,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color.fromRGBO(42, 40, 38, 0.16),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.check,
                      size: checkSize,
                      color: const Color(0xFF2F8F68),
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
  const _SkeletonRow({
    required this.widthFactor,
    required this.badgeSize,
    required this.badgeRadius,
    required this.lineHeight,
    required this.gap,
  });

  final double widthFactor;
  final double badgeSize;
  final double badgeRadius;
  final double lineHeight;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            Container(
              width: badgeSize,
              height: badgeSize,
              decoration: BoxDecoration(
                color: const Color(0xFFE3DED4),
                borderRadius: BorderRadius.circular(badgeRadius),
              ),
            ),
            SizedBox(width: gap),
            Container(
              width: constraints.maxWidth * widthFactor,
              height: lineHeight,
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
  var _segmentIndex = 0;
  var _segmentStart = Duration.zero;

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

  double _rand(double min, double max) =>
      min + _random.nextDouble() * (max - min);

  double _easeInOut(double t) =>
      t < 0.5 ? 2 * t * t : 1 - math.pow(-2 * t + 2, 2) / 2;

  void _buildLoop() {
    final segments = <_ScanSegment>[];
    for (var i = 0; i < 3; i++) {
      segments.add(
        _ScanSegment(
          fromL: _left,
          toL: _right,
          fromT: _rowY[i],
          toT: _rowY[i],
          durMs: _rand(420, 980),
        ),
      );
      segments.add(
        _ScanSegment(
          fromL: _right,
          toL: _right,
          fromT: _rowY[i],
          toT: _rowY[i],
          durMs: _rand(40, 150),
        ),
      );
      if (i < 2) {
        segments.add(
          _ScanSegment(
            fromL: _right,
            toL: _left,
            fromT: _rowY[i],
            toT: _rowY[i + 1],
            durMs: _rand(110, 180),
          ),
        );
      }
    }
    segments.add(
      _ScanSegment(
        fromL: _right,
        toL: _left,
        fromT: _rowY[2],
        toT: _rowY[0],
        durMs: _rand(280, 400),
      ),
    );
    _segments = segments;
    _segmentIndex = 0;
    _segmentStart = Duration.zero;
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      setState(() => _position = const Offset(0.5, 0.5));
      return;
    }
    if (_segmentStart == Duration.zero) _segmentStart = elapsed;
    final segment = _segments[_segmentIndex];
    final progress = ((elapsed - _segmentStart).inMilliseconds / segment.durMs)
        .clamp(0.0, 1.0);
    final eased = _easeInOut(progress);
    setState(() {
      _position = Offset(
        lerpDouble(segment.fromL, segment.toL, eased)!,
        lerpDouble(segment.fromT, segment.toT, eased)!,
      );
    });
    if (progress >= 1) {
      _segmentStart = elapsed;
      _segmentIndex += 1;
      if (_segmentIndex >= _segments.length) _buildLoop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return const Center(
        child: Icon(Icons.search, size: 20, color: Color(0xFF7A766E)),
      );
    }
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Positioned(
                left: constraints.maxWidth * _position.dx - 10,
                top: constraints.maxHeight * _position.dy - 10,
                child: const Icon(
                  Icons.search,
                  size: 20,
                  color: Color(0xFF7A766E),
                ),
              ),
            ],
          );
        },
      ),
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
