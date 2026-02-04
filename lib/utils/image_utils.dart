import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

/// 图片工具类
class ImageUtils {
  /// 从图片字节数据获取图片尺寸
  /// 返回 (width, height)，如果解析失败返回 null
  static Future<({int width, int height})?> getImageDimensions(
    Uint8List imageBytes,
  ) async {
    try {
      final codec = await ui.instantiateImageCodec(imageBytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final dimensions = (width: image.width, height: image.height);
      image.dispose();
      return dimensions;
    } catch (e) {
      return null;
    }
  }

  /// 从图片字节数据获取图片宽高比
  /// 返回 width / height，如果解析失败返回 null
  static Future<double?> getImageAspectRatio(Uint8List imageBytes) async {
    final dimensions = await getImageDimensions(imageBytes);
    if (dimensions == null) return null;
    return dimensions.width / dimensions.height;
  }

  /// 从图片 URL 获取图片尺寸（通过 ImageProvider）
  /// 返回 (width, height)，如果解析失败返回 null
  static Future<({int width, int height})?> getImageDimensionsFromUrl(
    String imageUrl,
  ) async {
    try {
      final imageProvider = NetworkImage(imageUrl);
      final completer = Completer<({int width, int height})?>();
      
      imageProvider.resolve(const ImageConfiguration()).addListener(
        ImageStreamListener(
          (ImageInfo info, bool _) {
            final dimensions = (
              width: info.image.width,
              height: info.image.height,
            );
            completer.complete(dimensions);
          },
          onError: (exception, stackTrace) {
            completer.complete(null);
          },
        ),
      );
      
      return completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => null,
      );
    } catch (e) {
      return null;
    }
  }

  /// 从图片 URL 获取图片宽高比（通过 ImageProvider）
  /// 返回 width / height，如果解析失败返回 null
  static Future<double?> getImageAspectRatioFromUrl(String imageUrl) async {
    final dimensions = await getImageDimensionsFromUrl(imageUrl);
    if (dimensions == null) return null;
    return dimensions.width / dimensions.height;
  }

  /// 从图片 URL 下载图片并获取尺寸（备用方法）
  /// 注意：这个方法需要下载整个图片，可能比较慢
  /// 返回 (width, height)，如果解析失败返回 null
  static Future<({int width, int height})?> getImageDimensionsFromUrlByDownload(
    String imageUrl,
  ) async {
    try {
      final dio = Dio();
      final response = await dio.get<List<int>>(
        imageUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      
      if (response.data == null) return null;
      
      final imageBytes = Uint8List.fromList(response.data!);
      return await getImageDimensions(imageBytes);
    } catch (e) {
      return null;
    }
  }
}
