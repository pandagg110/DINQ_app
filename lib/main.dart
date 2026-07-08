import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'services/push_service.dart';
import 'widgets/cards/factory/definitions/index.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Android 状态栏透明+深色图标：系统默认的灰色状态栏底色会和米白页面
  // 割裂（「顶部导航颜色没有与界面统一」「安卓 search 顶部区域白色」的根因）。
  // iOS 不受 statusBarColor 影响，仅由 brightness 控制图标颜色。
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  // 初始化卡片注册表
  initializeCardRegistry();
  // 初始化消息推送（未配置 Firebase 或非真机时内部安全跳过）
  await PushService.instance.init();
  runApp(DinqApp());
}
