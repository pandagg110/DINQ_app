import 'package:flutter/material.dart';

/// Format count with K, M suffixes
String formatCount(int value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  } else if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}K';
  }
  return value.toString();
}

enum MetricVariant { default_, compact, large }

enum MetricAlign { start, center, end }

class MetricDisplay extends StatelessWidget {
  const MetricDisplay({
    super.key,
    required this.label,
    required this.value,
    this.variant = MetricVariant.default_,
    this.align = MetricAlign.start,
    this.className,
  });

  final String label;
  final num value;
  final MetricVariant variant;
  final MetricAlign align;
  final String? className;

  String _formatValue() {
    if (value is int) {
      return formatCount(value as int);
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final formattedValue = _formatValue();
    
    TextStyle labelStyle;
    TextStyle valueStyle;
    
    switch (variant) {
      case MetricVariant.compact:
        labelStyle = const TextStyle(
          fontSize: 12,
          height: 1.33,
          fontWeight: FontWeight.w400,
          color: Color(0xFF6B7280),
        );
        valueStyle = const TextStyle(
          fontSize: 20,
          height: 1.4,
          fontWeight: FontWeight.w600,
          color: Color(0xFF171717),
        );
        break;
      case MetricVariant.large:
        labelStyle = const TextStyle(
          fontSize: 14,
          height: 1.29,
          fontWeight: FontWeight.w400,
          color: Color(0xFF6B7280),
        );
        valueStyle = const TextStyle(
          fontSize: 28,
          height: 1.29,
          fontWeight: FontWeight.w600,
          color: Color(0xFF171717),
        );
        break;
      case MetricVariant.default_:
        labelStyle = const TextStyle(
          fontSize: 14,
          height: 1.14,
          fontWeight: FontWeight.w400,
          color: Color(0xFF6B7280),
        );
        valueStyle = const TextStyle(
          fontSize: 24,
          height: 1.33,
          fontWeight: FontWeight.w500,
          color: Color(0xFF171717),
        );
        break;
    }

    CrossAxisAlignment crossAxisAlignment;
    TextAlign textAlign;
    
    switch (align) {
      case MetricAlign.center:
        crossAxisAlignment = CrossAxisAlignment.center;
        textAlign = TextAlign.center;
        break;
      case MetricAlign.end:
        crossAxisAlignment = CrossAxisAlignment.end;
        textAlign = TextAlign.right;
        break;
      case MetricAlign.start:
        crossAxisAlignment = CrossAxisAlignment.start;
        textAlign = TextAlign.left;
        break;
    }

    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: labelStyle,
          textAlign: textAlign,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4), // gap-1 in TSX = 4px
        Text(
          formattedValue,
          style: valueStyle,
          textAlign: textAlign,
        ),
      ],
    );
  }
}

