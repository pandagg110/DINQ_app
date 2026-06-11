import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/shortlist_models.dart';
import '../../theme/dinq_icons.dart';
import '../../theme/dinq_tokens.dart';
import '../../widgets/common/dinq_svg_icon.dart';

const List<Color> _avatarPalette = [
  Color(0xFFECD9AC),
  Color(0xFFF4D7C4),
  Color(0xFFD9E4CF),
  Color(0xFFD8DDF2),
  Color(0xFFEED0D6),
  Color(0xFFD4E8E1),
];

Color _statusColor(String label) {
  switch (label) {
    case 'Email obtained':
      return const Color(0xFFB7B4AE);
    case 'Contacted':
      return const Color(0xFF6E9B72);
    default:
      return const Color(0xFFD6D3CE);
  }
}

/// 候选人详情页（Enrich）。
/// 还原 `my_first_app` 的候选人详情样式，仅用真实 `FavoriteItem` 数据
/// （姓名/职位·公司/状态/标签 + 真实匹配理由 evidence + 置信度 confidence + 主页链接）。
/// 设计稿里的教育/工作时间线是 mock 数据，真实接口暂无，故省略。
class CandidateDetailPage extends StatelessWidget {
  const CandidateDetailPage({super.key, required this.item});

  final FavoriteItem item;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double s = (width / 390).clamp(0.9, 1.08).toDouble();

    return Scaffold(
      backgroundColor: DinqTokens.bgPage,
      body: SafeArea(
        child: Column(
          children: [
            _Header(scale: s, name: item.name),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16 * s, 8 * s, 16 * s, 26 * s),
                children: [
                  _ProfileCard(scale: s, item: item),
                  SizedBox(height: 12 * s),
                  if (item.evidence.isNotEmpty || item.confidence > 0)
                    _MatchContextCard(scale: s, item: item),
                  if (item.profileUrl.isNotEmpty) ...[
                    SizedBox(height: 12 * s),
                    _ProfileLinkButton(scale: s, url: item.profileUrl),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.scale, required this.name});

  final double scale;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16 * scale, 10 * scale, 12 * scale, 8 * scale),
      child: SizedBox(
        height: 42 * scale,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  width: 42 * scale,
                  height: 42 * scale,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: DinqTokens.bgCard,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: DinqTokens.shadow,
                        blurRadius: 16 * scale,
                        offset: Offset(0, 1 * scale),
                      ),
                    ],
                  ),
                  child: DinqSvgIcon(
                    assetName: DinqIcons.arrowLeft,
                    size: 21 * scale,
                    color: DinqTokens.textPrimary,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 58 * scale),
              child: Text(
                'Complete profile for $name',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: DinqTokens.textPrimary,
                  fontSize: 15 * scale,
                  height: 20 / 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.scale, required this.child});

  final double scale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18 * scale),
      decoration: BoxDecoration(
        color: DinqTokens.bgCard,
        borderRadius: BorderRadius.circular(22 * scale),
        border: Border.all(color: DinqTokens.borderLL),
      ),
      child: child,
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.scale, required this.item});

  final double scale;
  final FavoriteItem item;

  @override
  Widget build(BuildContext context) {
    final color = _avatarPalette[item.id.hashCode.abs() % _avatarPalette.length];
    return _Card(
      scale: scale,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 64 * scale,
                height: 64 * scale,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Text(
                  item.initials,
                  style: TextStyle(
                    fontSize: 22 * scale,
                    fontWeight: FontWeight.w700,
                    color: DinqTokens.textPrimary,
                  ),
                ),
              ),
              SizedBox(width: 16 * scale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 18 * scale,
                              height: 24 / 18,
                              fontWeight: FontWeight.w700,
                              color: DinqTokens.textPrimary,
                            ),
                          ),
                        ),
                        _StatusPill(scale: scale, label: item.statusLabel),
                      ],
                    ),
                    SizedBox(height: 4 * scale),
                    Text(
                      item.roleLine,
                      style: TextStyle(
                        fontSize: 13 * scale,
                        height: 18 / 13,
                        fontWeight: FontWeight.w400,
                        color: DinqTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (item.tagList.isNotEmpty) ...[
            SizedBox(height: 16 * scale),
            Wrap(
              spacing: 7 * scale,
              runSpacing: 7 * scale,
              children: item.tagList
                  .map((t) => _Tag(scale: scale, label: t))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _MatchContextCard extends StatelessWidget {
  const _MatchContextCard({required this.scale, required this.item});

  final double scale;
  final FavoriteItem item;

  @override
  Widget build(BuildContext context) {
    final pct = (item.confidence * 100).round();
    return _Card(
      scale: scale,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Match context',
            style: TextStyle(
              fontSize: 14 * scale,
              height: 19 / 14,
              fontWeight: FontWeight.w700,
              color: DinqTokens.textPrimary,
            ),
          ),
          SizedBox(height: 10 * scale),
          RichText(
            text: TextSpan(
              style: TextStyle(
                color: DinqTokens.textSecondary,
                fontSize: 13 * scale,
                height: 19 / 13,
                fontWeight: FontWeight.w500,
              ),
              children: [
                if (pct > 0)
                  TextSpan(
                    text: '$pct% ',
                    style: const TextStyle(
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                TextSpan(
                  text: item.evidence.isNotEmpty
                      ? item.evidence
                      : 'No additional match context available.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileLinkButton extends StatelessWidget {
  const _ProfileLinkButton({required this.scale, required this.url});

  final double scale;
  final String url;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      child: Container(
        width: double.infinity,
        height: 52 * scale,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: DinqTokens.textPrimary,
          borderRadius: BorderRadius.circular(14 * scale),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.open_in_new_rounded, size: 18 * scale, color: DinqTokens.bgCard),
            SizedBox(width: 10 * scale),
            Text(
              'View source profile',
              style: TextStyle(
                fontSize: 15 * scale,
                fontWeight: FontWeight.w600,
                color: DinqTokens.bgCard,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.scale, required this.label});

  final double scale;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(label);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6 * scale,
          height: 6 * scale,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 6 * scale),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12 * scale,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.scale, required this.label});

  final double scale;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 5 * scale),
      decoration: BoxDecoration(
        color: DinqTokens.bgSurface,
        borderRadius: BorderRadius.circular(8 * scale),
        border: Border.all(color: DinqTokens.borderL),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12 * scale,
          height: 16 / 12,
          fontWeight: FontWeight.w500,
          color: DinqTokens.textSecondary,
        ),
      ),
    );
  }
}
