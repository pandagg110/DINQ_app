// 与 example/src/types/api/recommendation.ts 对应

class PaperLinks {
  final List<String>? pdf;
  final List<String>? link;
  final List<String>? venue;
  final List<String>? detail;

  PaperLinks({this.pdf, this.link, this.venue, this.detail});

  factory PaperLinks.fromJson(Map<String, dynamic>? json) {
    if (json == null) return PaperLinks();
    return PaperLinks(
      pdf: (json['pdf'] as List?)?.cast<String>(),
      link: (json['link'] as List?)?.cast<String>(),
      venue: (json['venue'] as List?)?.cast<String>(),
      detail: (json['detail'] as List?)?.cast<String>(),
    );
  }
}

class PaperData {
  final String? time;
  final int index;
  final PaperLinks links;
  final String title;
  final List<String> authors;
  final String? session;
  final String summary;
  final List<String> keywords;
  final String paperId;
  final List<String> subjects;

  PaperData({
    this.time,
    required this.index,
    required this.links,
    required this.title,
    required this.authors,
    this.session,
    required this.summary,
    required this.keywords,
    required this.paperId,
    required this.subjects,
  });

  factory PaperData.fromJson(Map<String, dynamic> json) {
    return PaperData(
      time: json['time'] as String?,
      index: (json['index'] as num?)?.toInt() ?? 0,
      links: PaperLinks.fromJson(json['links'] as Map<String, dynamic>?),
      title: json['title'] as String? ?? '',
      authors: ((json['authors'] as List?) ?? []).map((e) => e.toString()).toList(),
      session: json['session'] as String?,
      summary: json['summary'] as String? ?? '',
      keywords: ((json['keywords'] as List?) ?? []).map((e) => e.toString()).toList(),
      paperId: json['paper_id'] as String? ?? '',
      subjects: ((json['subjects'] as List?) ?? []).map((e) => e.toString()).toList(),
    );
  }
}

class RecommendedPaper {
  final String paperUid;
  final PaperData data;
  final double? distance;
  final double? bm25;
  final double? hybridScore;

  RecommendedPaper({
    required this.paperUid,
    required this.data,
    this.distance,
    this.bm25,
    this.hybridScore,
  });

  factory RecommendedPaper.fromJson(Map<String, dynamic> json) {
    final dataJson = json['data'];
    return RecommendedPaper(
      paperUid: json['paper_uid'] as String? ?? '',
      data: dataJson is Map<String, dynamic> ? PaperData.fromJson(dataJson) : PaperData.fromJson({}),
      distance: (json['distance'] as num?)?.toDouble(),
      bm25: (json['bm25'] as num?)?.toDouble(),
      hybridScore: (json['hybrid_score'] as num?)?.toDouble(),
    );
  }
}

class PaperFiltersState {
  List<String> conference;
  List<int> year;
  List<String> status;
  List<String> group;

  PaperFiltersState({
    this.conference = const [],
    this.year = const [],
    this.status = const [],
    this.group = const [],
  });

  PaperFiltersState copyWith({
    List<String>? conference,
    List<int>? year,
    List<String>? status,
    List<String>? group,
  }) {
    return PaperFiltersState(
      conference: conference ?? this.conference,
      year: year ?? this.year,
      status: status ?? this.status,
      group: group ?? this.group,
    );
  }
}
