import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_echarts/flutter_echarts.dart';

/// 与 TSX `DonutChart.tsx` + ECharts option 对齐。
class AnalysisDonutChart extends StatelessWidget {
  const AnalysisDonutChart({
    super.key,
    required this.conferenceDistribution,
    this.topTierPapers,
    this.size = AnalysisDonutChartSize.large,
  });

  final Map<String, dynamic> conferenceDistribution;
  final num? topTierPapers;
  final AnalysisDonutChartSize size;

  static const _colors = ['#7F95CE', '#D2CEC4', '#CB7C5D', '#F8E9C8'];

  @override
  Widget build(BuildContext context) {
    final processed = _processedData();
    if (processed.isEmpty) {
      return SizedBox(height: size == AnalysisDonutChartSize.small ? 150 : 170);
    }

    final total = _totalTopTierPapers(processed);
    final option = _buildOption(processed, total);
    final height = size == AnalysisDonutChartSize.small ? 150.0 : 170.0;

    return Align(
      alignment: Alignment.center,
      child: SizedBox(
        width: MediaQuery.sizeOf(context).width * 0.85,
        height: height,
        child: Echarts(
          option: option,
          reloadAfterInit: true,
        ),
      ),
    );
  }

  String _buildOption(List<({String name, num value})> data, num total) {
    final seriesData = [
      for (var i = 0; i < data.length; i++)
        {
          'name': data[i].name,
          'value': data[i].value,
          'label': _outsideLabel(i),
        },
    ];

    return jsonEncode({
      'animation': false,
      'color': _colors,
      'backgroundColor': 'transparent',
      'textStyle': {'fontFamily': 'Poppins'},
      'grid': {'top': 20, 'right': 20, 'bottom': 20, 'left': 20, 'containLabel': true},
      'legend': {'show': false},
      'series': [
        {
          'name': 'Publications',
          'type': 'pie',
          'radius': ['50%', '70%'],
          'center': ['50%', '50%'],
          'startAngle': 45,
          'avoidLabelOverlap': true,
          'label': {'alignTo': 'edge', 'edgeDistance': 10},
          'labelLine': {
            'show': true,
            'length': 2,
            'length2': 2,
            'smooth': true,
            'lineStyle': {'width': 1, 'color': '#ccc'},
          },
          'emphasis': {
            'label': {'show': true, 'fontSize': 16, 'fontWeight': 'bold', 'fontFamily': 'Poppins'},
          },
          'data': seriesData,
        },
      ],
      'graphic': [
        {
          'type': 'text',
          'left': 'center',
          'top': '43%',
          'style': {
            'text': _formatNumber(total),
            'textAlign': 'center',
            'fill': '#030229',
            'fontSize': 20,
            'fontWeight': '700',
            'fontFamily': 'Poppins',
          },
        },
        {
          'type': 'text',
          'left': 'center',
          'top': '54%',
          'style': {
            'text': 'Top Tier',
            'textAlign': 'center',
            'fill': 'rgba(3, 2, 41, 0.7)',
            'fontSize': 11,
            'fontWeight': '500',
            'fontFamily': 'Poppins',
          },
        },
      ],
    });
  }

  Map<String, dynamic> _outsideLabel(int index) {
    return {
      'show': true,
      'position': 'outside',
      'distanceToLabelLine': 5,
      'formatter': '{bar|}\n{name|{b}}\n{value|{c}} {percent|{d}%}',
      'fontSize': 14,
      'fontFamily': 'Poppins',
      'color': '#030229',
      'backgroundColor': '#FAF2EF',
      'width': 100,
      'height': 50,
      'rich': {
        'bar': {
          'height': 4,
          'width': '100%',
          'backgroundColor': _colors[index % _colors.length],
        },
        'name': {
          'fontSize': 11,
          'align': 'center',
          'padding': [8, 8, 6, 8],
          'fontFamily': 'Poppins',
        },
        'value': {
          'fontSize': 11,
          'align': 'left',
          'padding': [0, 8, 0, 8],
          'fontFamily': 'Poppins',
        },
        'percent': {
          'fontSize': 11,
          'align': 'right',
          'padding': [0, 8, 0, 8],
          'fontFamily': 'Poppins',
        },
      },
    };
  }

  List<({String name, num value})> _rawData() {
    return conferenceDistribution.entries
        .map((e) => (name: e.key, value: num.tryParse('${e.value}') ?? 0))
        .toList();
  }

  num _totalTopTierPapers(List<({String name, num value})> raw) {
    if (topTierPapers != null) return topTierPapers!;
    return raw.fold<num>(0, (sum, item) => sum + item.value);
  }

  /// 与 TSX `processedData` 对齐。
  List<({String name, num value})> _processedData() {
    final raw = _rawData();
    final total = _totalTopTierPapers(raw);

    final filtered = raw.where((item) => item.name.toLowerCase() != 'others').toList()
      ..sort((a, b) {
        if (b.value != a.value) return b.value.compareTo(a.value);
        return a.name.compareTo(b.name);
      });

    if (filtered.isEmpty) return [];

    final List<({String name, num value})> finalData;
    if (filtered.length <= 3) {
      ({String name, num value})? backendOthers;
      for (final item in raw) {
        if (item.name.toLowerCase() == 'others') {
          backendOthers = item;
          break;
        }
      }
      final backendOthersValue = backendOthers?.value ?? 0;
      final specificSum = filtered.fold<num>(0, (s, it) => s + it.value);
      final calculatedOthers = (total - specificSum).clamp(0, double.infinity);
      final finalOthersValue = backendOthersValue > calculatedOthers ? backendOthersValue : calculatedOthers;
      if (finalOthersValue > 0) {
        finalData = [...filtered, (name: 'Others', value: finalOthersValue)];
      } else {
        finalData = filtered;
      }
    } else {
      final top3 = filtered.take(3).toList();
      final top3Sum = top3.fold<num>(0, (s, it) => s + it.value);
      final othersValue = (total - top3Sum).clamp(0, double.infinity);
      finalData = [...top3, (name: 'Others', value: othersValue)];
    }

    if (finalData.length == 4) {
      return [finalData[0], finalData[2], finalData[1], finalData[3]];
    }
    return finalData;
  }

  String _formatNumber(num value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return '$value';
  }
}

enum AnalysisDonutChartSize { small, large }
