import 'dart:typed_data';
import 'package:dinq_app/utils/top_toast_util.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/upload_service.dart';
import '../stores/card_store.dart';
import 'image_utils.dart';

/// 选择图片 → 上传（getUploadUrl）→ 创建 IMAGE 卡片。
/// 返回 true 表示成功创建，false 表示用户取消或失败。
///
/// QA：底部 bar「添加图片」应调起本地相册而不是文件夹视图 —— 原实现走
/// file_picker（系统文件浏览器），改为复用 [ImageUtils.pickSinglePicture]
///（image_picker 相册，与 settings_profile_page 头像上传同一入口），
/// 后续上传/创建卡片链路保持不变。
Future<bool> addImageCard(BuildContext context) async {
  final picked = await ImageUtils.pickSinglePicture(context);
  if (picked == null) return false;

  Uint8List bytes;
  try {
    bytes = await picked.readAsBytes();
  } catch (e) {
    if (context.mounted) {
      TopToastUtil.showError(
        context: context,
        title: '读取文件失败',
        description: e.toString(),
      );
    }
    return false;
  }

  final filename = picked.path.split('/').last;
  final ext = filename.contains('.') ? filename.split('.').last : 'jpg';

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
                'Uploading...',
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
      filename: filename,
      contentType: contentType(ext),
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
      TopToastUtil.showError(
        context: context,
        title: '上传失败',
        description: e.toString(),
      );
    }
    return false;
  }
}
