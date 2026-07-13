/// 组织分享目标，对齐 Web `OrganizationShareTarget`（types/share.ts）。
class OrganizationShareTarget {
  const OrganizationShareTarget({
    required this.slug,
    required this.name,
    this.description,
    this.logoUrl,
    this.tags = const [],
    this.location,
    this.memberCount,
  });

  final String slug;
  final String name;
  final String? description;
  final String? logoUrl;
  final List<String> tags;
  final String? location;
  final int? memberCount;
}
