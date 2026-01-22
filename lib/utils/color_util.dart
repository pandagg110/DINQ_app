import 'dart:math';

import 'package:flutter/cupertino.dart';

abstract class ColorUtil {
  static Color get randomColor {
    Random random = Random();
    return Color.fromARGB(255, random.nextInt(256), random.nextInt(256), random.nextInt(256));
  }

  /// 主颜色
  static Color get mainColor {
    return const Color(0xFF171717);
  }

  static Color get textColor {
    return const Color(0xFF171717);
  }

  static Color get sub1TextColor {
    return const Color(0xA3303030);
  }

  static Color get sub2TextColor {
    return const Color(0x66303030);
  }

  static Color get sub3TextColor {
    return const Color(0xFF919191);
  }

  static Color get sub4TextColor {
    return const Color(0xFFBDBDBD);
  }
}
