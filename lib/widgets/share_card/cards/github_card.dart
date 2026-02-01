import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../utils/asset_path.dart';

/// GitHub 卡片，对应 Web ShareCard/cards/GithubCard.tsx（简化版）
class GithubCard extends StatelessWidget {
  const GithubCard({super.key, this.username = ''});

  final String username;

  @override
  Widget build(BuildContext context) {
    final hasData = username.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            assetPath('icons/social-icons/Github.svg'),
            width: 48,
            height: 48,
          ),
          const SizedBox(height: 20),
          if (!hasData)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.error_outline, size: 32, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No content yet.',
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 24,
                        color: Color(0xFF000000),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Text(
              '@$username',
              style: const TextStyle(
                fontFamily: 'Geist',
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: Color(0xFF000000),
              ),
            ),
        ],
      ),
    );
  }
}
