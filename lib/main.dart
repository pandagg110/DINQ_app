import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'app.dart';
import 'services/push_service.dart';
import 'stores/user_store.dart';
import 'widgets/cards/factory/definitions/index.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final imagePickerImplementation = ImagePickerPlatform.instance;
  if (!kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android &&
      imagePickerImplementation is ImagePickerAndroid) {
    imagePickerImplementation.useAndroidPhotoPicker = true;
  }
  // Android edge-to-edge：状态栏透明 + 底部导航栏与页面同色（米白 bgPage），
  // 避免系统默认黑色导航条与界面割裂。
  SystemChrome.setSystemUIOverlayStyle(AppTheme.pageSystemUiOverlayStyle);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  // 初始化卡片注册表
  initializeCardRegistry();

  // 推送 / 用户初始化放到后台，失败也不阻塞首帧（真机无 GMS / 网络慢时避免白屏）
  unawaited(_initPushInBackground());
  final userStore = UserStore();

  var showFirstLaunchSplash = false;
  try {
    final preferences = await SharedPreferences.getInstance();
    showFirstLaunchSplash =
        !(preferences.getBool('startup.has_launched') ?? false);
    await preferences.setBool('startup.has_launched', true);
  } catch (_) {}

  runApp(
    DinqApp(userStore: userStore, showFirstLaunchSplash: showFirstLaunchSplash),
  );
}

Future<void> _initPushInBackground() async {
  try {
    await PushService.instance.init();
  } catch (_) {}
}
