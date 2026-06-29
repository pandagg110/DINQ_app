class PlaceholderCardConfig {
  const PlaceholderCardConfig({
    required this.type,
    required this.name,
    required this.icon,
    required this.size,
  });

  final String type;
  final String name;
  final String icon;
  final ({int w, int h}) size;
}

final List<PlaceholderCardConfig> placeholderCardsConfig = [
  PlaceholderCardConfig(
    type: 'ACHIEVEMENT_NETWORK',
    name: 'Network',
    icon: 'i-lucide-network',
    size: (w: 4, h: 4),
  ),
  PlaceholderCardConfig(
    type: 'CAREER_TRAJECTORY',
    name: 'Career',
    icon: 'i-lucide-trending-up',
    size: (w: 2, h: 4),
  ),
  PlaceholderCardConfig(
    type: 'LINKEDIN',
    name: 'LinkedIn',
    icon: '/icons/social-icons/LinkedIn.svg',
    size: (w: 2, h: 2),
  ),
  PlaceholderCardConfig(
    type: 'GITHUB',
    name: 'GitHub',
    icon: '/icons/social-icons/Github.svg',
    size: (w: 2, h: 2),
  ),
  PlaceholderCardConfig(
    type: 'TWITTER',
    name: 'X',
    icon: '/icons/social-icons/Twitter.svg',
    size: (w: 4, h: 2),
  ),
  PlaceholderCardConfig(
    type: 'SCHOLAR',
    name: 'Scholar',
    icon: '/icons/social-icons/Scholar.svg',
    size: (w: 2, h: 2),
  ),
  PlaceholderCardConfig(
    type: 'OPENREVIEW',
    name: 'OpenReview',
    icon: '/icons/social-icons/OpenReview.svg',
    size: (w: 2, h: 2),
  ),
  PlaceholderCardConfig(
    type: 'HUGGINGFACE',
    name: 'Hugging Face',
    icon: '/icons/social-icons/HuggingFace.svg',
    size: (w: 2, h: 2),
  ),
  PlaceholderCardConfig(
    type: 'IMAGE',
    name: 'Image',
    icon: '/images/card/image.svg',
    size: (w: 4, h: 2),
  ),
  PlaceholderCardConfig(
    type: 'LINK',
    name: 'Link',
    icon: 'i-lucide-link',
    size: (w: 2, h: 2),
  ),
];
