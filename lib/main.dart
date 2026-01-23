import 'package:flutter/material.dart';
import 'app.dart';
import 'widgets/cards/factory/definitions/index.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // 初始化卡片注册表
  initializeCardRegistry();
  runApp(const DinqApp());
}


