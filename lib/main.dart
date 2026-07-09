import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'app.dart';
import 'services/push_service.dart';
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
  runApp(DinqApp());
}
