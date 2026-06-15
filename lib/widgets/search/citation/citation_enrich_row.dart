/// 与 TSX `citerToRow` / `buildEnrichRow.ts` 对齐。
Map<String, dynamic> citationCiterToRow({
  required String name,
  String? affiliation,
  String? scholarId,
  List<String>? interests,
}) {
  final scholarUrl = scholarId != null && scholarId.isNotEmpty
      ? 'https://scholar.google.com/citations?user=$scholarId'
      : '';

  return {
    'row_id': 'citer-${scholarId ?? name}',
    'name': name,
    'title': '',
    'company': affiliation ?? '',
    'evidence': interests?.join(', ') ?? '',
    'profile_url': scholarUrl,
    'source': 'citation',
    'confidence': 0,
    'papers': <dynamic>[],
    'links': <dynamic>[],
    'url_identities': <dynamic>[],
    'updated_at': '',
  };
}
