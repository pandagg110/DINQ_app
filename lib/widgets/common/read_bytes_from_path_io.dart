import 'dart:io';
import 'dart:typed_data';

/// 从本地路径读取文件字节（仅 iOS/Android/桌面）
Future<Uint8List> readBytesFromPath(String path) async {
  return File(path).readAsBytes();
}
