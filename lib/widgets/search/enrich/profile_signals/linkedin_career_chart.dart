import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

String formatProfileSignalDuration(String duration) {
  if (duration.isEmpty) return '';

  final match = RegExp(
    r'^(\d{4})\.(\d{1,2})\s*-\s*(\d{4}|Present)(?:\.(\d{1,2}))?$',
    caseSensitive: false,
  ).firstMatch(duration);
  if (match == null) return duration;

  final startYear = int.parse(match.group(1)!);
  final startMonth = int.parse(match.group(2)!) - 1;

  int endYear;
  int endMonth;
  if (match.group(3)!.toLowerCase() == 'present') {
    final now = DateTime.now();
    endYear = now.year;
    endMonth = now.month - 1;
  } else {
    endYear = int.parse(match.group(3)!);
    endMonth = match.group(4) != null ? int.parse(match.group(4)!) - 1 : 11;
  }

  final totalMonths = (endYear - startYear) * 12 + (endMonth - startMonth);
  final years = totalMonths ~/ 12;
  final months = totalMonths % 12;

  if (years == 0) return months == 1 ? '1 mo' : '$months mos';
  if (months == 0) return years == 1 ? '1 yr' : '$years yrs';
  final yrStr = years == 1 ? '1 yr' : '$years yrs';
  final moStr = months == 1 ? '1 mo' : '$months mos';
  return '$yrStr $moStr';
}

class LinkedInCareerChart extends StatefulWidget {
  const LinkedInCareerChart({
    super.key,
    required this.careerJourney,
    this.onNodeTap,
  });

  final List<Map<String, dynamic>> careerJourney;
  final VoidCallback? onNodeTap;

  @override
  State<LinkedInCareerChart> createState() => _LinkedInCareerChartState();
}

class _LinkedInCareerChartState extends State<LinkedInCareerChart> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final careerJourney = widget.careerJourney;
    if (careerJourney.isEmpty) {
      return const Center(child: Text('No career data'));
    }

    final chartData = careerJourney.map((item) {
      return {
        'year': item['year'] as int,
        'score': (item['score'] as num?)?.toDouble() ?? 0.0,
        'name': item['name']?.toString() ?? '',
        'position': item['position']?.toString() ?? '',
        'duration': item['duration']?.toString() ?? '',
        'logo': item['logo']?.toString(),
      };
    }).toList();

    final scores = chartData.map((d) => d['score'] as double).toList();
    final minScore = scores.reduce((a, b) => a < b ? a : b);
    final maxScore = scores.reduce((a, b) => a > b ? a : b);
    final yMin = ((minScore - 5).clamp(0, double.infinity)).toDouble();
    final yMax = (maxScore + 5).toDouble();

    return LayoutBuilder(
      builder: (context, constraints) {
        const horizontalPadding = 20.0;
        const marginBottom = 30.0;

        final chartWidth = constraints.maxWidth;
        final chartHeight = constraints.maxHeight;
        final plotWidth = chartWidth - horizontalPadding * 2;
        final plotHeight = chartHeight - marginBottom;

        final maxLabels =
            (plotWidth / 48).floor().clamp(1, chartData.length);
        final labelStep = (chartData.length / maxLabels).ceil();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              IgnorePointer(
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      drawHorizontalLine: false,
                      getDrawingVerticalLine: (value) {
                        return const FlLine(
                          color: Color(0xFFA5A5A5),
                          strokeWidth: 1,
                          dashArray: [3, 3],
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            final showLabel =
                                (chartData.length - 1 - index) % labelStep == 0;
                            if (index >= 0 &&
                                index < chartData.length &&
                                showLabel) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  '${chartData[index]['year']}',
                                  style: const TextStyle(
                                    color: Color(0xFF9CA3AF),
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: (chartData.length - 1).toDouble(),
                    minY: yMin,
                    maxY: yMax,
                    lineBarsData: [
                      LineChartBarData(
                        spots: chartData.asMap().entries.map((entry) {
                          return FlSpot(
                            entry.key.toDouble(),
                            entry.value['score'] as double,
                          );
                        }).toList(),
                        isCurved: true,
                        curveSmoothness: 0.35,
                        color: const Color(0xFF171717),
                        barWidth: 1,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              const Color(0xFFCCE5FF).withValues(alpha: 1.0),
                              const Color(0xFFCCE5FF).withValues(alpha: 0.1),
                            ],
                            stops: const [0.05, 0.95],
                          ),
                        ),
                      ),
                    ],
                    lineTouchData: const LineTouchData(enabled: false),
                  ),
                ),
              ),
              ...chartData.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final logo = item['logo']?.toString();
                final score = item['score'] as double;

                final xRatio = chartData.length > 1
                    ? index / (chartData.length - 1)
                    : 0.5;
                final xPos = plotWidth * xRatio;
                final yRatio = (score - yMin) / (yMax - yMin);
                final yPos = plotHeight - (plotHeight * yRatio);

                return Positioned(
                  left: xPos - 15,
                  top: yPos - 15,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      setState(() {
                        _selectedIndex = _selectedIndex == index ? null : index;
                      });
                      widget.onNodeTap?.call();
                    },
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFF3F4F6),
                        border: Border.all(
                          color: const Color(0xFF171717),
                          width: 1,
                        ),
                      ),
                      child: ClipOval(
                        child: logo != null && logo.isNotEmpty
                            ? Image.network(
                                logo,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.asset(
                                    'assets/images/defaultCompany.png',
                                    fit: BoxFit.cover,
                                  );
                                },
                              )
                            : Image.asset(
                                'assets/images/defaultCompany.png',
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                  ),
                );
              }),
              if (_selectedIndex != null &&
                  _selectedIndex! >= 0 &&
                  _selectedIndex! < chartData.length)
                _buildTooltip(
                  chartData[_selectedIndex!],
                  plotWidth: plotWidth,
                  plotHeight: plotHeight,
                  index: _selectedIndex!,
                  chartDataLength: chartData.length,
                  yMin: yMin,
                  yMax: yMax,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTooltip(
    Map<String, dynamic> item, {
    required double plotWidth,
    required double plotHeight,
    required int index,
    required int chartDataLength,
    required double yMin,
    required double yMax,
  }) {
    final score = item['score'] as double;
    final xRatio = chartDataLength > 1 ? index / (chartDataLength - 1) : 0.5;
    final xPos = plotWidth * xRatio;
    final yRatio = (score - yMin) / (yMax - yMin);
    final yPos = plotHeight - (plotHeight * yRatio);

    final name = item['name']?.toString() ?? '';
    final position = item['position']?.toString() ?? '';
    final duration = formatProfileSignalDuration(
      item['duration']?.toString() ?? '',
    );

    return Positioned(
      left: (xPos - 72).clamp(0, plotWidth - 144),
      top: (yPos - 72).clamp(0, plotHeight - 56),
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              if (position.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  position,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF4B5563),
                  ),
                ),
              ],
              if (duration.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  duration,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
