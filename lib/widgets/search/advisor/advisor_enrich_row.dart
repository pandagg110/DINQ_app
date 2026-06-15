/// 与 TSX `advisorToRow` / `buildEnrichRow.ts` 对齐。
Map<String, dynamic> advisorToRow(Map<String, dynamic> advisor) {
  final institution =
      advisor['institution']?.toString() ?? advisor['university']?.toString() ?? '';
  final scholarId = advisor['google_scholar_id']?.toString();
  final scholarUrl = scholarId != null && scholarId.isNotEmpty
      ? 'https://scholar.google.com/citations?user=$scholarId'
      : '';
  final homepage = advisor['personal_homepage']?.toString() ?? '';
  final profileUrl = homepage.isNotEmpty ? homepage : scholarUrl;
  final researchAreas = advisor['research_areas'];
  final areasText = researchAreas is List
      ? researchAreas.map((e) => e.toString()).join(', ')
      : '';
  final matchReason = advisor['match_reason']?.toString() ?? '';
  final evidence = [areasText, matchReason].where((s) => s.isNotEmpty).join('. ');

  return {
    'row_id': 'advisor-${advisor['name']}-$institution',
    'name': advisor['name']?.toString() ?? '',
    'title': advisor['position']?.toString() ?? '',
    'company': institution,
    'evidence': evidence,
    'profile_url': profileUrl,
    'source': 'advisor',
    'confidence': 0,
    'papers': <dynamic>[],
    'links': <dynamic>[],
    'url_identities': <dynamic>[],
    'updated_at': '',
  };
}
