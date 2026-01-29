enum MainTabType {
  myDinq,
  discover,
  inBox,
  me;

  int get pageIndex {
    switch (this) {
      case MainTabType.myDinq:
        return 0;
      case MainTabType.discover:
        return 1;
      case MainTabType.inBox:
        return 2;
      case MainTabType.me:
        return 3;
    }
  }

  static MainTabType fromIndex(int index) {
    switch (index) {
      case 0:
        return MainTabType.myDinq;
      case 1:
        return MainTabType.discover;
      case 2:
        return MainTabType.inBox;
      case 3:
        return MainTabType.me;
      default:
        return MainTabType.myDinq;
    }
  }
}

class MainTabModel {
  MainTabType pageType;
  String title;
  String iconName;
  String selIconName;

  MainTabModel({
    required this.pageType,
    required this.title,
    required this.iconName,
    required this.selIconName,
  });
}
