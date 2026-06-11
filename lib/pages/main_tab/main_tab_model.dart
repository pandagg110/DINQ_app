enum MainTabType {
  discover,
  talentRadar,
  shortlist,
  inBox,
  me;

  int get pageIndex {
    switch (this) {
      case MainTabType.discover:
        return 0;
      case MainTabType.talentRadar:
        return 1;
      case MainTabType.shortlist:
        return 2;
      case MainTabType.inBox:
        return 3;
      case MainTabType.me:
        return 4;
    }
  }

  static MainTabType fromIndex(int index) {
    switch (index) {
      case 0:
        return MainTabType.discover;
      case 1:
        return MainTabType.talentRadar;
      case 2:
        return MainTabType.shortlist;
      case 3:
        return MainTabType.inBox;
      case 4:
        return MainTabType.me;
      default:
        return MainTabType.discover;
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
