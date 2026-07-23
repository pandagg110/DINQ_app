import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'app.dart';
import 'services/push_service.dart';
import 'stores/user_store.dart';
import 'widgets/cards/factory/definitions/index.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Android edge-to-edge：状态栏透明 + 底部导航栏与页面同色（米白 bgPage），
  // 避免系统默认黑色导航条与界面割裂。
  SystemChrome.setSystemUIOverlayStyle(AppTheme.pageSystemUiOverlayStyle);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  // 初始化卡片注册表
  initializeCardRegistry();
  // 初始化消息推送（未配置 Firebase 或非真机时内部安全跳过）
  await PushService.instance.init();
  final userStore = UserStore();
  await userStore.ready;
  final preferences = await SharedPreferences.getInstance();
  final showFirstLaunchSplash =
      !(preferences.getBool('startup.has_launched') ?? false);
  await preferences.setBool('startup.has_launched', true);
  runApp(
    DinqApp(userStore: userStore, showFirstLaunchSplash: showFirstLaunchSplash),
  );
}
