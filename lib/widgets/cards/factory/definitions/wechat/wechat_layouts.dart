import 'package:flutter/material.dart';
import '../../../../common/asset_icon.dart';

class WeChatLayouts {
  // 2x2 Size - Compact
  static Widget build2x2Layout({
    required String username,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          const AssetIcon(asset: 'icons/social-icons/WeChat.svg', size: 40),
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
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          const AssetIcon(asset: 'icons/social-icons/WeChat.svg', size: 40),
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
          if (imageUrl != null && imageUrl.isNotEmpty)
            Expanded(
              child: AspectRatio(
                aspectRatio: 1.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
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

  // 4x2 Size - Horizontal
  static Widget build4x2Layout({
    required String username,
    required String? imageUrl,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon + Username
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const AssetIcon(asset: 'icons/social-icons/WeChat.svg', size: 40),
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
          if (imageUrl != null && imageUrl.isNotEmpty)
            Expanded(
              child: AspectRatio(
                aspectRatio: 1.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
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
    required String username,
    required String? imageUrl,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          const AssetIcon(asset: 'icons/social-icons/WeChat.svg', size: 40),
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
          if (imageUrl != null && imageUrl.isNotEmpty)
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
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

