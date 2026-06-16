/// Deep Search Enrich 数据模型，对齐 Web `types/api/deep-search-enrich.ts`.
library;
class EnrichStreamRequest {
  const EnrichStreamRequest({
    required this.name,
    required this.text,
    required this.sessionId,
    this.userLanguage,
    this.company,
  });

  final String name;
  final String text;
  final String sessionId;
  final String? userLanguage;
  final String? company;

  Map<String, dynamic> toJson() => {
        'name': name,
        'text': text,
        'session_id': sessionId,
        if (userLanguage != null && userLanguage!.isNotEmpty)
          'user_language': userLanguage,
        if (company != null && company!.isNotEmpty) 'company': company,
      };
}

class EnrichSocialLink {
  const EnrichSocialLink({required this.type, required this.url});

  final String type;
  final String url;

  factory EnrichSocialLink.fromJson(Map<String, dynamic> json) {
    return EnrichSocialLink(
      type: (json['type'] ?? '').toString(),
      url: (json['url'] ?? '').toString(),
    );
  }
}

class EnrichPublication {
  const EnrichPublication({required this.title, this.url});

  final String title;
  final String? url;

  factory EnrichPublication.fromJson(Map<String, dynamic> json) {
    return EnrichPublication(
      title: (json['title'] ?? '').toString(),
      url: json['url']?.toString(),
    );
  }
}

class EnrichNewsItem {
  const EnrichNewsItem({required this.description, this.url});

  final String description;
  final String? url;

  factory EnrichNewsItem.fromJson(Map<String, dynamic> json) {
    return EnrichNewsItem(
      description: (json['description'] ?? '').toString(),
      url: json['url']?.toString(),
    );
  }
}

class EnrichEducationHistory {
  const EnrichEducationHistory({
    required this.institution,
    this.degree,
    this.field,
    this.period,
  });

  final String institution;
  final String? degree;
  final String? field;
  final String? period;

  factory EnrichEducationHistory.fromJson(Map<String, dynamic> json) {
    return EnrichEducationHistory(
      institution: (json['institution'] ?? '').toString(),
      degree: json['degree']?.toString(),
      field: json['field']?.toString(),
      period: json['period']?.toString(),
    );
  }
}

class EnrichWorkExperience {
  const EnrichWorkExperience({
    required this.organization,
    this.role,
    this.period,
    this.details,
  });

  final String organization;
  final String? role;
  final String? period;
  final String? details;

  factory EnrichWorkExperience.fromJson(Map<String, dynamic> json) {
    return EnrichWorkExperience(
      organization: (json['organization'] ?? '').toString(),
      role: json['role']?.toString(),
      period: json['period']?.toString(),
      details: json['details']?.toString(),
    );
  }
}

class EnrichResultPerson {
  const EnrichResultPerson({
    required this.name,
    this.company,
    this.position,
    this.university,
    this.location,
    this.researchAreas,
    this.educationHistory,
    this.workExperience,
    this.email,
    this.personalHomepage,
    this.imageUrl,
    this.oneLiner,
    this.socialLinks,
    this.keyPublications,
    this.news,
  });

  final String name;
  final String? company;
  final String? position;
  final String? university;
  final String? location;
  final List<String>? researchAreas;
  final List<EnrichEducationHistory>? educationHistory;
  final List<EnrichWorkExperience>? workExperience;
  final String? email;
  final String? personalHomepage;
  final String? imageUrl;
  final String? oneLiner;
  final List<EnrichSocialLink>? socialLinks;
  final List<EnrichPublication>? keyPublications;
  final List<EnrichNewsItem>? news;

  factory EnrichResultPerson.fromJson(Map<String, dynamic> json) {
    List<T>? listOf<T>(
      dynamic raw,
      T Function(Map<String, dynamic>) fromJson,
    ) {
      if (raw is! List) return null;
      return raw
          .whereType<Map>()
          .map((e) => fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    return EnrichResultPerson(
      name: (json['name'] ?? '').toString(),
      company: json['company']?.toString(),
      position: json['position']?.toString(),
      university: json['university']?.toString(),
      location: json['location']?.toString(),
      researchAreas: (json['research_areas'] as List?)
          ?.map((e) => e.toString())
          .toList(),
      educationHistory: listOf(
        json['education_history'],
        EnrichEducationHistory.fromJson,
      ),
      workExperience: listOf(
        json['work_experience'],
        EnrichWorkExperience.fromJson,
      ),
      email: json['email']?.toString(),
      personalHomepage: json['personal_homepage']?.toString(),
      imageUrl: json['image_url']?.toString(),
      oneLiner: json['one_liner']?.toString(),
      socialLinks: listOf(json['social_links'], EnrichSocialLink.fromJson),
      keyPublications: listOf(
        json['key_publications'],
        EnrichPublication.fromJson,
      ),
      news: listOf(json['news'], EnrichNewsItem.fromJson),
    );
  }

  EnrichResultPerson merge(EnrichResultPerson other) {
    return EnrichResultPerson(
      name: other.name.isNotEmpty ? other.name : name,
      company: other.company ?? company,
      position: other.position ?? position,
      university: other.university ?? university,
      location: other.location ?? location,
      researchAreas: other.researchAreas ?? researchAreas,
      educationHistory: other.educationHistory ?? educationHistory,
      workExperience: other.workExperience ?? workExperience,
      email: other.email ?? email,
      personalHomepage: other.personalHomepage ?? personalHomepage,
      imageUrl: other.imageUrl ?? imageUrl,
      oneLiner: other.oneLiner ?? oneLiner,
      socialLinks: other.socialLinks ?? socialLinks,
      keyPublications: other.keyPublications ?? keyPublications,
      news: other.news ?? news,
    );
  }
}

/// Tool log 条目，对齐 Web `ToolLogTimeline`。
class EnrichToolLogSource {
  const EnrichToolLogSource({
    required this.title,
    required this.url,
    required this.domain,
  });

  final String title;
  final String url;
  final String domain;
}

class EnrichToolLog {
  const EnrichToolLog({
    required this.tool,
    required this.message,
    required this.status,
    required this.startedAt,
    this.endedAt,
    this.sources,
  });

  final String tool;
  final String message;
  final String status; // running | done
  final int startedAt;
  final int? endedAt;
  final List<EnrichToolLogSource>? sources;

  EnrichToolLog copyWith({
    String? tool,
    String? message,
    String? status,
    int? startedAt,
    int? endedAt,
    List<EnrichToolLogSource>? sources,
  }) {
    return EnrichToolLog(
      tool: tool ?? this.tool,
      message: message ?? this.message,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      sources: sources ?? this.sources,
    );
  }
}

enum EnrichStatus { idle, streaming, done, error }

class EnrichEntry {
  EnrichEntry({
    this.person,
    this.status = EnrichStatus.idle,
    List<EnrichToolLog>? toolLogs,
    this.errorMessage,
    Set<String>? seenUrls,
    this.fromCache = false,
    this.emailRevealing = false,
    this.emailRevealAttempted = false,
    this.revealedEmail,
    this.emailRevealError = false,
    this.savedAt,
    this.requestParams,
  })  : toolLogs = toolLogs ?? [],
        seenUrls = seenUrls ?? {};

  EnrichResultPerson? person;
  EnrichStatus status;
  List<EnrichToolLog> toolLogs;
  String? errorMessage;
  Set<String> seenUrls;
  bool fromCache;
  bool emailRevealing;
  bool emailRevealAttempted;
  String? revealedEmail;
  bool emailRevealError;
  int? savedAt;
  EnrichStreamRequest? requestParams;
}
