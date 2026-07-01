import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../common/asset_icon.dart';
import '../../../utils/asset_path.dart';

/// GitHub card, aligned with Web ShareCard/cards/GithubCard.tsx.
class GithubCard extends StatelessWidget {
  const GithubCard({super.key, this.username = ''});

  final String username;

  @override
  Widget build(BuildContext context) {
    final hasData = username.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: hasData
            ? MainAxisAlignment.spaceBetween
            : MainAxisAlignment.start,
        children: [
          const AssetIcon(asset: 'icons/social-icons/Github.svg', size: 48),
          if (!hasData)
            const Expanded(child: _EmptyState(iconSize: 32, boxSize: 64))
          else
            Align(
              alignment: Alignment.centerRight,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: double.infinity,
                  height: 179,
                  child: OverflowBox(
                    alignment: Alignment.centerRight,
                    maxWidth: 660,
                    child: Image.network(
                      'https://ghchart.rshah.org/$username',
                      height: 179,
                      fit: BoxFit.fitHeight,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(color: const Color(0xFFF3F4F6)),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.iconSize, required this.boxSize});

  final double iconSize;
  final double boxSize;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Transform.translate(
        offset: const Offset(0, -20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: boxSize,
              height: boxSize,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: SvgPicture.asset(
                assetPath('icons/error.svg'),
                width: iconSize,
                height: iconSize,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No content yet.',
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 24,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
