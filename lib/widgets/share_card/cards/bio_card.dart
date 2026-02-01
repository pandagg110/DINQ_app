import 'package:flutter/material.dart';

/// Bio 卡片，对应 Web ShareCard/cards/BioCard.tsx
class BioCard extends StatelessWidget {
  const BioCard({super.key, required this.bio});

  final String bio;

  @override
  Widget build(BuildContext context) {
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
          const Text(
            'Bio',
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: Color(0xFF000000),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 30),
          Text(
            bio,
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 24,
              height: 1.42,
              color: Color(0xFF171717),
            ),
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
