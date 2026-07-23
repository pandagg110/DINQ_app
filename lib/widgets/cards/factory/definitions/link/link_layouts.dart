import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../utils/icon_mapping.dart';
import '../social_image_upload_preview.dart';

class LinkLayouts {
  // Special icons that override backend favicon
  static const Map<String, String> specialIcons = {
    'xiaohongshu.com': 'icons/social-icons/RedNote.svg',
    'xhslink.com': 'icons/social-icons/RedNote.svg',
    'discord.gg': 'icons/social-icons/Discord.svg',
    'discord.com': 'icons/social-icons/Discord.svg',
    'openreview.net': 'icons/social-icons/OpenReview.svg',
    'dinq.me': 'logo/dinq-black.svg',
  };

  static String? getSpecialIcon(String url) {
    try {
      final uri = Uri.parse(url);
      final hostname = uri.host.toLowerCase();
      for (final entry in specialIcons.entries) {
        if (hostname.contains(entry.key)) {
          return entry.value;
        }
      }
    } catch (e) {
      // Invalid URL
    }
    return null;
  }

  static Widget buildLinkIcon({
    required String? favicon,
    required String url,
    required double dimension,
  }) {
    final specialIcon = getSpecialIcon(url);
    final iconSrc =
        specialIcon ?? (favicon?.isNotEmpty == true ? favicon : null);

    if (iconSrc != null) {
      final isDinqLogo = specialIcon?.contains('dinq') == true;
      return Container(
        width: dimension,
        height: dimension,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: isDinqLogo
            ? EdgeInsets.all(dimension * 0.15)
            : EdgeInsets.zero,
        child: specialIcon != null
            ? _buildSpecialIconAsset(specialIcon)
            : Image.network(
                iconSrc,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.link, color: Colors.grey);
                },
              ),
      );
    }

    return Container(
      width: dimension,
      height: dimension,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.link, color: Colors.black),
    );
  }

  /// 渲染映射表命中的本地图标（QA 三轮打回：OpenReview 卡 logo 缺失）。
  /// `icons/social-icons/*.svg` 实为 `<pattern>` 包 base64 位图的“伪矢量”，
  /// flutter_svg/vector_graphics 编译后没有任何绘制指令（产物仅 14 字节头），
  /// SvgPicture 会渲染成空白 —— 与 AssetIcon/add_page 一致，统一经
  /// [mapSvgToPng] 换成 assets/icons/logo 下的 PNG 用 Image.asset 渲染；
  /// 真矢量（如 dinq-black.svg）仍走 SvgPicture。
  static Widget _buildSpecialIconAsset(String specialIcon) {
    final asset = specialIcon.contains('icons/social-icons/')
        ? mapSvgToPng(specialIcon)
        : specialIcon;
    if (asset.toLowerCase().endsWith('.svg')) {
      return SvgPicture.asset('assets/$asset', fit: BoxFit.contain);
    }
    return Image.asset('assets/$asset', fit: BoxFit.contain);
  }

  static String cleanUrl(String url) {
    return url
        .replaceAll(RegExp(r'^https?://'), '')
        .replaceAll(RegExp(r'/$'), '');
  }

  // 2x2 Size - Compact
  static Widget build2x2Layout({
    required String title,
    required String url,
    required String? favicon,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          buildLinkIcon(favicon: favicon, url: url, dimension: 40),
          const SizedBox(height: 8),
          // Title and URL
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.isNotEmpty)
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (url.isNotEmpty) ...[
                  if (title.isNotEmpty) const SizedBox(height: 4),
                  Text(
                    cleanUrl(url),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2x4 Size - Vertical
  static Widget build2x4Layout({
    required String title,
    required String url,
    required String? favicon,
    required String? ogImage,
    required bool editable,
    required ValueChanged<String> onImageChange,
  }) {
    final hasImage = ogImage != null && ogImage.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top section: icon + title + url
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildLinkIcon(favicon: favicon, url: url, dimension: 40),
              const SizedBox(height: 8),
              if (title.isNotEmpty)
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              if (url.isNotEmpty) ...[
                if (title.isNotEmpty) const SizedBox(height: 4),
                Text(
                  cleanUrl(url),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          // Bottom section: og_image (1:1 ratio)
          if (hasImage || editable)
            Expanded(
              child: AspectRatio(
                aspectRatio: 1.0,
                child: _buildPreviewImage(
                  imageUrl: ogImage,
                  editable: editable,
                  onImageChange: onImageChange,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 4x2 Size - Medium
  static Widget build4x2Layout({
    required String title,
    required String url,
    required String? favicon,
    required String? ogImage,
    required bool editable,
    required ValueChanged<String> onImageChange,
  }) {
    final hasImage = ogImage != null && ogImage.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left section: icon + title + url
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildLinkIcon(favicon: favicon, url: url, dimension: 40),
              const SizedBox(height: 8),
              SizedBox(
                width: 150,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title.isNotEmpty)
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (url.isNotEmpty) ...[
                      if (title.isNotEmpty) const SizedBox(height: 4),
                      Text(
                        cleanUrl(url),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Right section: preview image (1:1 ratio)
          if (hasImage || editable)
            Expanded(
              child: AspectRatio(
                aspectRatio: 1.0,
                child: _buildPreviewImage(
                  imageUrl: ogImage,
                  editable: editable,
                  onImageChange: onImageChange,
                  objectFit: BoxFit.cover,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 4x4 Size - Full
  static Widget build4x4Layout({
    required String title,
    required String url,
    required String? favicon,
    required String? ogImage,
    required bool editable,
    required ValueChanged<String> onImageChange,
  }) {
    final hasImage = ogImage != null && ogImage.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top section: icon, title, url
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildLinkIcon(favicon: favicon, url: url, dimension: 40),
              const SizedBox(height: 8),
              SizedBox(
                width: 200,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title.isNotEmpty)
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (url.isNotEmpty) ...[
                      if (title.isNotEmpty) const SizedBox(height: 4),
                      Text(
                        cleanUrl(url),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          // Bottom section: og_image (2:1 ratio)
          if (hasImage || editable)
            AspectRatio(
              aspectRatio: 2.0,
              child: _buildPreviewImage(
                imageUrl: ogImage,
                editable: editable,
                onImageChange: onImageChange,
              ),
            ),
        ],
      ),
    );
  }

  static Widget _buildPreviewImage({
    required String? imageUrl,
    required bool editable,
    required ValueChanged<String> onImageChange,
    BoxFit objectFit = BoxFit.cover,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SocialImageUploadPreview(
        imageUrl: imageUrl ?? '',
        editable: editable,
        altText: 'Link preview image',
        objectFit: objectFit,
        onImageChange: onImageChange,
      ),
    );
  }
}
