import 'package:flutter/material.dart';

/// 组织头像占位（无 logo 时）的取色/取首字母，逐行对齐 web
/// src/utils/format.ts 的 nameToAvatarColor / toInitials，保证同名组织
/// 在 App 与 web 上显示同样的底色和缩写。

/// web format.ts AVATAR_PALETTE（10 色）。
const List<Color> _orgAvatarPalette = [
  Color(0xFFF3D9C6),
  Color(0xFFD9DFE5),
  Color(0xFFF3D6D3),
  Color(0xFFE8D9B5),
  Color(0xFFE3DDD0),
  Color(0xFFEDD3D4),
  Color(0xFFD9DCC5),
  Color(0xFFD8E4D3),
  Color(0xFFD5DDE0),
  Color(0xFFD9E2D9),
];

/// web format.ts:41 nameToAvatarColor：hash=(hash+charCode*(i+1))%1000。
Color orgAvatarColor(String name) {
  var hash = 0;
  for (var i = 0; i < name.length; i++) {
    hash = (hash + name.codeUnitAt(i) * (i + 1)) % 1000;
  }
  return _orgAvatarPalette[hash % _orgAvatarPalette.length];
}

/// web format.ts:12 toInitials：去掉括号内容 → 按空白拆词 → 取前两个词
/// 首字母大写；空结果回退 "—"。
String orgInitials(String name) {
  final cleaned = name.replaceAll(RegExp(r'\(.*?\)'), '');
  final out = cleaned
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .map((w) => w.characters.first)
      .take(2)
      .join()
      .toUpperCase();
  return out.isEmpty ? '—' : out;
}
