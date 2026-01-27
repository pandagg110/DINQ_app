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
    // For non-int values, format with reasonable precision
    if (value is double) {
      final doubleVal = value as double;
      // If it's a large number, format similar to int
      if (doubleVal >= 1000000) {
        return '${(doubleVal / 1000000).toStringAsFixed(1)}M';
      } else if (doubleVal >= 1000) {
        return '${(doubleVal / 1000).toStringAsFixed(1)}K';
      }
      // For smaller numbers, limit decimal places
      return doubleVal.toStringAsFixed(doubleVal.truncateToDouble() == doubleVal ? 0 : 1);
    }
    // Fallback: limit string length
    final str = value.toString();
    return str.length > 15 ? '${str.substring(0, 12)}...' : str;
  }

  @override
  Widget build(BuildContext context) {
    final formattedValue = _formatValue();
    
    // Use mobile/compact styles by default (matching TSX mobile version)
    TextStyle labelStyle;
    TextStyle valueStyle;
    
    switch (variant) {
      case MetricVariant.compact:
        // text-xs leading-4 font-normal text-gray-500
        labelStyle = const TextStyle(
          fontSize: 12,
          height: 1.0, // Use 1.0 to minimize extra space
          fontWeight: FontWeight.w400,
          color: Color(0xFF6B7280), // text-gray-500
        );
        // text-xl leading-7 font-semibold text-[#171717]
        valueStyle = const TextStyle(
          fontSize: 20, // text-xl
          height: 1.0, // Use 1.0 to minimize extra space
          fontWeight: FontWeight.w600, // font-semibold
          color: Color(0xFF171717),
        );
        break;
      case MetricVariant.large:
        // text-sm leading-[18px] font-normal text-gray-500
        labelStyle = const TextStyle(
          fontSize: 14,
          height: 1.29, // leading-[18px] = 18px / 14px = 1.29
          fontWeight: FontWeight.w400,
          color: Color(0xFF6B7280),
        );
        // text-[28px] leading-9 font-semibold text-[#171717]
        valueStyle = const TextStyle(
          fontSize: 28,
          height: 1.29, // leading-9 = 36px / 28px = 1.29
          fontWeight: FontWeight.w600,
          color: Color(0xFF171717),
        );
        break;
      case MetricVariant.default_:
        // Use compact style for mobile (matching TSX mobile version)
        // text-xs leading-4 font-normal text-gray-500
        labelStyle = const TextStyle(
          fontSize: 12,
          height: 1.0, // Use 1.0 to minimize extra space
          fontWeight: FontWeight.w400,
          color: Color(0xFF6B7280),
        );
        // text-xl leading-7 font-semibold text-[#171717]
        valueStyle = const TextStyle(
          fontSize: 20,
          height: 1.0, // Use 1.0 to minimize extra space
          fontWeight: FontWeight.w600,
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
          textHeightBehavior: const TextHeightBehavior(
            applyHeightToFirstAscent: true,
            applyHeightToLastDescent: false,
          ),
        ),
        const SizedBox(height: 4), // gap-1 in TSX = 4px
        Text(
          formattedValue,
          style: valueStyle,
          textAlign: textAlign,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textHeightBehavior: const TextHeightBehavior(
            applyHeightToFirstAscent: true,
            applyHeightToLastDescent: false,
          ),
        ),
      ],
    );
  }
}

