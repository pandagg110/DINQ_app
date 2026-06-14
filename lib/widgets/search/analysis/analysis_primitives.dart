import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'analysis_format.dart';
import 'analysis_theme.dart';

/// 与 TSX `SegmentTable.tsx` 对齐。
class AnalysisSegmentTable extends StatelessWidget {
  const AnalysisSegmentTable({super.key, required this.items});

  final List<AnalysisSegmentItem> items;

  static const _valueStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    fontFamily: AnalysisTheme.fontUdc,
    color: Colors.black,
    height: 1.1,
  );

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final colWidth = constraints.maxWidth / 3;
        return Row(
          children: [
            for (var i = 0; i < items.length; i++)
              SizedBox(
                width: colWidth,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              AnalysisFormat.formatThousand(items[i].value),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              softWrap: false,
                              style: _valueStyle,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            items[i].label,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                          ),
                        ],
                      ),
                    ),
                    if (i < items.length - 1)
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
              ),
          ],
        );
      },
    );
  }
}

class AnalysisSegmentItem {
  const AnalysisSegmentItem({required this.label, required this.value});

  final String label;
  final dynamic value;
}

/// 与 TSX `BarLineChart.tsx` 对齐：Papers 柱状 + Citations 折线 + 图例。
class AnalysisPapersBarLineChart extends StatelessWidget {
  const AnalysisPapersBarLineChart({
    super.key,
    required this.yearlyPapers,
    required this.yearlyCitations,
  });

  final Map<String, dynamic> yearlyPapers;
  final Map<String, dynamic> yearlyCitations;

  static const _paperColor = Color(0xFFC3DCFF);
  static const _lineStart = Color(0xFF5BC4FF);
  static const _lineEnd = Color(0xFFFF5BEF);
  static const _dotBorder = Color(0xFFAE8FF7);
  static const _leftAxisWidth = 52.0;
  static const _bottomAxisHeight = 28.0;
  static const _topLabelSpace = 22.0;

  @override
  Widget build(BuildContext context) {
    final years = _allYears();
    if (years.isEmpty) {
      return const SizedBox(height: 280);
    }

    final paperValues = years.map((y) => _readNum(yearlyPapers[y])).toList();
    final citationValues = years.map((y) => _readNum(yearlyCitations[y])).toList();
    final paperMax = _maxAxis(paperValues);
    final citationMax = _maxAxis(citationValues);
    final count = years.length;

    return SizedBox(
      height: 280,
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final plotWidth = constraints.maxWidth - _leftAxisWidth;
                final plotHeight =
                    constraints.maxHeight - _bottomAxisHeight - _topLabelSpace;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        left: _leftAxisWidth,
                        bottom: _bottomAxisHeight,
                        top: _topLabelSpace,
                      ),
                      child: SizedBox(
                        width: plotWidth,
                        height: plotHeight,
                        child: Stack(
                          children: [
                            BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: paperMax,
                                minY: 0,
                                gridData: const FlGridData(show: false),
                                borderData: FlBorderData(show: false),
                                titlesData: const FlTitlesData(show: false),
                                barTouchData: BarTouchData(enabled: false),
                                barGroups: [
                                  for (var i = 0; i < count; i++)
                                    BarChartGroupData(
                                      x: i,
                                      barRods: [
                                        BarChartRodData(
                                          toY: paperValues[i],
                                          color: _paperColor,
                                          width: 18,
                                          borderRadius: const BorderRadius.vertical(
                                            top: Radius.circular(8),
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                            LineChart(
                              LineChartData(
                                minX: 0,
                                maxX: (count - 1).toDouble(),
                                minY: 0,
                                maxY: citationMax,
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  horizontalInterval: citationMax / 3,
                                  getDrawingHorizontalLine: (_) => const FlLine(
                                    color: Color(0xFFE5E5E5),
                                    strokeWidth: 1,
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                titlesData: const FlTitlesData(show: false),
                                lineTouchData: LineTouchData(enabled: false),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: [
                                      for (var i = 0; i < count; i++)
                                        FlSpot(i.toDouble(), citationValues[i]),
                                    ],
                                    isCurved: true,
                                    barWidth: 3,
                                    dotData: FlDotData(
                                      show: true,
                                      getDotPainter: (_, __, ___, ____) =>
                                          FlDotCirclePainter(
                                        radius: 4,
                                        color: Colors.white,
                                        strokeWidth: 3,
                                        strokeColor: _dotBorder,
                                      ),
                                    ),
                                    belowBarData: BarAreaData(show: false),
                                    gradient: const LinearGradient(
                                      colors: [_lineStart, _lineEnd],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    for (var i = 0; i < count; i++)
                      _BarValueLabel(
                        index: i,
                        count: count,
                        value: paperValues[i],
                        paperMax: paperMax,
                        leftAxisWidth: _leftAxisWidth,
                        plotWidth: plotWidth,
                        plotHeight: plotHeight,
                        topLabelSpace: _topLabelSpace,
                      ),
                    Positioned(
                      left: 0,
                      top: _topLabelSpace,
                      bottom: _bottomAxisHeight,
                      width: _leftAxisWidth,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (final tick in _yTicks(citationMax))
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Text(
                                AnalysisFormat.formatThousand(tick),
                                maxLines: 1,
                                softWrap: false,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF666666),
                                  height: 1,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: _leftAxisWidth,
                      right: 0,
                      bottom: 0,
                      height: _bottomAxisHeight,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          for (final year in years)
                            Text(
                              year,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF666666),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              _LegendDot(color: _paperColor, label: 'Papers'),
              SizedBox(width: 16),
              _LegendDot(
                color: _dotBorder,
                label: 'Citations',
                isLine: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<int> _yTicks(double max) {
    final step = max / 3;
    return [
      max.round(),
      (step * 2).round(),
      step.round(),
      0,
    ];
  }

  List<String> _allYears() {
    final currentYear = DateTime.now().year;
    final years = <int>{
      ...yearlyPapers.keys.map((k) => int.tryParse(k)).whereType<int>(),
      ...yearlyCitations.keys.map((k) => int.tryParse(k)).whereType<int>(),
    }.where((y) => y >= currentYear - 10 && y <= currentYear).toList()
      ..sort();
    return years.map((y) => y.toString()).toList();
  }

  double _readNum(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _maxAxis(List<double> values) {
    if (values.isEmpty) return 30;
    final maxValue = values.reduce(math.max);
    if (maxValue <= 0) return 30;
    final rawInterval = maxValue / 3;
    final magnitude = math.pow(10, (math.log(rawInterval) / math.ln10).floor()).toDouble();
    for (final m in [1.0, 2.0, 5.0, 10.0]) {
      final candidate = magnitude * m;
      if (candidate >= rawInterval) return candidate * 3;
    }
    return magnitude * 3;
  }
}

class _BarValueLabel extends StatelessWidget {
  const _BarValueLabel({
    required this.index,
    required this.count,
    required this.value,
    required this.paperMax,
    required this.leftAxisWidth,
    required this.plotWidth,
    required this.plotHeight,
    required this.topLabelSpace,
  });

  final int index;
  final int count;
  final double value;
  final double paperMax;
  final double leftAxisWidth;
  final double plotWidth;
  final double plotHeight;
  final double topLabelSpace;

  @override
  Widget build(BuildContext context) {
    if (value <= 0) return const SizedBox.shrink();

    final slotWidth = plotWidth / count;
    final xCenter = leftAxisWidth + slotWidth * (index + 0.5);
    final barTop = topLabelSpace + plotHeight * (1 - value / paperMax);

    return Positioned(
      left: xCenter - 16,
      top: barTop - 20,
      width: 32,
      child: Text(
        value.toInt().toString(),
        textAlign: TextAlign.center,
        maxLines: 1,
        style: const TextStyle(fontSize: 12, color: Color(0xFF666666), height: 1),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label, this.isLine = false});

  final Color color;
  final String label;
  final bool isLine;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLine)
          Container(
            width: 16,
            height: 8,
            alignment: Alignment.center,
            child: Container(
              width: 16,
              height: 2,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF5BC4FF),
                    Color(0xFFFF5BEF),
                  ],
                ),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          )
        else
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF666666))),
      ],
    );
  }
}

/// 与 TSX `DonutChart.tsx` 简化对齐。
class AnalysisDonutChart extends StatelessWidget {
  const AnalysisDonutChart({
    super.key,
    required this.conferenceDistribution,
    this.topTierPapers,
  });

  final Map<String, dynamic> conferenceDistribution;
  final num? topTierPapers;

  static const _colors = [
    Color(0xFF7F95CE),
    Color(0xFFD2CEC4),
    Color(0xFFCB7C5D),
    Color(0xFFF8E9C8),
  ];

  @override
  Widget build(BuildContext context) {
    final entries = _processedEntries();
    if (entries.isEmpty) return const SizedBox(height: 170);

    final centerValue = topTierPapers ?? entries.fold<num>(0, (s, e) => s + e.value);

    return SizedBox(
      height: 170,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 52,
              sections: [
                for (var i = 0; i < entries.length; i++)
                  PieChartSectionData(
                    value: entries[i].value.toDouble(),
                    color: _colors[i % _colors.length],
                    radius: 28,
                    title: '',
                  ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AnalysisFormat.formatThousand(centerValue),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF030229),
                ),
              ),
              const Text(
                'Top Tier',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xB3030229),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<({String name, num value})> _processedEntries() {
    final raw = conferenceDistribution.entries
        .map((e) => (name: e.key, value: num.tryParse('${e.value}') ?? 0))
        .where((e) => e.value > 0 && e.name.toLowerCase() != 'others')
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (raw.isEmpty) return [];
    if (raw.length <= 3) return raw;
    final top3 = raw.take(3).toList();
    final others = raw.skip(3).fold<num>(0, (s, e) => s + e.value);
    if (others > 0) top3.add((name: 'Others', value: others));
    return top3;
  }
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

/// 与 TSX `LanguageDonutChart.tsx` 对齐。
class AnalysisLanguageDonutChart extends StatelessWidget {
  const AnalysisLanguageDonutChart({
    super.key,
    required this.languages,
    required this.total,
  });

  final Map<String, dynamic> languages;
  final num total;

  static const _colors = [
    Color(0xFF7F95CE),
    Color(0xFFD2CEC4),
    Color(0xFFCB7C5D),
    Color(0xFFF8E9C8),
    Color(0xFFB89EDA),
    Color(0xFFA8C5A8),
    Color(0xFFF4A6A6),
    Color(0xFFFFD88C),
  ];

  @override
  Widget build(BuildContext context) {
    final entries = _processedEntries();
    if (entries.isEmpty) return const SizedBox.expand();

    final centerText = total >= 1000000
        ? '${(total / 1000000).toStringAsFixed(1)}M'
        : total >= 1000
            ? '${(total / 1000).toStringAsFixed(1)}K'
            : '$total';

    return Column(
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 48,
                  sections: [
                    for (var i = 0; i < entries.length; i++)
                      PieChartSectionData(
                        value: entries[i].value.toDouble(),
                        color: _colors[i % _colors.length],
                        radius: 36,
                        title: '',
                      ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    centerText,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF030229),
                    ),
                  ),
                  const Text(
                    'Total Code',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 8,
          children: [
            for (var i = 0; i < entries.length; i++)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: _colors[i % _colors.length],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    entries[i].name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF030229)),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  List<({String name, num value})> _processedEntries() {
    final raw = languages.entries
        .map((e) => (name: e.key, value: num.tryParse('${e.value}') ?? 0))
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (raw.isEmpty) return [];
    if (raw.length <= 4) return raw;
    final top4 = raw.take(4).toList();
    final top4Sum = top4.fold<num>(0, (s, e) => s + e.value);
    final others = total - top4Sum;
    if (others > 0) top4.add((name: 'Others', value: others));
    return top4;
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
