import 'package:flutter/material.dart';
import '../../../../common/asset_icon.dart';
import '../social_image_upload_preview.dart';

class TelegramLayouts {
  // 2x2 Size - Compact
  static Widget build2x2Layout({required String username}) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          const AssetIcon(asset: 'icons/social-icons/Telegram.svg', size: 40),
          const Spacer(),
          // Username
          if (username.isNotEmpty)
            Text(
              '@$username',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF111827),
              ),
            ),
        ],
      ),
    );
  }

  // 2x4 Size - Vertical Layout
  static Widget build2x4Layout({
    required String username,
    required String? imageUrl,
    required bool editable,
    required ValueChanged<String> onImageChange,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          const AssetIcon(asset: 'icons/social-icons/Telegram.svg', size: 40),
          const Spacer(),
          // Username + Image at bottom
          if (username.isNotEmpty) ...[
            Text(
              '@$username',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if ((imageUrl != null && imageUrl.isNotEmpty) || editable)
            SizedBox(
              width: double.infinity,
              child: AspectRatio(
                aspectRatio: 1,
                child: SocialImageUploadPreview(
                  imageUrl: imageUrl ?? '',
                  editable: editable,
                  altText: 'Telegram',
                  onImageChange: onImageChange,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 4x2 Size - Horizontal
  static Widget build4x2Layout({
    required String username,
    required String? imageUrl,
    required bool editable,
    required ValueChanged<String> onImageChange,
  }) {
    final showImage = (imageUrl != null && imageUrl.isNotEmpty) || editable;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: showImage
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon + Username
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const AssetIcon(
                      asset: 'icons/social-icons/Telegram.svg',
                      size: 40,
                    ),
                    if (username.isNotEmpty)
                      Text(
                        '@$username',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF111827),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                // Right: Image
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: SocialImageUploadPreview(
                        imageUrl: imageUrl ?? '',
                        editable: editable,
                        altText: 'Telegram',
                        onImageChange: onImageChange,
                      ),
                    ),
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const AssetIcon(
                  asset: 'icons/social-icons/Telegram.svg',
                  size: 40,
                ),
                if (username.isNotEmpty)
                  Text(
                    '@$username',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF111827),
                    ),
                  ),
              ],
            ),
    );
  }

  // 4x4 Size - Full
  static Widget build4x4Layout({
    required String username,
    required String? imageUrl,
    required bool editable,
    required ValueChanged<String> onImageChange,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          const AssetIcon(asset: 'icons/social-icons/Telegram.svg', size: 40),
          const SizedBox(height: 8),
          // Username
          if (username.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                '@$username',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF111827),
                ),
              ),
            ),
          // Image Section
          if ((imageUrl != null && imageUrl.isNotEmpty) || editable)
            const Spacer(),
          if ((imageUrl != null && imageUrl.isNotEmpty) || editable)
            SizedBox(
              height: 150,
              width: double.infinity,
              child: SocialImageUploadPreview(
                imageUrl: imageUrl ?? '',
                editable: editable,
                altText: 'Telegram',
                onImageChange: onImageChange,
                objectFit: BoxFit.contain,
              ),
            ),
        ],
      ),
    );
  }
}
