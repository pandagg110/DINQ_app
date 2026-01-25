import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LinkLayouts {
  // Special icons that override backend favicon
  static const Map<String, String> specialIcons = {
    'xiaohongshu.com': 'icons/social-icons/RedNote.svg',
    'xhslink.com': 'icons/social-icons/RedNote.svg',
    'discord.gg': 'icons/social-icons/Discord.svg',
    'discord.com': 'icons/social-icons/Discord.svg',
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
    final iconSrc = specialIcon ?? (favicon?.isNotEmpty == true ? favicon : null);

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
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: isDinqLogo ? EdgeInsets.all(dimension * 0.15) : EdgeInsets.zero,
        child: specialIcon != null
            ? SvgPicture.asset(
                'assets/$iconSrc',
                fit: BoxFit.contain,
              )
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

  static String cleanUrl(String url) {
    return url.replaceAll(RegExp(r'^https?://'), '').replaceAll(RegExp(r'/$'), '');
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
  }) {
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
          if (ogImage != null && ogImage.isNotEmpty)
            Expanded(
              child: AspectRatio(
                aspectRatio: 1.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    ogImage,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.image, color: Colors.grey),
                        ),
                      );
                    },
                  ),
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
  }) {
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
          if (ogImage != null && ogImage.isNotEmpty)
            Expanded(
              child: AspectRatio(
                aspectRatio: 1.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    ogImage,
                    fit: BoxFit.cover,
                    alignment: Alignment.centerLeft,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.image, color: Colors.grey),
                        ),
                      );
                    },
                  ),
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
  }) {
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
          if (ogImage != null && ogImage.isNotEmpty)
            AspectRatio(
              aspectRatio: 2.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  ogImage,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.image, color: Colors.grey),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

