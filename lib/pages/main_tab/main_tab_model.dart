enum MainTabType {
  search,
  talentRadar,
  shortlist,
  inBox,
  me;

  int get pageIndex {
    // Defensive fallback for hot-reload enum drift.
    if (this == MainTabType.search) return 0;
    if (this == MainTabType.talentRadar) return 1;
    if (this == MainTabType.shortlist) return 2;
    if (this == MainTabType.inBox) return 3;
    if (this == MainTabType.me) return 4;
    return 0;
  }

  static MainTabType fromIndex(int index) {
    switch (index) {
      case 0:
        return MainTabType.search;
      case 1:
        return MainTabType.talentRadar;
      case 2:
        return MainTabType.shortlist;
      case 3:
        return MainTabType.inBox;
      case 4:
        return MainTabType.me;
      default:
        return MainTabType.search;
    }
  }
}

class MainTabModel {
  MainTabType pageType;
  String title;
  String iconName;
  String selIconName;

  /// 可选 SVG 图标（用于无 PNG tab 图的新 Tab，如 Talent Radar / Shortlist）。
  /// 提供时底栏用 SVG + 着色渲染，否则用 PNG（AssetImageView）。
  final String? iconSvg;
  final String? selIconSvg;

  MainTabModel({
    required this.pageType,
    required this.title,
    required this.iconName,
    required this.selIconName,
    this.iconSvg,
    this.selIconSvg,
  });
}
