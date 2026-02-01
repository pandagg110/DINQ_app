import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../utils/asset_path.dart';

/// LinkedIn 时间线卡片，对应 Web ShareCard/cards/LinkedInCard.tsx（简化版）
class LinkedInCard extends StatelessWidget {
  const LinkedInCard({
    super.key,
    this.careerJourney = const [],
  });

  final List<dynamic> careerJourney;

  @override
  Widget build(BuildContext context) {
    final hasData = careerJourney.isNotEmpty;
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
            assetPath('icons/social-icons/LinkedIn.svg'),
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
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: careerJourney.length.clamp(0, 5),
                itemBuilder: (context, i) {
                  final item = careerJourney[i];
                  final title = item is Map ? (item['title'] ?? item['representative'] ?? '') : '';
                  final score = item is Map ? (item['score'] ?? 0) : 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF323232),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '$title',
                            style: const TextStyle(
                              fontFamily: 'Geist',
                              fontSize: 20,
                              color: Color(0xFF171717),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (score > 0)
                          Text(
                            '$score',
                            style: const TextStyle(
                              fontFamily: 'Geist',
                              fontSize: 18,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
