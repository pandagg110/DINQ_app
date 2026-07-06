/*
 * ShareCard Component - Flutter 迁移自 Web example/src/components/business/ShareCard
 * 用于 OG 图 / 分享预览，纯布局与样式，无业务请求。
 */

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../models/user_models.dart';
import '../../utils/asset_path.dart';
import 'cards/bio_card.dart';
import 'cards/career_card.dart';
import 'cards/github_card.dart';
import 'cards/linkedin_card.dart';
import 'cards/network_card.dart';
import 'cards/scholar_card.dart';
import 'cards/tags_card.dart';

/// 分享卡片主组件，对应 Web [ShareCard](example/src/components/business/ShareCard/index.tsx)。
/// [userInfo] 用户信息；[cardsMap] 卡片类型 -> 元数据，用于渲染 leftCard/rightCard。
class ShareCard extends StatelessWidget {
  const ShareCard({
    super.key,
    required this.userInfo,
    required this.cardsMap,
    this.themeMode = 'classic',
    this.themeColor = 'default',
    this.leftCardType,
    this.rightCardType,
    this.logoUrl,
    this.verifiedCount = 0,
  });

  final UserData userInfo;
  final Map<String, dynamic> cardsMap;

  /// classic | card
  final String themeMode;

  /// default | colorful
  final String themeColor;

  /// LINKEDIN | GITHUB | SCHOLAR | BIO
  final String? leftCardType;

  /// ACHIEVEMENT_NETWORK | CAREER_TRAJECTORY
  final String? rightCardType;
  final String? logoUrl;
  final int verifiedCount;

  static const List<String> _firstCards = [
    'LINKEDIN',
    'GITHUB',
    'SCHOLAR',
    'BIO',
  ];
  static const List<String> _secondCards = [
    'ACHIEVEMENT_NETWORK',
    'CAREER_TRAJECTORY',
  ];

  static const List<Color> _tagColors = [
    Color(0xFFCDE3FF),
    Color(0xFFE0DCFF),
    Color(0xFFE8DEDC),
  ];

  List<String> get _tags {
    final t = userInfo.tags;
    if (t.isEmpty) return [];
    return t
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .take(3)
        .toList();
  }

  String get _firstCardType {
    if (leftCardType != null && leftCardType!.isNotEmpty) return leftCardType!;
    for (final ct in _firstCards) {
      if (cardsMap.containsKey(ct) || ct == 'BIO') return ct;
    }
    return 'BIO';
  }

  String get _secondCardType {
    if (rightCardType != null && rightCardType!.isNotEmpty) {
      return rightCardType!;
    }
    for (final ct in _secondCards) {
      if (cardsMap.containsKey(ct)) return ct;
    }
    return 'ACHIEVEMENT_NETWORK';
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  @override
  Widget build(BuildContext context) {
    final isColorful = themeColor == 'colorful';
    final isClassic = themeMode == 'classic';

    Widget content = Padding(
      padding: const EdgeInsets.fromLTRB(40, 40, 40, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTopSection(),
          const SizedBox(height: 28),
          if (isClassic) _buildClassicMiddle() else _buildCardModeMiddle(),
          const SizedBox(height: 28),
          _buildBottomSection(),
        ],
      ),
    );

    if (isColorful) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFFE2EFFF), Color(0xFFEAE7FF)],
          ),
        ),
        padding: const EdgeInsets.all(2),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(painter: _ColorfulCardBackgroundPainter()),
              ),
              content,
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.transparent, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: content,
    );
  }

  Widget _buildTopSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildUserAvatar(),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      userInfo.name.isEmpty ? 'DINQ User' : userInfo.name,
                      style: const TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 48,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF000000),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (verifiedCount > 0) ...[
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6),
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(
                            assetPath('icons/verified-badge-inverted.svg'),
                            width: 24,
                            height: 24,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$verifiedCount',
                            style: const TextStyle(
                              fontFamily: 'Geist',
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              if (userInfo.fullPosition.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  userInfo.fullPosition,
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 28,
                    height: 1.29,
                    color: Color(0xFF4B5563),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 24),
        SizedBox(
          width: 120,
          height: 120,
          child: logoUrl != null && logoUrl!.isNotEmpty
              ? Image.network(logoUrl!, fit: BoxFit.contain)
              : Image.asset(
                  assetPath('profile/default-avator.png'),
                  fit: BoxFit.contain,
                ),
        ),
      ],
    );
  }

  Widget _buildUserAvatar() {
    final fallback = Image.asset(
      assetPath('profile/default-avator.png'),
      width: 120,
      height: 120,
      fit: BoxFit.cover,
    );

    return Container(
      width: 120,
      height: 120,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFF3F4F6),
      ),
      clipBehavior: Clip.antiAlias,
      child: userInfo.avatarUrl.isNotEmpty
          ? Image.network(
              userInfo.avatarUrl,
              width: 120,
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => fallback,
            )
          : fallback,
    );
  }

  Widget _buildClassicMiddle() {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              userInfo.bio,
              style: const TextStyle(
                fontFamily: 'Geist',
                fontSize: 32,
                height: 1.375,
                color: Color(0xFF171717),
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            ClipRect(
              child: Row(
                children: _tags.asMap().entries.map((e) {
                  final i = e.key;
                  final tag = e.value;
                  return Padding(
                    padding: EdgeInsets.only(left: i == 0 ? 0 : 12),
                    child: Container(
                      height: 54,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: themeColor == 'default'
                            ? _tagColors[i % _tagColors.length].withValues(
                                alpha: 0.73,
                              )
                            : const Color(0xFF888888).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        tag,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.clip,
                        style: const TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF171717),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardModeMiddle() {
    final first = _buildCardByType(_firstCardType);
    final second = _buildCardByType(_secondCardType);
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: first),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(flex: 3, child: second),
                const SizedBox(height: 20),
                Expanded(flex: 2, child: TagsCard(tags: _tags)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardByType(String type) {
    final data = Map<String, dynamic>.from(cardsMap[type] ?? {});
    if (type == 'ACHIEVEMENT_NETWORK') {
      data['currentUserAvatar'] = userInfo.avatarUrl;
    }
    if (type == 'BIO') {
      data['bio'] = userInfo.bio;
    }

    switch (type) {
      case 'LINKEDIN':
        return LinkedInCard(
          careerJourney:
              (data['career_journey'] ?? data['careerJourney'] ?? [])
                  as List<dynamic>,
        );
      case 'GITHUB':
        return GithubCard(username: (data['username'] ?? '').toString());
      case 'SCHOLAR':
        return ScholarCard(
          topTierPapers: _toInt(
            data['top_tier_papers'] ?? data['topTierPapers'],
          ),
          totalPapers: _toInt(data['total_papers'] ?? data['totalPapers']),
          hIndex: _toInt(data['h_index'] ?? data['hIndex']),
          summary: (data['summary'] ?? '').toString(),
        );
      case 'BIO':
        return BioCard(bio: (data['bio'] ?? userInfo.bio).toString());
      case 'ACHIEVEMENT_NETWORK':
        return NetworkCard(
          connections: (data['connections'] ?? []).cast<dynamic>(),
          currentUserAvatar:
              (data['currentUserAvatar'] ?? userInfo.avatarUrl) as String?,
        );
      case 'CAREER_TRAJECTORY':
        return CareerCard(segments: (data['segments'] ?? []).cast<dynamic>());
      default:
        return BioCard(bio: userInfo.bio);
    }
  }

  Widget _buildBottomSection() {
    return Row(
      children: [
        if (userInfo.location.isNotEmpty)
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 28,
                  color: const Color(0xFF9CA3AF),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    userInfo.location,
                    style: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF9CA3AF),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        const Spacer(),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Find me',
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              '-',
              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 24),
            ),
            const SizedBox(width: 12),
            SvgPicture.asset(
              assetPath('logo/dinq-black.svg'),
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                const Color(0xFF9CA3AF).withValues(alpha: 0.5),
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'dinq.me/${userInfo.domain}',
              style: const TextStyle(
                fontFamily: 'Geist',
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ColorfulCardBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final basePaint = Paint()..color = Colors.white;
    canvas.drawRect(Offset.zero & size, basePaint);

    final scaleX = size.width / 600;
    final scaleY = size.height / 315;

    final firstRect = Rect.fromCenter(
      center: Offset(218.011 * scaleX, 132.737 * scaleY),
      width: 435 * scaleX,
      height: 274 * scaleY,
    );
    final firstPaint = Paint()
      ..color = const Color(0x662088FF)
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        _sigmaForStdDeviation(57 * ((scaleX + scaleY) / 2)),
      );
    canvas.save();
    canvas.translate(218.011 * scaleX, 132.737 * scaleY);
    canvas.rotate(10.0151 * 3.141592653589793 / 180);
    canvas.translate(-218.011 * scaleX, -132.737 * scaleY);
    canvas.drawOval(firstRect, firstPaint);
    canvas.restore();

    final secondRect = Rect.fromCenter(
      center: Offset(548.545 * scaleX, 146.237 * scaleY),
      width: 213.992 * scaleX,
      height: 151.5696 * scaleY,
    );
    final secondPaint = Paint()
      ..color = const Color(0x663A20FF)
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        _sigmaForStdDeviation(57 * ((scaleX + scaleY) / 2)),
      );
    canvas.save();
    canvas.translate(548.545 * scaleX, 146.237 * scaleY);
    canvas.rotate(10.0151 * 3.141592653589793 / 180);
    canvas.translate(-548.545 * scaleX, -146.237 * scaleY);
    canvas.drawOval(secondRect, secondPaint);
    canvas.restore();

    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Colors.white.withValues(alpha: 0.4),
    );
  }

  static double _sigmaForStdDeviation(double stdDeviation) {
    return stdDeviation * 0.57735 + 0.5;
  }

  @override
  bool shouldRepaint(covariant _ColorfulCardBackgroundPainter oldDelegate) =>
      false;
}
