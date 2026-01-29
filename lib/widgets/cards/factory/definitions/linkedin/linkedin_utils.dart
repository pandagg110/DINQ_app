/// Format duration string like "2017.6-Present" to "7y 6mos"
String formatDuration(String duration) {
  if (duration.isEmpty) return '';

  final match = RegExp(r'^(\d{4})\.(\d{1,2})\s*-\s*(\d{4}|Present)(?:\.(\d{1,2}))?$', caseSensitive: false)
      .firstMatch(duration);
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

