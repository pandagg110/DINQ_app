import 'package:flutter/material.dart';

import 'app.dart';
import 'widgets/cards/factory/definitions/index.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
<<<<<<< HEAD
  runApp(DinqApp());
=======
  // 初始化卡片注册表
  initializeCardRegistry();
  runApp(const DinqApp());
>>>>>>> e3f848713441b52b4387dff2e68ff57ea6446886
}
