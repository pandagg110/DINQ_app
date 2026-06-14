import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_echarts/flutter_echarts.dart';

/// 与 TSX `BarLineChart.tsx` + ECharts option 对齐。
class AnalysisPapersBarLineChart extends StatelessWidget {
  const AnalysisPapersBarLineChart({
    super.key,
    required this.yearlyPapers,
    required this.yearlyCitations,
  });

  final Map<String, dynamic> yearlyPapers;
  final Map<String, dynamic> yearlyCitations;

  static const _chartHeight = 280.0;
  static const _splitNumber = 3;

  @override
  Widget build(BuildContext context) {
    final years = _allYears();
    if (years.isEmpty) {
      return const SizedBox(height: _chartHeight);
    }

    final option = _buildOption(years);

    return SizedBox(
      height: _chartHeight,
      width: double.infinity,
      child: Echarts(
        option: option,
        reloadAfterInit: true,
      ),
    );
  }

  String _buildOption(List<String> years) {
    final papersMax = _maxValue(yearlyPapers);
    final citationsMax = _maxValue(yearlyCitations);
    final paperSeries = _seriesData(yearlyPapers, years);
    final citationSeries = _seriesData(yearlyCitations, years);

    return jsonEncode({
      'legend': {
        'show': true,
        'bottom': 0,
        'textStyle': {'color': '#666', 'fontSize': 12},
      },
      'tooltip': {
        'trigger': 'axis',
        'position': 'top',
        'backgroundColor': 'rgba(0, 0, 0, 0.7)',
        'borderColor': 'transparent',
        'textStyle': {'color': '#FFF', 'fontSize': 12},
      },
      'grid': {
        'left': 10,
        'right': 10,
        'bottom': 42,
        'top': 20,
        'containLabel': true,
      },
      'xAxis': {
        'type': 'category',
        'data': years,
        'axisLine': {'show': false},
        'axisTick': {'show': false},
        'axisLabel': {
          'color': '#666',
          'fontSize': 12,
          'margin': 15,
        },
      },
      'yAxis': [
        {
          'type': 'value',
          'splitNumber': _splitNumber,
          'splitLine': {'show': false},
          'axisLine': {'show': false},
          'axisTick': {'show': false},
          'max': papersMax,
          'axisLabel': {'show': false},
        },
        {
          'type': 'value',
          'position': 'left',
          'splitNumber': _splitNumber,
          'splitLine': {
            'show': true,
            'lineStyle': {'color': '#E5E5E5', 'width': 1, 'type': 'solid'},
          },
          'axisLine': {'show': false},
          'axisTick': {'show': false},
          'max': citationsMax,
          'axisLabel': {'color': '#666', 'fontSize': 12},
        },
      ],
      'series': [
        {
          'name': 'Papers',
          'type': 'bar',
          'yAxisIndex': 0,
          'data': paperSeries,
          'itemStyle': {
            'color': '#C3DCFF',
            'borderRadius': [8, 8, 0, 0],
          },
          'label': {
            'show': true,
            'position': 'insideTop',
            'offset': [0, -20],
            'color': '#666',
            'fontSize': 12,
            'formatter': '{c}',
          },
        },
        {
          'name': 'Citations',
          'type': 'line',
          'yAxisIndex': 1,
          'smooth': true,
          'symbol': 'circle',
          'symbolSize': 8,
          'data': citationSeries,
          'lineStyle': {
            'width': 3,
            'color': {
              'type': 'linear',
              'x': 0,
              'y': 0,
              'x2': 1,
              'y2': 0,
              'colorStops': [
                {'offset': 0, 'color': '#5BC4FF'},
                {'offset': 1, 'color': '#FF5BEF'},
              ],
            },
          },
          'itemStyle': {
            'color': '#FFF',
            'borderColor': '#AE8FF7',
            'borderWidth': 3,
          },
        },
      ],
    });
  }

  List<String> _allYears() {
    final currentYear = DateTime.now().year;
    final tenYearsAgo = currentYear - 10;
    final years = <int>{
      ...yearlyPapers.keys.map((k) => int.tryParse(k.toString())).whereType<int>(),
      ...yearlyCitations.keys.map((k) => int.tryParse(k.toString())).whereType<int>(),
    }.where((y) => y >= tenYearsAgo && y <= currentYear).toList()
      ..sort();
    return years.map((y) => y.toString()).toList();
  }

  List<num> _seriesData(Map<String, dynamic> source, List<String> years) {
    return years.map((y) => _readNum(source[y])).toList();
  }

  num _readNum(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '') ?? 0;
  }

  /// 与 TSX `getMaxValue` 对齐。
  num _maxValue(Map<String, dynamic> data) {
    final values = data.values
        .map(_readNum)
        .where((v) => v > 0)
        .toList();
    if (values.isEmpty) return _splitNumber * 10;
    final maxValue = values.reduce(math.max);
    if (maxValue <= 0) return _splitNumber * 10;

    final rawInterval = maxValue / _splitNumber;
    final magnitude = math.pow(10, (math.log(rawInterval) / math.ln10).floor()).toDouble();
    for (final m in [1.0, 2.0, 5.0, 10.0]) {
      final candidate = magnitude * m;
      if (candidate >= rawInterval) return candidate * _splitNumber;
    }
    return magnitude * _splitNumber;
  }
}
