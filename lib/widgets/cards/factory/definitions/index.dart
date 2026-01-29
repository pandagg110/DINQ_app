/// Card Definitions Index
/// 
/// 导出所有卡片定义

export 'title_card.dart';
export 'github_card.dart';
export 'linkedin_card.dart';
export 'twitter_card.dart';
export 'image_card.dart';
export 'link_card.dart';
export 'markdown_card.dart';
export 'note_card.dart';
export 'scholar_card.dart';
export 'youtube_card.dart';
export 'openreview_card.dart';
export 'huggingface_card.dart';
export 'bluesky_card.dart';
export 'instagram_card.dart';
export 'reddit_card.dart';
export 'bilibili_card.dart';
export 'spotify_card.dart';
export 'netease_card.dart';
export 'behance_card.dart';
export 'substack_card.dart';
export 'threads_card.dart';
export 'facebook_card.dart';
export 'medium_card.dart';
export 'wechat_card.dart';
export 'telegram_card.dart';
export 'career_trajectory_card.dart';
export 'achievement_network_card.dart';
export 'iframe_card.dart';

import '../card_definition.dart';
import '../card_registry.dart';
import 'title_card.dart';
import 'github_card.dart';
import 'linkedin_card.dart';
import 'twitter_card.dart';
import 'image_card.dart';
import 'link_card.dart';
import 'markdown_card.dart';
import 'note_card.dart';
import 'scholar_card.dart';
import 'youtube_card.dart';
import 'openreview_card.dart';
import 'huggingface_card.dart';
import 'bluesky_card.dart';
import 'instagram_card.dart';
import 'reddit_card.dart';
import 'bilibili_card.dart';
import 'spotify_card.dart';
import 'netease_card.dart';
import 'behance_card.dart';
import 'substack_card.dart';
import 'threads_card.dart';
import 'facebook_card.dart';
import 'medium_card.dart';
import 'wechat_card.dart';
import 'telegram_card.dart';
import 'career_trajectory_card.dart';
import 'achievement_network_card.dart';
import 'iframe_card.dart';

/// 社交卡片定义列表
/// 这些卡片需要后端数据源获取
final List<CardDefinition> socialCards = [
  ScholarCardDefinition(),
  GitHubCardDefinition(),
  LinkedInCardDefinition(),
  TwitterCardDefinition(),
  OpenReviewCardDefinition(),
  YouTubeCardDefinition(),
  HuggingFaceCardDefinition(),
  BlueskyCardDefinition(),
  InstagramCardDefinition(),
  RedditCardDefinition(),
  BilibiliCardDefinition(),
  SpotifyCardDefinition(),
  NeteaseCardDefinition(),
  BehanceCardDefinition(),
  SubstackCardDefinition(),
  ThreadsCardDefinition(),
  FacebookCardDefinition(),
  MediumCardDefinition(),
  WeChatCardDefinition(),
  TelegramCardDefinition(),
];

/// 通用卡片定义列表
final List<CardDefinition> generalCards = [
  MarkdownCardDefinition(),
  ImageCardDefinition(),
  NoteCardDefinition(),
  LinkCardDefinition(),
  TitleCardDefinition(),
  CareerTrajectoryCardDefinition(),
  AchievementNetworkCardDefinition(),
  IframeCardDefinition(),
];

/// 所有卡片定义
final List<CardDefinition> allCardDefinitions = [
  ...generalCards,
  ...socialCards,
];

/// AI 卡片定义列表
/// 这些卡片使用 AI 从外部源获取和处理数据
final List<CardDefinition> aiCards = [
  LinkCardDefinition(),
  AchievementNetworkCardDefinition(),
  GitHubCardDefinition(),
  ScholarCardDefinition(),
  TwitterCardDefinition(),
  BlueskyCardDefinition(),
  InstagramCardDefinition(),
  RedditCardDefinition(),
  YouTubeCardDefinition(),
  BilibiliCardDefinition(),
  SpotifyCardDefinition(),
  NeteaseCardDefinition(),
  BehanceCardDefinition(),
  SubstackCardDefinition(),
  OpenReviewCardDefinition(),
  HuggingFaceCardDefinition(),
  LinkedInCardDefinition(),
  ThreadsCardDefinition(),
  FacebookCardDefinition(),
  MediumCardDefinition(),
  CareerTrajectoryCardDefinition(),
  // CareerHighlightsCard, // 如果需要可以添加
];

/// 卡片类型集合，用于快速查找
final Set<String> _socialCardTypes = socialCards.map((def) => def.type.toUpperCase()).toSet();
final Set<String> _aiCardTypes = aiCards.map((def) => def.type.toUpperCase()).toSet();

/// 检查卡片类型是否为社交卡片
bool isSocialCard(String type) {
  return _socialCardTypes.contains(type.toUpperCase());
}

/// 检查卡片类型是否为 AI 卡片
bool isAICard(String type) {
  return _aiCardTypes.contains(type.toUpperCase()) ||
      type.toLowerCase() == 'datasource';
}

/// 初始化卡片注册表
void initializeCardRegistry() {
  final registry = CardRegistry();
  for (final def in allCardDefinitions) {
    registry.register(def);
  }
}

