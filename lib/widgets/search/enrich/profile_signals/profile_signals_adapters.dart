import '../../../../models/deep_search_enrich_models.dart';

const _singleProfileSignalTypes = {'GITHUB', 'LINKEDIN', 'SCHOLAR'};

class ProfileSignalItem {
  const ProfileSignalItem({
    required this.type,
    required this.metadata,
    this.url,
  });

  final String type;
  final Map<String, dynamic> metadata;
  final String? url;
}

String normalizeProfileSignalType(String raw) {
  final type = raw.trim().toUpperCase();
  switch (type) {
    case 'GOOGLE_SCHOLAR':
      return 'SCHOLAR';
    default:
      return type;
  }
}

/// 剥离后端 `{ code, message, data }` 信封（对齐 Web `unwrapEnvelope`）。
dynamic unwrapProfileSignalEnvelope(dynamic raw) {
  if (raw == null || raw is! Map) return raw;
  if (!raw.containsKey('code') && !raw.containsKey('message')) return raw;

  final inner = raw['data'];
  if (inner == null) return raw;
  if (inner is List) return inner;
  if (inner is Map) {
    final rest = Map<String, dynamic>.from(raw);
    rest.remove('code');
    rest.remove('message');
    rest.remove('data');
    return {...Map<String, dynamic>.from(inner), ...rest};
  }
  return raw;
}

dynamic _adapterData(dynamic rawMetadata) {
  if (rawMetadata is Map && rawMetadata.containsKey('data')) {
    return rawMetadata['data'];
  }
  return rawMetadata;
}

Map<String, dynamic> _adapterMap(dynamic rawMetadata) {
  final data = _adapterData(rawMetadata);
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return Map<String, dynamic>.from(data);
  return <String, dynamic>{};
}

String? extractGitHubUsernameFromUrl(String? url) {
  if (url == null || url.isEmpty) return null;
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.host.contains('github.com')) return null;
  final parts = uri.pathSegments.where((part) => part.isNotEmpty).toList();
  if (parts.isEmpty) return null;
  return parts.first;
}

String? extractGitHubRepoNameFromUrl(String? url) {
  if (url == null || url.isEmpty) return null;
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.host.contains('github.com')) return null;
  final parts = uri.pathSegments.where((part) => part.isNotEmpty).toList();
  if (parts.length < 2) return null;
  return parts[1];
}

Map<String, dynamic> adaptLinkedInMetadata(dynamic rawMetadata) {
  if (rawMetadata is Map && rawMetadata['careerJourney'] is List) {
    return Map<String, dynamic>.from(rawMetadata);
  }

  final rawData = _adapterData(rawMetadata);
  List<dynamic> items;
  if (rawData is List) {
    items = rawData;
  } else if (rawData is Map && rawData['linkedin'] is List) {
    items = rawData['linkedin'] as List;
  } else {
    items = [];
  }

  int extractStartYear(String duration) {
    final match = RegExp(r'^(\d{4})').firstMatch(duration);
    return match != null ? int.parse(match.group(1)!) : DateTime.now().year;
  }

  final careerJourney = items.reversed.map((item) {
    final itemMap = item as Map<String, dynamic>;
    return {
      'logo': itemMap['logo'] ?? '',
      'name': itemMap['name'] ?? '',
      'position': itemMap['position'] ?? '',
      'score': itemMap['score'] ?? 0,
      'year': extractStartYear(itemMap['duration']?.toString() ?? ''),
      'duration': itemMap['duration'] ?? '',
    };
  }).toList();

  return {'careerJourney': careerJourney};
}

Map<String, dynamic> adaptGitHubMetadata(
  dynamic rawMetadata, {
  String? cardUrl,
}) {
  var data = _adapterMap(rawMetadata);
  if (data['github'] is Map) {
    data = Map<String, dynamic>.from(data['github'] as Map);
  }

  var username = (data['username'] ?? data['login'] ?? '').toString();
  if (username.isEmpty) {
    username = extractGitHubUsernameFromUrl(cardUrl) ?? '';
  }

  return {
    'username': username,
    'starCount':
        data['total_stars'] ?? data['totalStars'] ?? data['starCount'] ?? 0,
    'topLanguages': data['top_languages'] ?? data['topLanguages'] ?? [],
    'summary': data['summary'] ?? '',
    'representativeProject':
        data['representative_project'] ?? data['representativeProject'],
    'displayMode': data['displayMode'],
  };
}

Map<String, dynamic> adaptScholarMetadata(dynamic rawMetadata) {
  var data = _adapterMap(rawMetadata);
  if (data['google_scholar'] is Map) {
    data = Map<String, dynamic>.from(data['google_scholar'] as Map);
  } else if (data['scholar'] is Map) {
    data = Map<String, dynamic>.from(data['scholar'] as Map);
  }

  return {
    'name': data['name'] ?? '',
    'scholarId': data['scholarId'] ?? data['scholar_id'] ?? '',
    'topTierPapers': data['topTierPapers'] ?? data['top_tier_papers'] ?? 0,
    'totalPapers': data['totalPapers'] ?? data['total_papers'] ?? 0,
    'totalCitations': data['totalCitations'] ?? data['total_citations'] ?? 0,
    'firstAuthorCitations':
        data['firstAuthorCitations'] ?? data['first_author_citations'] ?? 0,
    'hIndex': data['hIndex'] ?? data['h_index'] ?? 0,
    'summary': data['summary'] ?? '',
  };
}

Map<String, dynamic>? adaptProfileSignalMetadata(
  String type,
  dynamic rawMetadata, {
  String? cardUrl,
}) {
  switch (type) {
    case 'LINKEDIN':
      return adaptLinkedInMetadata(rawMetadata);
    case 'GITHUB':
      return adaptGitHubMetadata(rawMetadata, cardUrl: cardUrl);
    case 'SCHOLAR':
      return adaptScholarMetadata(rawMetadata);
    default:
      return null;
  }
}

bool isRenderableProfileSignal(EnrichDinqCard card) {
  if (card.status?.toLowerCase() == 'error') return false;
  return card.metadata != null;
}

int _profileSignalCardScore(EnrichDinqCard card) {
  if (card.status?.toLowerCase() == 'error') return -1;

  var score = 0;
  if (card.url.isNotEmpty) score += 20;

  final metadata = card.metadata;
  if (metadata != null) {
    score += 10 + metadata.length;
    if (metadata['careerJourney'] is List &&
        (metadata['careerJourney'] as List).isNotEmpty) {
      score += 30;
    }
    if ((metadata['username'] ?? metadata['login'])?.toString().isNotEmpty ==
        true) {
      score += 25;
    }
    if (metadata['totalCitations'] != null ||
        metadata['total_citations'] != null) {
      score += 25;
    }
    if (metadata['github'] is Map) score += 15;
  }

  return score;
}

/// 对齐 Web：同 type 只保留一张卡，优先 metadata/url 更完整的那张。
List<EnrichDinqCard> selectProfileSignalCards(List<EnrichDinqCard> cards) {
  final bestByType = <String, EnrichDinqCard>{};
  final order = <String>[];

  for (final card in cards) {
    final type = normalizeProfileSignalType(card.type);
    if (!_singleProfileSignalTypes.contains(type)) continue;
    if (!isRenderableProfileSignal(card)) continue;

    final existing = bestByType[type];
    if (existing == null) {
      bestByType[type] = card;
      order.add(type);
      continue;
    }

    if (_profileSignalCardScore(card) > _profileSignalCardScore(existing)) {
      bestByType[type] = card;
    }
  }

  return order.map((type) => bestByType[type]!).toList();
}

ProfileSignalItem? buildProfileSignalItem(EnrichDinqCard card) {
  final type = normalizeProfileSignalType(card.type);
  if (!_singleProfileSignalTypes.contains(type)) return null;
  if (!isRenderableProfileSignal(card)) return null;

  final url = card.url.isNotEmpty ? card.url : null;
  final unwrapped = unwrapProfileSignalEnvelope(card.metadata);
  final adapted = adaptProfileSignalMetadata(
    type,
    unwrapped,
    cardUrl: url,
  );
  if (adapted == null) return null;

  final metadata = Map<String, dynamic>.from(adapted);
  if (url != null) {
    metadata['url'] = url;
  }

  return ProfileSignalItem(type: type, metadata: metadata, url: url);
}

List<ProfileSignalItem> buildProfileSignalItems(List<EnrichDinqCard> cards) {
  return selectProfileSignalCards(cards)
      .map(buildProfileSignalItem)
      .whereType<ProfileSignalItem>()
      .toList();
}
