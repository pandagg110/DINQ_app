import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/upload_service.dart';
import '../stores/card_store.dart';
import '../utils/toast_util.dart';
import '../widgets/common/read_bytes_from_path_stub.dart'
    if (dart.library.io) '../widgets/common/read_bytes_from_path_io.dart'
    as path_reader;

/// 选择图片 → 上传（getUploadUrl）→ 创建 IMAGE 卡片。
/// 返回 true 表示成功创建，false 表示用户取消或失败。
Future<bool> addImageCard(BuildContext context) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp'],
  );
  if (result == null || result.files.isEmpty) return false;
  final file = result.files.first;

  Uint8List bytes;
  if (file.bytes != null) {
    bytes = file.bytes!;
  } else if (!kIsWeb && file.path != null && file.path!.isNotEmpty) {
    try {
      bytes = await path_reader.readBytesFromPath(file.path!);
    } catch (e) {
      if (context.mounted) {
        ToastUtil.showError(
          context: context,
          title: '读取文件失败',
          description: e.toString(),
        );
      }
      return false;
    }
  } else {
    if (context.mounted) {
      ToastUtil.showError(
        context: context,
        title: '无法读取图片',
        description: '请重试或换一张图片',
      );
    }
    return false;
  }

  String contentType(String ext) {
    switch (ext.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  if (!context.mounted) return false;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                '上传中...',
                style: TextStyle(fontFamily: 'Geist', fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  try {
    final fileUrl = await UploadService().uploadFile(
      bytes: bytes,
      filename: file.name,
      contentType: contentType(file.extension ?? 'jpg'),
    );
    if (!context.mounted) return false;
    Navigator.of(context).pop(); // 关闭 loading
    context.read<CardStore>().addCard(
      type: 'IMAGE',
      metadata: {'url': fileUrl},
    );
    return true;
  } catch (e) {
    if (context.mounted) {
      Navigator.of(context).pop(); // 关闭 loading
      ToastUtil.showError(
        context: context,
        title: '上传失败',
        description: e.toString(),
      );
    }
    return false;
  }
}
