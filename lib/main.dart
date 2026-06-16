import 'package:flutter/material.dart';
import 'app.dart';
import 'services/push_service.dart';
import 'widgets/cards/factory/definitions/index.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 初始化卡片注册表
  initializeCardRegistry();
  // 初始化消息推送（未配置 Firebase 或非真机时内部安全跳过）
  await PushService.instance.init();
  runApp(DinqApp());
}
