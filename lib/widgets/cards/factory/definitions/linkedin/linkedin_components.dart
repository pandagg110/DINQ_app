import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'linkedin_utils.dart';

class LinkedInComponents {
  // Organization Logo component
  static Widget buildOrgLogo({
    required String? logo,
    required String name,
    String size = 'md',
  }) {
    final sizeValue = size == 'sm' ? 20.0 : size == 'lg' ? 40.0 : 32.0;
    final displayLogo = (logo?.isNotEmpty == true) ? logo! : '/images/defaultCompany.png';

    return Container(
      width: sizeValue,
      height: sizeValue,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[100],
        border: Border.all(color: const Color(0xFF171717), width: 1),
      ),
      child: ClipOval(
        child: Image.network(
          displayLogo,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Image.asset(
              'assets/images/defaultCompany.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.business, size: 16),
                );
              },
            );
          },
        ),
      ),
    );
  }

  // Avatar Group for 2x2 layout
  static Widget buildAvatarGroup({
    required List<Map<String, dynamic>> careerJourney,
  }) {
    return Wrap(
      spacing: -16,
      children: careerJourney.take(7).map((item) {
        return Container(
          margin: const EdgeInsets.only(right: 16),
          child: buildOrgLogo(
            logo: item['logo']?.toString(),
            name: item['name']?.toString() ?? '',
            size: 'md',
          ),
        );
      }).toList(),
    );
  }

  // Vertical Timeline for 2x4 layout
  static Widget buildVerticalTimeline({
    required List<Map<String, dynamic>> careerJourney,
  }) {
    if (careerJourney.isEmpty) {
      return const Center(child: Text('No career data'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        
        // Calculate positions based on years
        final years = careerJourney.map((item) => item['year'] as int).toList();
        final minYear = years.reduce((a, b) => a < b ? a : b);
        final maxYear = years.reduce((a, b) => a > b ? a : b);
        final yearSpan = maxYear - minYear;

        // Calculate positions
        List<double> positions;
        if (yearSpan == 0 || careerJourney.length == 1) {
          if (careerJourney.length == 1) {
            positions = [0.5];
          } else {
            positions = List.generate(
              careerJourney.length,
              (i) => i / (careerJourney.length - 1),
            );
          }
        } else {
          final minSpan = yearSpan > (careerJourney.length - 1) * 3
              ? yearSpan
              : (careerJourney.length - 1) * 3;
          final maxSpan = (careerJourney.length - 1) * 6;
          final normalizedSpan = minSpan < maxSpan ? minSpan : maxSpan;

          positions = careerJourney.map((item) {
            final yearOffset = (item['year'] as int) - minYear;
            final scaledOffset = (yearOffset / yearSpan) * normalizedSpan;
            return scaledOffset / normalizedSpan;
          }).toList();
        }

        // Adjust positions for minimum spacing
        const minGapPx = 48.0;
        final minGapPercent = (minGapPx / height) * 100;

        final adjustedPositions = [...positions];
        for (int i = 1; i < adjustedPositions.length; i++) {
          final prevPos = adjustedPositions[i - 1];
          final currentPos = adjustedPositions[i];
          final gap = (currentPos - prevPos) * 100;

          if (gap < minGapPercent) {
            adjustedPositions[i] = prevPos + minGapPercent / 100;
          }
        }

        // Normalize to fit within safe margins (5% to 95%)
        const safeMargin = 5.0;
        const usableRange = 90.0;
        final minPos = adjustedPositions.reduce((a, b) => a < b ? a : b);
        final maxPos = adjustedPositions.reduce((a, b) => a > b ? a : b);
        final posRange = maxPos - minPos;

        final finalPositions = adjustedPositions.map((pos) {
          if (careerJourney.length == 1) return height * 0.5;
          final normalized = (pos - minPos) / posRange;
          return (safeMargin + normalized * usableRange) / 100 * height;
        }).toList();

        return Stack(
          children: [
            // Vertical Timeline Line
            if (careerJourney.length > 1)
              Positioned(
                left: 16,
                top: finalPositions[0],
                bottom: height - finalPositions[finalPositions.length - 1],
                child: Container(
                  width: 1,
                  color: const Color(0xFF171717),
                ),
              ),
            
            // Timeline Nodes
            ...careerJourney.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Positioned(
                left: 0,
                top: finalPositions[index] - 16,
                child: Row(
                  children: [
                    buildOrgLogo(
                      logo: item['logo']?.toString(),
                      name: item['name']?.toString() ?? '',
                      size: 'md',
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${item['year']}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9CA3AF),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }

  // Horizontal Timeline for 4x2 layout
  static Widget buildHorizontalTimeline({
    required List<Map<String, dynamic>> careerJourney,
  }) {
    if (careerJourney.isEmpty) {
      return const Center(child: Text('No career data'));
    }

    // Calculate positions (similar logic to vertical)
    final years = careerJourney.map((item) => item['year'] as int).toList();
    final minYear = years.reduce((a, b) => a < b ? a : b);
    final maxYear = years.reduce((a, b) => a > b ? a : b);
    final yearSpan = maxYear - minYear;

    List<double> positions;
    if (yearSpan == 0) {
      if (careerJourney.length == 1) {
        positions = [0.0];
      } else {
        positions = List.generate(
          careerJourney.length,
          (i) => i / (careerJourney.length - 1),
        );
      }
    } else {
      final minSpan = yearSpan > (careerJourney.length - 1) * 4
          ? yearSpan
          : (careerJourney.length - 1) * 4;
      final maxSpan = (careerJourney.length - 1) * 8;
      final normalizedSpan = minSpan < maxSpan ? minSpan : maxSpan;

      positions = careerJourney.map((item) {
        final yearOffset = (item['year'] as int) - minYear;
        final scaledOffset = (yearOffset / yearSpan) * normalizedSpan;
        return scaledOffset / normalizedSpan;
      }).toList();
    }

    // Adjust for minimum spacing
    const estimatedWidth = 600.0;
    const minGapPx = 72.0;
    final minGapPercent = (minGapPx / estimatedWidth) * 100;

    final adjustedPositions = [...positions];
    for (int i = 1; i < adjustedPositions.length; i++) {
      final prevPos = adjustedPositions[i - 1];
      final currentPos = adjustedPositions[i];
      final gap = (currentPos - prevPos) * 100;

      if (gap < minGapPercent) {
        adjustedPositions[i] = prevPos + minGapPercent / 100;
      }
    }

    // Normalize
    const safeMargin = 5.0;
    const usableRange = 90.0;
    final minPos = adjustedPositions.reduce((a, b) => a < b ? a : b);
    final maxPos = adjustedPositions.reduce((a, b) => a > b ? a : b);
    final posRange = maxPos - minPos;

    final finalPositions = adjustedPositions.map((pos) {
      if (careerJourney.length == 1) return 50.0;
      final normalized = (pos - minPos) / posRange;
      return safeMargin + normalized * usableRange;
    }).toList();

    return Stack(
      children: [
        // Horizontal Timeline Line
        Positioned(
          left: 16,
          right: 16,
          top: 16,
          child: Container(
            height: 1,
            color: const Color(0xFF171717),
          ),
        ),
        
        // Timeline Nodes
        ...careerJourney.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Positioned(
            left: finalPositions[index] - 16,
            top: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                buildOrgLogo(
                  logo: item['logo']?.toString(),
                  name: item['name']?.toString() ?? '',
                  size: 'md',
                ),
                const SizedBox(height: 8),
                Text(
                  '${item['year']}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // Career Chart for 4x4 layout using fl_chart
  static Widget buildCareerChart({
    required List<Map<String, dynamic>> careerJourney,
  }) {
    if (careerJourney.isEmpty) {
      return const Center(child: Text('No career data'));
    }

    // Prepare chart data
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

    // Get min/max values for Y axis
    final scores = chartData.map((d) => d['score'] as double).toList();
    final minScore = scores.reduce((a, b) => a < b ? a : b);
    final maxScore = scores.reduce((a, b) => a > b ? a : b);
    final yMin = ((minScore - 5).clamp(0, double.infinity)).toDouble();
    final yMax = (maxScore + 5).toDouble();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Add horizontal padding to ensure chart and logos are fully visible
        const horizontalPadding = 20.0;
        const marginBottom = 30.0; // Reserved for bottom titles
        
        final chartWidth = constraints.maxWidth;
        final chartHeight = constraints.maxHeight;
        final plotWidth = chartWidth - horizontalPadding * 2;
        final plotHeight = chartHeight - marginBottom;
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              LineChart(
        LineChartData(
          gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          drawHorizontalLine: false,
          horizontalInterval: 1,
          verticalInterval: 1,
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: const Color(0xFFA5A5A5),
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
                if (index >= 0 && index < chartData.length) {
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
              return FlSpot(entry.key.toDouble(), entry.value['score'] as double);
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
                  const Color(0xFFCCE5FF).withOpacity(1.0),
                  const Color(0xFFCCE5FF).withOpacity(0.1),
                ],
                stops: const [0.05, 0.95],
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((LineBarSpot touchedSpot) {
                final index = touchedSpot.x.toInt();
                if (index >= 0 && index < chartData.length) {
                  final item = chartData[index];
                  return LineTooltipItem(
                    '${item['name']}\n${item['position'] != null && item['position'].toString().isNotEmpty ? '${item['position']}\n' : ''}${formatDuration(item['duration'].toString())}',
                    const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }
                return null;
              }).toList();
            },
            tooltipRoundedRadius: 8,
            tooltipPadding: const EdgeInsets.all(12),
            tooltipBorder: const BorderSide(
              color: Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
        ),
        ),
              ),
              // Overlay company logos on chart dots
              ...chartData.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final logo = item['logo']?.toString();
                final score = item['score'] as double;
                
                // Calculate X position (based on index)
                final xRatio = chartData.length > 1 
                    ? index / (chartData.length - 1) 
                    : 0.5;
                final xPos = plotWidth * xRatio;
                
                // Calculate Y position (based on score, inverted because Y=0 is at top)
                final yRatio = (score - yMin) / (yMax - yMin);
                final yPos = plotHeight - (plotHeight * yRatio);
                
                return Positioned(
                  left: xPos - 15, // Center the 30px logo
                  top: yPos - 15, // Center the 30px logo
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
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.business, size: 16);
                                  },
                                );
                              },
                            )
                          : Image.asset(
                              'assets/images/defaultCompany.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.business, size: 16);
                              },
                            ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

