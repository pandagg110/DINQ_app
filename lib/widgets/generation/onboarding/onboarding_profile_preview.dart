import 'package:flutter/material.dart';

import '../../../utils/onboarding_draft_mapping.dart';

const _tagColors = [
  Color(0xFFFDE277),
  Color(0xFFFED7D7),
  Color(0xFFD6F995),
  Color(0xFFC6E2FF),
  Color(0xFFE2C6FF),
  Color(0xFFFFE4CC),
  Color(0xFFD4F4DD),
  Color(0xFFFFD6E8),
];

/// 对齐 Web `OnboardingProfilePreview.tsx`（桌面端右侧实时预览）。
class OnboardingProfilePreview extends StatelessWidget {
  const OnboardingProfilePreview({
    super.key,
    required this.name,
    required this.position,
    required this.company,
    required this.school,
    required this.location,
    required this.timezone,
    required this.bio,
    required this.avatarUrl,
    required this.tags,
  });

  final String name;
  final String position;
  final String company;
  final String school;
  final String location;
  final String timezone;
  final String bio;
  final String avatarUrl;
  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    final fullPosition = [position, company].where((e) => e.isNotEmpty).join(', ');
    final displayTags = normalizeProfileTags(tags);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 384),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AvatarPreview(url: avatarUrl),
          const SizedBox(height: 24),
          Text(
            name.isNotEmpty ? name : 'Your name',
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 32,
              fontWeight: FontWeight.w600,
              height: 1.2,
              color: name.isNotEmpty
                  ? const Color(0xFF171717)
                  : const Color(0xFF9E9B93),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFEEEDE9), height: 1),
          const SizedBox(height: 16),
          _PreviewRow(
            icon: Icons.work_outline,
            value: fullPosition,
            placeholder: 'Your position',
          ),
          const SizedBox(height: 12),
          _PreviewRow(
            icon: Icons.school_outlined,
            value: school,
            placeholder: 'Your school',
          ),
          const SizedBox(height: 12),
          _PreviewRow(
            icon: Icons.location_on_outlined,
            value: location,
            placeholder: 'Your location',
          ),
          const SizedBox(height: 12),
          _PreviewRow(
            icon: Icons.schedule,
            value: timezone,
            placeholder: 'Select timezone',
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...displayTags.asMap().entries.map(
                    (entry) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _tagColors[entry.key % _tagColors.length],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        entry.value,
                        style: const TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF171717),
                        ),
                      ),
                    ),
                  ),
              if (displayTags.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFDCD9D2),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: const Text(
                    'Tags appear here',
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 14,
                      color: Color(0xFF9E9B93),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: bio.isEmpty
                    ? const Color(0xFFDCD9D2)
                    : Colors.transparent,
                style: bio.isEmpty ? BorderStyle.solid : BorderStyle.none,
              ),
            ),
            child: Text(
              bio.isNotEmpty ? bio : 'Add a short bio',
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 14,
                height: 1.5,
                color: bio.isNotEmpty
                    ? const Color(0xFF171717)
                    : const Color(0xFF9E9B93),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Built by DINQ.me',
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 12,
              color: Color(0xFF9E9B93),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarPreview extends StatelessWidget {
  const _AvatarPreview({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFDCD9D2), width: 2),
        color: const Color(0xFFFAFAF8),
      ),
      clipBehavior: Clip.antiAlias,
      child: url.isNotEmpty
          ? Image.network(url, fit: BoxFit.cover)
          : const Icon(Icons.person_outline, size: 64, color: Color(0xFF9E9B93)),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({
    required this.icon,
    required this.value,
    required this.placeholder,
  });

  final IconData icon;
  final String value;
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF9E9B93)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value.isNotEmpty ? value : placeholder,
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 14,
              color: value.isNotEmpty
                  ? const Color(0xFF171717)
                  : const Color(0xFF9E9B93),
            ),
          ),
        ),
      ],
    );
  }
}
