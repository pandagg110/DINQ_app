/// 对齐 Web `onboarding/socials/page.tsx` 的社交图标配置。
abstract final class OnboardingSocialIcons {
  static const base = 'assets/icons/social-icons';

  /// Web 源码为小写文件名；Flutter 仓库沿用 PascalCase 资源名。
  static const _assetNames = <String, String>{
    'twitter.svg': 'Twitter.svg',
    'github.svg': 'Github.svg',
    'wechat.svg': 'WeChat.svg',
    'linkedin.svg': 'LinkedIn.svg',
    'youtube.svg': 'Youtube.svg',
    'instagram.svg': 'Instagram.svg',
    'medium.svg': 'Medium.svg',
    'behance.svg': 'Behance.svg',
    'substack.svg': 'Substack.svg',
    'huggingface.svg': 'HuggingFace.svg',
    'scholar.svg': 'Scholar.svg',
    'openreview.svg': 'OpenReview.svg',
    'tiktok.svg': 'Tiktok.svg',
    'telegram.svg': 'Telegram.svg',
    'spotify.svg': 'Spotify.svg',
    'facebook.svg': 'Facebook.svg',
    'discord.svg': 'Discord.svg',
    'link.svg': 'Link.svg',
    'reddit.svg': 'Reddit.svg',
    'threads.svg': 'Threads.svg',
    'bluesky.svg': 'BlueSky.svg',
    'website.svg': 'website.svg',
  };

  static const platformIconFiles = <({String file, String name})>[
    (file: 'twitter.svg', name: 'X'),
    (file: 'github.svg', name: 'GitHub'),
    (file: 'wechat.svg', name: 'WeChat'),
    (file: 'linkedin.svg', name: 'LinkedIn'),
    (file: 'youtube.svg', name: 'YouTube'),
    (file: 'instagram.svg', name: 'Instagram'),
    (file: 'medium.svg', name: 'Medium'),
    (file: 'behance.svg', name: 'Behance'),
    (file: 'substack.svg', name: 'Substack'),
    (file: 'huggingface.svg', name: 'Hugging Face'),
    (file: 'scholar.svg', name: 'Scholar'),
    (file: 'openreview.svg', name: 'OpenReview'),
    (file: 'tiktok.svg', name: 'TikTok'),
    (file: 'telegram.svg', name: 'Telegram'),
    (file: 'spotify.svg', name: 'Spotify'),
    (file: 'facebook.svg', name: 'Facebook'),
    (file: 'discord.svg', name: 'Discord'),
  ];

  static const typeToIconFile = <String, String>{
    'LINKEDIN': 'linkedin.svg',
    'GITHUB': 'github.svg',
    'TWITTER': 'twitter.svg',
    'SCHOLAR': 'scholar.svg',
    'OPENREVIEW': 'openreview.svg',
    'HUGGINGFACE': 'huggingface.svg',
    'MEDIUM': 'medium.svg',
    'SUBSTACK': 'substack.svg',
    'BEHANCE': 'behance.svg',
    'DISCORD': 'discord.svg',
    'FACEBOOK': 'facebook.svg',
    'INSTAGRAM': 'instagram.svg',
    'SPOTIFY': 'spotify.svg',
    'TELEGRAM': 'telegram.svg',
    'TIKTOK': 'tiktok.svg',
    'WECHAT': 'wechat.svg',
    'YOUTUBE': 'youtube.svg',
    'REDDIT': 'reddit.svg',
    'THREADS': 'threads.svg',
    'BLUESKY': 'bluesky.svg',
    'WEBSITE': 'website.svg',
    'LINK': 'link.svg',
  };

  static String assetFor(String file) {
    final assetName = _assetNames[file] ?? file;
    return '$base/$assetName';
  }

  static String iconForType(String type) =>
      assetFor(typeToIconFile[type.toUpperCase()] ?? 'link.svg');
}
