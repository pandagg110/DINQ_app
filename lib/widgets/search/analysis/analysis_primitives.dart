import 'package:flutter/material.dart';

import 'analysis_format.dart';
import 'analysis_theme.dart';

export 'analysis_donut_chart.dart';
export 'analysis_language_donut_chart.dart';
export 'analysis_papers_bar_line_chart.dart';

/// 与 TSX `SegmentTable.tsx` 对齐。
class AnalysisSegmentTable extends StatelessWidget {
  const AnalysisSegmentTable({super.key, required this.items});

  final List<AnalysisSegmentItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final colWidth = constraints.maxWidth / 3;
        final rowCount = (items.length / 3).ceil();

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var row = 0; row < rowCount; row++)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var col = 0; col < 3; col++)
                    if (row * 3 + col < items.length)
                      _SegmentCell(
                        item: items[row * 3 + col],
                        width: colWidth,
                        showDivider: col < 2 && row * 3 + col < items.length - 1,
                      )
                    else
                      SizedBox(width: colWidth),
                ],
              ),
          ],
        );
      },
    );
  }
}

class _SegmentCell extends StatelessWidget {
  const _SegmentCell({
    required this.item,
    required this.width,
    required this.showDivider,
  });

  final AnalysisSegmentItem item;
  final double width;
  final bool showDivider;

  static const _valueStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    fontFamily: AnalysisTheme.fontUdc,
    color: Colors.black,
    height: 1.1,
  );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AnalysisFormat.formatThousand(item.value),
                  textAlign: TextAlign.center,
                  style: _valueStyle,
                ),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          if (showDivider)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  width: 1,
                  height: 12,
                  color: const Color(0xFFE5E7EB),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class AnalysisSegmentItem {
  const AnalysisSegmentItem({required this.label, required this.value});

  final String label;
  final dynamic value;
}

/// 与 TSX `Progress.tsx` 对齐。
class AnalysisProgressBar extends StatelessWidget {
  const AnalysisProgressBar({super.key, required this.percentage});

  final double percentage;

  @override
  Widget build(BuildContext context) {
    final clamped = percentage.clamp(0, 100);
    return Container(
      height: 24,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: const LinearGradient(
          colors: [Color(0xFFF8E9C8), Color(0xFFFFE6AE)],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: clamped / 100,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFB1C1EC), Color(0xFF7F95CE)],
                stops: [0, 0.5404],
              ),
              borderRadius: BorderRadius.horizontal(left: Radius.circular(999)),
            ),
          ),
        ),
      ),
    );
  }
}

/// 与 TSX `ContributionHeatmap.tsx` 严格对齐（含 compact @1055px）。
class AnalysisContributionHeatmap extends StatefulWidget {
  const AnalysisContributionHeatmap({
    super.key,
    required this.contributionData,
  });

  final Map<String, int> contributionData;

  static const _weeks = 52;
  static const _gap = 5.0;

  @override
  State<AnalysisContributionHeatmap> createState() => _AnalysisContributionHeatmapState();
}

class _AnalysisContributionHeatmapState extends State<AnalysisContributionHeatmap> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < AnalysisTheme.heatmapCompactBreakpoint;
        final gridData = _buildGridData();
        final monthLabels = _monthLabels(gridData);

        Widget dayLabels({required bool onRight}) {
          return Padding(
            padding: EdgeInsets.only(left: onRight ? 8 : 0, right: onRight ? 0 : 8),
            child: Column(
              children: const [
                SizedBox(height: 10),
                Text('Mon', style: TextStyle(fontSize: 12, color: Color(0xFF666666), height: 1)),
                SizedBox(height: 10),
                Text('Wed', style: TextStyle(fontSize: 12, color: Color(0xFF666666), height: 1)),
                SizedBox(height: 10),
                Text('Fri', style: TextStyle(fontSize: 12, color: Color(0xFF666666), height: 1)),
                SizedBox(height: 10),
              ],
            ),
          );
        }

        final gridRow = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!compact) dayLabels(onRight: false),
            Expanded(
              child: Row(
                children: [
                  for (var w = 0; w < gridData.length; w++) ...[
                    if (w > 0) SizedBox(width: AnalysisContributionHeatmap._gap),
                    Expanded(
                      child: Column(
                        children: [
                          for (var d = 0; d < 7; d++) ...[
                            if (d > 0) SizedBox(height: AnalysisContributionHeatmap._gap),
                            AspectRatio(
                              aspectRatio: 1,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _colorFor(gridData[w][d].count),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (compact) dayLabels(onRight: true),
          ],
        );

        final body = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 20,
              child: Stack(
                children: [
                  for (final label in monthLabels)
                    Positioned(
                      left: label.offset,
                      child: Text(label.month, style: const TextStyle(fontSize: 12, color: Color(0xFF666666))),
                    ),
                ],
              ),
            ),
            gridRow,
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('Less', style: TextStyle(fontSize: 12, color: Color(0xFF666666))),
                const SizedBox(width: 8),
                for (final c in [0, 1, 3, 6, 9]) ...[
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    decoration: BoxDecoration(
                      color: _colorFor(c),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                const Text('More', style: TextStyle(fontSize: 12, color: Color(0xFF666666))),
              ],
            ),
          ],
        );

        if (!compact) {
          return Padding(padding: const EdgeInsets.all(16), child: body);
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
          }
        });

        return Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: AnalysisContributionHeatmap._weeks * 19.0,
              child: body,
            ),
          ),
        );
      },
    );
  }

  List<List<({String date, int count})>> _buildGridData() {
    final today = DateTime.now();
    final start = today.subtract(Duration(days: AnalysisContributionHeatmap._weeks * 7));
    final startSunday = start.subtract(Duration(days: start.weekday % 7));
    final weeks = <List<({String date, int count})>>[];

    for (var w = 0; w < AnalysisContributionHeatmap._weeks; w++) {
      final week = <({String date, int count})>[];
      for (var d = 0; d < 7; d++) {
        final date = startSunday.add(Duration(days: w * 7 + d));
        final key =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        week.add((date: key, count: widget.contributionData[key] ?? 0));
      }
      weeks.add(week);
    }
    return weeks;
  }

  List<({String month, double offset})> _monthLabels(List<List<({String date, int count})>> weeks) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final labels = <({String month, double offset})>[];
    var lastMonth = -1;
    for (var i = 0; i < weeks.length; i++) {
      final date = DateTime.parse(weeks[i].first.date);
      if (date.month != lastMonth) {
        labels.add((month: months[date.month - 1], offset: i * 19.0));
        lastMonth = date.month;
      }
    }
    return labels;
  }

  Color _colorFor(int count) {
    if (count == 0) return const Color(0xFFEBEDF0);
    if (count < 3) return const Color(0xFF9BE9A8);
    if (count < 6) return const Color(0xFF40C463);
    if (count < 9) return const Color(0xFF30A14E);
    return const Color(0xFF216E39);
  }
}
