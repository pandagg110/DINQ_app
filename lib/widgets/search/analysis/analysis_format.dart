/// 与 TSX `@/utils/format` 中 analysis 相关格式化对齐。
abstract final class AnalysisFormat {
  AnalysisFormat._();

  static String formatThousand(dynamic value) {
    if (value == null || value == '') return '-';
    final num? n = value is num ? value : num.tryParse(value.toString().replaceAll(',', ''));
    if (n == null) return value.toString();
    if (n >= 1000000) {
      final m = n / 1000000;
      final text = m.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
      return '${text}M';
    }
    if (n >= 1000) {
      return n.round().toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]},',
          );
    }
    return n.toString();
  }

  static String formatNumber(dynamic value) {
    return formatThousand(value);
  }

  static String formatSalary(dynamic value) {
    if (value == null || value == '') return r'$0';
    if (value is num) {
      final n = value.toInt();
      if (n >= 1000000) {
        return '\$${(n / 1000000).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}M';
      }
      if (n >= 1000) return '\$${(n / 1000).round()}k';
      return '\$$n';
    }
    final text = value.toString().trim();
    if (text.startsWith('\$')) return text;
    final parsed = num.tryParse(text.replaceAll(RegExp(r'[^\d.]'), ''));
    if (parsed != null) return formatSalary(parsed);
    return '\$$text';
  }

  static String formatAuthorPosition(dynamic pos) {
    if (pos == null) return '';
    if (pos is num) {
      if (pos == -1) return 'Last author';
      if (pos == 0) return 'Unknown';
      return '$pos';
    }
    final text = pos.toString();
    if (text == 'first') return '1st author';
    if (text == 'last') return 'Last author';
    if (text == 'others' || text == 'other') return 'Co-author';
    final numVal = int.tryParse(text);
    if (numVal != null) return numVal == -1 ? 'Last author' : '$numVal';
    return text;
  }
}
