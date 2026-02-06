import 'package:flutter/foundation.dart';

/// 主 Tab 页面状态管理
class MainStore extends ChangeNotifier {
  /// 是否显示底部导航栏（MainTabBottomView）
  bool _showBottomNav = true;

  bool get showBottomNav => _showBottomNav;

  /// 设置底部导航栏显示/隐藏
  void setShowBottomNav(bool show) {
    if (_showBottomNav != show) {
      _showBottomNav = show;
      notifyListeners();
    }
  }

  /// 显示底部导航栏
  void showBottomNavigation() {
    setShowBottomNav(true);
    notifyListeners();
  }

  /// 隐藏底部导航栏
  void hideBottomNavigation() {
    setShowBottomNav(false);
    notifyListeners();
  }
}
