const int profileTagLimit = 5;
const int profileTagCharLimit = 20;
const int profileBioLimit = 200;

const educationLevels = [
  'High school',
  'Bachelor',
  'Master',
  'PhD',
  'Postdoc',
  'Other',
];

const onboardingTimezones = [
  'UTC-08:00 Pacific Time',
  'UTC-05:00 Eastern Time',
  'UTC+00:00 London',
  'UTC+01:00 Central Europe',
  'UTC+8 Beijing/Shanghai',
  'UTC+09:00 Japan/Korea',
];

List<String> normalizeProfileTags(List<String> tags) {
  final seen = <String>{};
  final normalized = <String>[];
  for (final rawTag in tags) {
    final tag = rawTag.replaceAll(RegExp(r'[\r\n,]+'), ' ').trim();
    final clipped = tag.length > profileTagCharLimit
        ? tag.substring(0, profileTagCharLimit)
        : tag;
    final key = clipped.toLowerCase();
    if (clipped.isEmpty || seen.contains(key)) continue;
    seen.add(key);
    normalized.add(clipped);
    if (normalized.length >= profileTagLimit) break;
  }
  return normalized;
}

List<String> splitTags(String? tags) {
  if (tags == null || tags.isEmpty) return [];
  return normalizeProfileTags(tags.split(','));
}

({String? position, String? company}) splitFullPosition(String? value) {
  final full = value ?? '';
  if (full.isEmpty) return (position: null, company: null);
  if (full.contains(', ')) {
    final parts = full.split(', ');
    return (position: parts.first, company: parts.skip(1).join(', '));
  }
  if (full.contains(' at ')) {
    final parts = full.split(' at ');
    return (position: parts.first, company: parts.skip(1).join(' at '));
  }
  return (position: full, company: null);
}

({String? educationLevel, String? school}) splitFullDegree(String? value) {
  final full = value ?? '';
  if (full.isEmpty) return (educationLevel: null, school: null);
  if (full.contains(', ')) {
    final parts = full.split(', ');
    return (educationLevel: parts.first, school: parts.skip(1).join(', '));
  }
  return (educationLevel: null, school: full);
}

/// Maps API/draft degree strings (incl. Chinese) to [educationLevels] values.
String normalizeEducationLevel(String? raw) {
  final trimmed = raw?.trim() ?? '';
  if (trimmed.isEmpty) return '';
  if (educationLevels.contains(trimmed)) return trimmed;

  const aliases = <String, String>{
    'high school': 'High school',
    '高中': 'High school',
    'bachelor': 'Bachelor',
    "bachelor's": 'Bachelor',
    '本科': 'Bachelor',
    '学士': 'Bachelor',
    'master': 'Master',
    "master's": 'Master',
    '硕士': 'Master',
    'phd': 'PhD',
    'doctorate': 'PhD',
    '博士': 'PhD',
    'postdoc': 'Postdoc',
    '博士后': 'Postdoc',
    'other': 'Other',
    '其他': 'Other',
  };

  return aliases[trimmed.toLowerCase()] ?? '';
}

/// Maps API/draft timezone strings to [onboardingTimezones] values.
String normalizeOnboardingTimezone(String? raw) {
  final trimmed = raw?.trim() ?? '';
  if (trimmed.isEmpty) return '';
  if (onboardingTimezones.contains(trimmed)) return trimmed;

  final lower = trimmed.toLowerCase();
  if (lower.contains('shanghai') ||
      lower.contains('beijing') ||
      lower.contains('china') ||
      lower.contains('utc+8') ||
      lower.contains('utc+08')) {
    return 'UTC+8 Beijing/Shanghai';
  }
  if (lower.contains('pacific') || lower.contains('utc-8') || lower.contains('utc-08')) {
    return 'UTC-08:00 Pacific Time';
  }
  if (lower.contains('eastern') || lower.contains('utc-5') || lower.contains('utc-05')) {
    return 'UTC-05:00 Eastern Time';
  }
  if (lower.contains('london') || lower.contains('utc+0') || lower.contains('utc+00')) {
    return 'UTC+00:00 London';
  }
  if (lower.contains('europe') || lower.contains('utc+1') || lower.contains('utc+01')) {
    return 'UTC+01:00 Central Europe';
  }
  if (lower.contains('japan') ||
      lower.contains('korea') ||
      lower.contains('utc+9') ||
      lower.contains('utc+09')) {
    return 'UTC+09:00 Japan/Korea';
  }

  return '';
}

String? dropdownValueOrNull(String value, List<String> options) {
  if (value.isEmpty || !options.contains(value)) return null;
  return value;
}
