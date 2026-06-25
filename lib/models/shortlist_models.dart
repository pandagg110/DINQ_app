// Shortlist 数据模型，对应线上 `/favorite-projects` 与 `/favorites` 接口。

import '../constants/shortlist_constants.dart';

/// 收藏项目（文件夹）。
class FavoriteProject {
  const FavoriteProject({
    required this.id,
    required this.name,
    required this.isDefault,
    required this.talentCount,
    this.createdAt,
  });

  final String id;
  final String name;
  final bool isDefault;
  final int talentCount;
  final String? createdAt;

  factory FavoriteProject.fromJson(Map<String, dynamic> json) {
    return FavoriteProject(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      isDefault: json['isDefault'] == true,
      talentCount: (json['talentCount'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt']?.toString(),
    );
  }

  FavoriteProject copyWith({
    String? id,
    String? name,
    bool? isDefault,
    int? talentCount,
    String? createdAt,
  }) {
    return FavoriteProject(
      id: id ?? this.id,
      name: name ?? this.name,
      isDefault: isDefault ?? this.isDefault,
      talentCount: talentCount ?? this.talentCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// 收藏的候选人。
class FavoriteItem {
  const FavoriteItem({
    required this.id,
    required this.projectId,
    required this.title,
    required this.field,
    required this.tags,
    required this.status,
    this.createdAt,
    this.type = 'talent',
  });

  final String id;
  final String projectId;
  final String title;
  final Map<String, dynamic> field;
  final String tags;
  final String status;
  final String? createdAt;
  final String type;

  factory FavoriteItem.fromJson(Map<String, dynamic> json) {
    final dynamic rawField = json['field'];
    return FavoriteItem(
      id: (json['id'] ?? '').toString(),
      projectId: (json['projectId'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      field: rawField is Map<String, dynamic>
          ? rawField
          : <String, dynamic>{},
      tags: (json['tags'] ?? '').toString(),
      status: (json['status'] ?? 'not_obtained').toString(),
      createdAt: json['createdAt']?.toString(),
      type: (json['type'] ?? 'talent').toString(),
    );
  }

  FavoriteItem copyWith({
    String? id,
    String? projectId,
    String? title,
    Map<String, dynamic>? field,
    String? tags,
    String? status,
    String? createdAt,
    String? type,
  }) {
    return FavoriteItem(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      field: field ?? this.field,
      tags: tags ?? this.tags,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
    );
  }

  String get name => (field['name'] ?? title).toString();
  String get roleTitle => (field['title'] ?? '').toString();
  String get company => (field['company'] ?? '').toString();
  String get profileUrl => (field['profile_url'] ?? '').toString();
  String? get avatarUrl {
    final raw = field['avatar_url'] ?? field['avatar'] ?? field['image_url'];
    final value = raw?.toString().trim() ?? '';
    return value.isEmpty ? null : value;
  }

  String? get location {
    final raw = field['location'] ?? field['city'] ?? field['region'];
    final value = raw?.toString().trim() ?? '';
    return value.isEmpty ? null : value;
  }

  String get evidence => (field['evidence'] ?? '').toString();
  String? get rowId => field['row_id']?.toString();
  double get confidence => (field['confidence'] as num?)?.toDouble() ?? 0;

  String get roleLine {
    final r = roleTitle.trim();
    final c = company.trim();
    if (r.isNotEmpty && c.isNotEmpty) return '$r · $c';
    if (r.isNotEmpty) return r;
    return c;
  }

  List<String> get tagList => tags
      .split(',')
      .map((t) => t.trim())
      .where((t) => t.isNotEmpty)
      .toList();

  String get initials {
    final n = name.trim();
    if (n.isEmpty) return '?';
    final parts = n.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return (parts.first.substring(0, 1) + parts[1].substring(0, 1))
          .toUpperCase();
    }
    return n.substring(0, n.length >= 2 ? 2 : 1).toUpperCase();
  }

  String get statusLabel {
    switch (normalizeFavoriteStatus(status)) {
      case 'email_obtained':
        return 'Email obtained';
      case 'contacted':
        return 'Contacted';
      default:
        return 'Not obtained';
    }
  }

  Map<String, dynamic> toEnrichRow() {
    return {
      'row_id': rowId ?? id,
      'name': name,
      'title': roleTitle,
      'company': company,
      'evidence': evidence,
      'profile_url': profileUrl,
      if (confidence > 0) 'confidence': confidence,
    };
  }
}

class ShortlistBulkResult {
  const ShortlistBulkResult({required this.ok, required this.fail});

  final int ok;
  final int fail;
}

class ShortlistPdfExportResult {
  const ShortlistPdfExportResult({
    required this.bytes,
    required this.filename,
  });

  final List<int> bytes;
  final String filename;
}
