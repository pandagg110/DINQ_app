// Shortlist 数据模型，对应线上 `/favorite-projects` 与 `/favorites` 接口。

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
  });

  final String id;
  final String projectId;
  final String title;
  final Map<String, dynamic> field;
  final String tags;

  /// 原始状态：not_obtained / email_obtained / contacted
  final String status;

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
    );
  }

  String get name => (field['name'] ?? title).toString();
  String get roleTitle => (field['title'] ?? '').toString();
  String get company => (field['company'] ?? '').toString();
  String get profileUrl => (field['profile_url'] ?? '').toString();
  String get evidence => (field['evidence'] ?? '').toString();
  double get confidence => (field['confidence'] as num?)?.toDouble() ?? 0;

  /// 职位 + 公司，组合成卡片副标题，如 "运营 · 字节跳动"。
  String get roleLine {
    final String r = roleTitle.trim();
    final String c = company.trim();
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
    final String n = name.trim();
    if (n.isEmpty) return '?';
    final parts = n.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return (parts.first.substring(0, 1) + parts[1].substring(0, 1))
          .toUpperCase();
    }
    return n.substring(0, n.length >= 2 ? 2 : 1).toUpperCase();
  }

  /// 状态展示标签：与设计稿的筛选项一致。
  String get statusLabel => switch (status) {
        'email_obtained' => 'Email obtained',
        'contacted' => 'Contacted',
        _ => 'Not obtained',
      };
}
