/// 占位卡片配置：类型、名称、图标、尺寸（网格格数 w x h）

class PlaceholderCardConfig {
  const PlaceholderCardConfig({
    required this.type,
    required this.name,
    required this.iconAsset,
    required this.size,
  });

  final String type;
  final String name;
  /// Flutter 资源路径，如 'assets/icons/network.png' 或 null 表示用 Icons
  final String? iconAsset;
  final ({int w, int h}) size;
}

/// 10 个占位卡片配置，按优先级排序；过滤掉已存在的类型后显示
final List<PlaceholderCardConfig> placeholderCardsConfig = [
  PlaceholderCardConfig(
    type: 'ACHIEVEMENT_NETWORK',
    name: 'Network',
    iconAsset: 'assets/icons/network.png',
    size: (w: 4, h: 4),
  ),
  PlaceholderCardConfig(
    type: 'CAREER_TRAJECTORY',
    name: 'Career',
    iconAsset: null, // 使用 Icons.trending_up
    size: (w: 2, h: 4),
  ),
  PlaceholderCardConfig(
    type: 'LINKEDIN',
    name: 'LinkedIn',
    iconAsset: 'assets/icons/social-icons/LinkedIn.svg',
    size: (w: 2, h: 2),
  ),
  PlaceholderCardConfig(
    type: 'GITHUB',
    name: 'GitHub',
    iconAsset: 'assets/icons/social-icons/Github.svg',
    size: (w: 2, h: 2),
  ),
  PlaceholderCardConfig(
    type: 'TWITTER',
    name: 'X',
    iconAsset: 'assets/icons/social-icons/Twitter.svg',
    size: (w: 4, h: 2),
  ),
  PlaceholderCardConfig(
    type: 'SCHOLAR',
    name: 'Scholar',
    iconAsset: 'assets/icons/social-icons/Scholar.svg',
    size: (w: 2, h: 2),
  ),
  PlaceholderCardConfig(
    type: 'OPENREVIEW',
    name: 'OpenReview',
    iconAsset: 'assets/icons/social-icons/OpenReview.svg',
    size: (w: 2, h: 2),
  ),
  PlaceholderCardConfig(
    type: 'HUGGINGFACE',
    name: 'Hugging Face',
    iconAsset: 'assets/icons/social-icons/HuggingFace.svg',
    size: (w: 2, h: 2),
  ),
  PlaceholderCardConfig(
    type: 'IMAGE',
    name: 'Image',
    iconAsset: 'assets/images/card/image.svg',
    size: (w: 4, h: 2),
  ),
  PlaceholderCardConfig(
    type: 'LINK',
    name: 'Link',
    iconAsset: 'assets/icons/link.png',
    size: (w: 2, h: 2),
  ),
];
