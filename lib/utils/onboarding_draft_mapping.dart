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
  'UTC+08:00 China',
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
