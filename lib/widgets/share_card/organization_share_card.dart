import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../models/organization_share_models.dart';
import '../../utils/asset_path.dart';
import '../../utils/org_avatar.dart';

/// 组织分享卡片，对齐 Web `OrganizationShareCard.tsx`（1200×630）。
class OrganizationShareCard extends StatelessWidget {
  const OrganizationShareCard({super.key, required this.org});

  final OrganizationShareTarget org;

  static const _tagColors = [
    Color(0xBBFDE277),
    Color(0xBBFED7D7),
    Color(0xBBD6F995),
    Color(0xBBC6E2FF),
    Color(0xBBE2C6FF),
    Color(0xBBFFE4CC),
    Color(0xBBD4F4DD),
    Color(0xBBFFD6E8),
  ];

  @override
  Widget build(BuildContext context) {
    final tags = org.tags.where((tag) => tag.trim().isNotEmpty).take(4).toList();
    final details = <String>[
      if (org.location != null && org.location!.trim().isNotEmpty) org.location!.trim(),
      if (org.memberCount != null)
        '${org.memberCount} ${org.memberCount == 1 ? 'member' : 'members'}',
    ];

    return Container(
      width: 1200,
      height: 630,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      _buildLogo(),
                      const SizedBox(width: 28),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              org.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Geist',
                                fontSize: 56,
                                height: 64 / 56,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF171717),
                              ),
                            ),
                            if (details.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                details.join(' · '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Geist',
                                  fontSize: 26,
                                  color: Color(0xFF6B6862),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: SvgPicture.asset(
                    assetPath('logo/dinq-black.svg'),
                    width: 68,
                    height: 68,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: const Color(0xD1FFFFFF),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (org.description != null && org.description!.trim().isNotEmpty)
                        ? org.description!.trim()
                        : '${org.name} on DINQ',
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 34,
                      height: 46 / 34,
                      color: Color(0xFF171717),
                    ),
                  ),
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (var i = 0; i < tags.length; i++)
                          Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _tagColors[i % _tagColors.length],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              tags[i],
                              style: const TextStyle(
                                fontFamily: 'Geist',
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF171717),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              if (org.location != null && org.location!.trim().isNotEmpty)
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.place_outlined,
                        size: 32,
                        color: Color(0xFFA6A6A6),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          org.location!.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Geist',
                            fontSize: 30,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFA6A6A6),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.link, size: 34, color: Color(0xFFA6A6A6)),
                  const SizedBox(width: 14),
                  Text(
                    'dinq.me/${org.slug}',
                    style: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 30,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFA6A6A6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    final logoUrl = org.logoUrl?.trim() ?? '';
    if (logoUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Image.network(
          logoUrl,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _logoFallback(),
        ),
      );
    }
    return _logoFallback();
  }

  Widget _logoFallback() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: orgAvatarColor(org.name),
        borderRadius: BorderRadius.circular(28),
      ),
      alignment: Alignment.center,
      child: Text(
        orgInitials(org.name),
        style: const TextStyle(
          fontFamily: 'Geist',
          fontSize: 50,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1F1F1F),
        ),
      ),
    );
  }
}
