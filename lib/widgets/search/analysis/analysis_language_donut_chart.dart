import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_echarts/flutter_echarts.dart';

/// 与 TSX `LanguageDonutChart.tsx` + ECharts option 对齐。
class AnalysisLanguageDonutChart extends StatelessWidget {
  const AnalysisLanguageDonutChart({
    super.key,
    required this.languages,
    required this.total,
  });

  final Map<String, dynamic> languages;
  final num total;

  static const _colors = [
    '#7F95CE',
    '#D2CEC4',
    '#CB7C5D',
    '#F8E9C8',
    '#B89EDA',
    '#A8C5A8',
    '#F4A6A6',
    '#FFD88C',
  ];

  @override
  Widget build(BuildContext context) {
    final processed = _processedData();
    if (processed.isEmpty) return const SizedBox.expand();

    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Echarts(
        option: _buildOption(processed),
        reloadAfterInit: true,
      ),
    );
  }

  String _buildOption(List<({String name, num value})> data) {
    final seriesData = [
      for (var i = 0; i < data.length; i++)
        {
          'name': data[i].name,
          'value': data[i].value,
          'label': _outsideLabel(i),
        },
    ];

    final centerText = total >= 1000000
        ? '${(total / 1000000).toStringAsFixed(1)}M'
        : total >= 1000
            ? '${(total / 1000).toStringAsFixed(1)}K'
            : '$total';

    return jsonEncode({
      'animation': false,
      'color': _colors,
      'backgroundColor': 'transparent',
      'textStyle': {'fontFamily': 'Poppins'},
      'grid': {'top': 20, 'right': 20, 'bottom': 20, 'left': 20, 'containLabel': true},
      'legend': {
        'show': true,
        'orient': 'horizontal',
        'bottom': 0,
        'left': 'center',
        'itemWidth': 16,
        'itemHeight': 16,
        'itemGap': 16,
        'textStyle': {
          'color': '#030229',
          'fontSize': 14,
          'fontWeight': 500,
          'fontFamily': 'Poppins',
        },
        'icon': 'roundRect',
      },
      'series': [
        {
          'name': 'Code Lines',
          'type': 'pie',
          'radius': ['30%', '45%'],
          'center': ['50%', '45%'],
          'startAngle': 60,
          'avoidLabelOverlap': true,
          'labelLine': {
            'show': true,
            'length': 15,
            'length2': 10,
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
          'top': '40%',
          'style': {
            'text': centerText,
            'textAlign': 'center',
            'fill': '#030229',
            'fontSize': 20,
            'fontWeight': '600',
            'fontFamily': 'Poppins',
          },
        },
        {
          'type': 'text',
          'left': 'center',
          'top': '50%',
          'style': {
            'text': 'Total Code',
            'textAlign': 'center',
            'fill': '#000000',
            'fontSize': 10,
            'fontWeight': '500',
            'fontFamily': 'Poppins',
          },
        },
      ],
    });
  }

  Map<String, dynamic> _outsideLabel(int index) {
    return {
      'fontFamily': 'Poppins',
      'show': true,
      'position': 'outside',
      'distanceToLabelLine': 5,
      'formatter': '{bar|}\n{name|{b}}\n{value|{c}} {percent|{d}%}',
      'fontSize': 14,
      'color': '#030229',
      'backgroundColor': '#FAF2EF',
      'width': 100,
      'height': 50,
      'rich': {
        'bar': {
          'height': 4,
          'width': '100%',
          'backgroundColor': _colors[index % _colors.length],
          'fontFamily': 'Poppins',
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
    return languages.entries
        .map((e) => (name: e.key, value: num.tryParse('${e.value}') ?? 0))
        .where((e) => e.value > 0)
        .toList();
  }

  /// 与 TSX `processedData` 对齐。
  List<({String name, num value})> _processedData() {
    final raw = _rawData()..sort((a, b) => b.value.compareTo(a.value));
    if (raw.isEmpty) return [];

    final List<({String name, num value})> finalData;
    if (raw.length <= 4) {
      finalData = raw;
    } else {
      final top4 = raw.take(4).toList();
      final top4Sum = top4.fold<num>(0, (s, it) => s + it.value);
      final othersValue = (total - top4Sum).clamp(0, double.infinity);
      if (othersValue > 0) {
        finalData = [...top4, (name: 'Others', value: othersValue)];
      } else {
        finalData = top4;
      }
    }

    if (finalData.length >= 4) {
      final interleaved = <({String name, num value})>[];
      for (var i = 0; i < finalData.length; i += 2) {
        interleaved.add(finalData[i]);
      }
      for (var i = 1; i < finalData.length; i += 2) {
        interleaved.add(finalData[i]);
      }
      return interleaved;
    }
    return finalData;
  }
}
