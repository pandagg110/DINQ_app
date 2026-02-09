import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

/// 图片工具类
class ImageUtils {
  /// 选择单个图片
  static Future<File?> pickSinglePicture(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) {
      return File(image.path);
    }
    return null;
  }

  /// 相册权限
  static Future<bool> checkPhotoPermission() async {
    var photoStatus = await Permission.photos.status;
    var storageStatus = await Permission.storage.status;

    bool hasPer = true;
    if (Platform.isIOS) {
      if (!(photoStatus.isGranted || photoStatus.isLimited)) {
        hasPer = false;
      }
    } else {
      if (!((photoStatus.isGranted || photoStatus.isLimited) ||
          (storageStatus.isGranted || storageStatus.isLimited))) {
        hasPer = false;
      }
    }
    if (hasPer == false) {
      return await requestPhotoPermission();
    }
    return true;
  }

  /// 请求权限 是否同意
  static Future<bool> requestPhotoPermission() async {
    Map<Permission, PermissionStatus> statuses;
    if (Platform.isIOS) {
      statuses = await [Permission.photos].request();
    } else {
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      if (deviceInfo.version.sdkInt > 32) {
        statuses = await [Permission.photos].request();
      } else {
        statuses = await [Permission.storage].request();
      }
    }
    return statuses.values.first.isGranted || statuses.values.first.isLimited;
  }
}
