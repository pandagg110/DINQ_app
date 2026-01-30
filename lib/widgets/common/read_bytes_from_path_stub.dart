import 'dart:typed_data';

/// Web 等平台不支持从 path 读文件，仅占位
Future<Uint8List> readBytesFromPath(String path) async {
  throw UnsupportedError('readBytesFromPath 仅支持 iOS/Android/桌面，当前平台不支持');
}
