import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../constants/app_constants.dart';
import '../search_panel/tool_search_progress.dart';
import 'advisor_enrich_row.dart';
import 'advisor_theme.dart';
import 'advisor_tool_phases.dart';

/// 与 TSX `AdvisorsList.tsx` 对齐。
class AdvisorsResultsView extends StatelessWidget {
  const AdvisorsResultsView({
    super.key,
    required this.advisors,
    this.rounds,
    this.isSearching = false,
    this.onShuffle,
    this.shuffleLoading = false,
    this.onEnrich,
  });

  final List<Map<String, dynamic>> advisors;
  final List<dynamic>? rounds;
  final bool isSearching;
  final VoidCallback? onShuffle;
  final bool shuffleLoading;
  final void Function(Map<String, dynamic> row)? onEnrich;

  @override
  Widget build(BuildContext context) {
    final hasAdvisors = advisors.isNotEmpty;
    final isFinished = !isSearching;

    if (!hasAdvisors && !isSearching) return const SizedBox.shrink();

    final progressPhases = rounds != null
        ? buildAdvisorPhasesFromRounds(
            rounds: rounds!,
            isFinished: isFinished,
          )
        : <ToolSearchPhase>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isSearching || (isFinished && hasAdvisors))
          ToolSearchProgress(
            phases: progressPhases,
            isFinished: isFinished,
            finishedLabel:
                'Found ${advisors.length} ${advisors.length == 1 ? 'Advisor' : 'Advisors'}',
          ),
        if (hasAdvisors && onShuffle != null) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: _ShuffleButton(
              onPressed: onShuffle!,
              loading: shuffleLoading,
            ),
          ),
        ],
        if (hasAdvisors) ...[
          const SizedBox(height: 12),
          for (var i = 0; i < advisors.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i < advisors.length - 1 ? 12 : 0),
              child: _AdvisorCard(
                advisor: advisors[i],
                onTap: onEnrich != null
                    ? () => onEnrich!(advisorToRow(advisors[i]))
                    : null,
              ),
            ),
        ],
      ],
    );
  }
}

class _ShuffleButton extends StatelessWidget {
  const _ShuffleButton({
    required this.onPressed,
    required this.loading,
  });

  final VoidCallback onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF0EFE9),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: loading ? null : onPressed,
        borderRadius: BorderRadius.circular(8),
        hoverColor: const Color(0xFFE8E7E1),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                SvgPicture.asset(
                  AdvisorTheme.iconRefresh,
                  width: 14,
                  height: 14,
                  colorFilter: const ColorFilter.mode(
                    AdvisorTheme.chipText,
                    BlendMode.srcIn,
                  ),
                ),
              const SizedBox(width: 6),
              Text(
                loading ? 'Finding...' : 'More advisors',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AdvisorTheme.chipText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdvisorCard extends StatelessWidget {
  const _AdvisorCard({
    required this.advisor,
    this.onTap,
  });

  final Map<String, dynamic> advisor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final institution = advisor['institution']?.toString() ??
        advisor['university']?.toString() ??
        '';
    final position = advisor['position']?.toString() ?? '';
    final name = advisor['name']?.toString() ?? 'Advisor';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        hoverColor: onTap != null ? const Color(0x08000000) : null,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AdvisorTheme.cardBorder),
          ),
          padding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                right: 0,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'dinq.me',
                      style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                    ),
                    const SizedBox(width: 6),
                    Opacity(
                      opacity: 0.5,
                      child: SvgPicture.asset(
                        AdvisorTheme.dinqLogo,
                        width: 20,
                        height: 20,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _AdvisorAvatar(url: advisor['image_url']?.toString()),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 48),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              if (position.isNotEmpty || institution.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Opacity(
                                          opacity: 0.5,
                                          child: SvgPicture.asset(
                                            AdvisorTheme.iconSchool,
                                            width: 14,
                                            height: 14,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          [
                                            if (position.isNotEmpty) position,
                                            institution,
                                          ].join(', '),
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF4B5563),
                                            height: 1.35,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _RatingsAndMatchSection(advisor: advisor),
                  if (advisor['match_reason']?.toString().isNotEmpty ?? false) ...[
                    const SizedBox(height: 12),
                    _RecommendationSection(
                      reason: advisor['match_reason']?.toString(),
                    ),
                  ],
                  if (advisor['risk_description']?.toString().isNotEmpty ?? false) ...[
                    const SizedBox(height: 12),
                    _RiskAssessmentSection(
                      description: advisor['risk_description']?.toString(),
                    ),
                  ],
                  _ContactInfoSection(advisor: advisor),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdvisorAvatar extends StatelessWidget {
  const _AdvisorAvatar({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final hasUrl = url != null && url!.isNotEmpty;
    return CircleAvatar(
      radius: 24,
      backgroundColor: const Color(0xFFEEEEEE),
      backgroundImage: hasUrl ? NetworkImage(url!) : null,
      child: hasUrl
          ? null
          : ClipOval(
              child: Image.asset(
                AdvisorTheme.avatarFallback,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
              ),
            ),
    );
  }
}

class _RatingsAndMatchSection extends StatelessWidget {
  const _RatingsAndMatchSection({required this.advisor});

  final Map<String, dynamic> advisor;

  int? _readStars(String key) {
    final v = advisor[key];
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final matchDetails = advisor['match_details'];
    final details = matchDetails is List
        ? matchDetails.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : <Map<String, dynamic>>[];
    final hasMatchDetails = details.isNotEmpty;

    final recommendation = _readStars('recommendation_stars');
    final match = _readStars('match_stars');
    final risk = _readStars('risk_stars');
    final action = _readStars('action_difficulty_stars');
    final safety = risk != null ? 6 - risk : null;
    final accessibility = action != null ? 6 - action : null;

    final hasRatings = recommendation != null ||
        match != null ||
        safety != null ||
        accessibility != null;

    if (!hasRatings && !hasMatchDetails) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AdvisorTheme.ratingsBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 480;
          final ratings = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (recommendation != null)
                _StarRatingRow(value: recommendation, label: 'Recommendation'),
              if (match != null) ...[
                if (recommendation != null) const SizedBox(height: 10),
                _StarRatingRow(value: match, label: 'Match Quality'),
              ],
              if (safety != null) ...[
                if (recommendation != null || match != null) const SizedBox(height: 10),
                _StarRatingRow(value: safety, label: 'Safety Level'),
              ],
              if (accessibility != null) ...[
                if (recommendation != null || match != null || safety != null)
                  const SizedBox(height: 10),
                _StarRatingRow(value: accessibility, label: 'Accessibility'),
              ],
            ],
          );

          final matchPanel = hasMatchDetails
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Research Match',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (var i = 0; i < details.length && i < 3; i++)
                      Padding(
                        padding: EdgeInsets.only(bottom: i < 2 ? 10 : 0),
                        child: _MatchDetailRow(
                          label: details[i]['label']?.toString() ?? '',
                          value: _readPercent(details[i]['value']),
                          color: AdvisorTheme.matchBarColors[i % 3],
                        ),
                      ),
                  ],
                )
              : null;

          if (isWide && matchPanel != null) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: constraints.maxWidth * 0.4, child: ratings),
                Container(
                  width: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  color: const Color(0x80E5E7EB),
                  height: 120,
                ),
                Expanded(child: matchPanel),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ratings,
              if (matchPanel != null) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Divider(height: 1, color: Color(0x80E5E7EB)),
                ),
                matchPanel,
              ],
            ],
          );
        },
      ),
    );
  }

  int _readPercent(dynamic value) {
    if (value is num) return value.clamp(0, 100).toInt();
    return (int.tryParse(value?.toString() ?? '') ?? 0).clamp(0, 100);
  }
}

class _StarRatingRow extends StatelessWidget {
  const _StarRatingRow({
    required this.value,
    required this.label,
  });

  final int value;
  final String label;

  Color get _color {
    if (value >= 4) return AdvisorTheme.scoreGood;
    if (value == 3) return AdvisorTheme.scoreModerate;
    return AdvisorTheme.scoreLow;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 112,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
        ),
        Row(
          children: List.generate(5, (i) {
            final filled = i < value;
            return Padding(
              padding: EdgeInsets.only(right: i < 4 ? 2 : 0),
              child: Icon(
                filled ? Icons.star : Icons.star_border,
                size: 14,
                color: filled ? _color : AdvisorTheme.starInactive,
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _MatchDetailRow extends StatelessWidget {
  const _MatchDetailRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 160,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: value / 100,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 40,
                child: Text(
                  '$value%',
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecommendationSection extends StatelessWidget {
  const _RecommendationSection({this.reason});

  final String? reason;

  @override
  Widget build(BuildContext context) {
    if (reason == null || reason!.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AdvisorTheme.reasonBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Why This Advisor',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AdvisorTheme.reasonTitle,
            ),
          ),
          const SizedBox(height: 4),
          _HighlightedText(
            text: reason!,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF4B5563),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _RiskAssessmentSection extends StatelessWidget {
  const _RiskAssessmentSection({this.description});

  final String? description;

  @override
  Widget build(BuildContext context) {
    if (description == null || description!.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AdvisorTheme.riskBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Risk Assessment',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AdvisorTheme.riskTitle,
            ),
          ),
          const SizedBox(height: 6),
          _HighlightedText(
            text: description!,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF4B5563),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _HighlightedText extends StatelessWidget {
  const _HighlightedText({
    required this.text,
    required this.style,
  });

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final parts = text.split(RegExp(r'(\*\*[^*]+\*\*)'));
    return RichText(
      text: TextSpan(
        style: style,
        children: parts.map((part) {
          if (part.startsWith('**') && part.endsWith('**')) {
            final content = part.substring(2, part.length - 2);
            return TextSpan(
              text: content,
              style: style.copyWith(
                color: const Color(0xFF171717),
                backgroundColor: AdvisorTheme.highlightBg,
              ),
            );
          }
          return TextSpan(text: part);
        }).toList(),
      ),
    );
  }
}

class _ContactInfoSection extends StatelessWidget {
  const _ContactInfoSection({required this.advisor});

  final Map<String, dynamic> advisor;

  @override
  Widget build(BuildContext context) {
    final collection = _collectContacts(advisor);
    if (collection.items.isEmpty &&
        (collection.additionalInfo == null || collection.additionalInfo!.isEmpty)) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.only(top: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      margin: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contact Information',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final contact in collection.items)
                if (contact.type == 'email')
                  _EmailCopyButton(email: contact.label)
                else if (contact.type == 'google_scholar' ||
                    contact.type == 'github' ||
                    contact.type == 'linkedin')
                  _SocialLinkWithMenu(
                    type: contact.type,
                    url: contact.url,
                    label: contact.label,
                  )
                else
                  _ContactChip(
                    icon: _contactIcon(contact.type),
                    label: contact.label,
                    onTap: () => _openUrl(contact.url, external: contact.type != 'phone'),
                  ),
              if (collection.additionalInfo != null &&
                  collection.additionalInfo!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AdvisorTheme.chipBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    collection.additionalInfo!,
                    style: const TextStyle(fontSize: 12, color: AdvisorTheme.chipText),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContactCollection {
  _ContactCollection(this.items, {this.additionalInfo});

  final List<_ContactItem> items;
  final String? additionalInfo;
}

class _ContactItem {
  const _ContactItem({
    required this.type,
    required this.url,
    required this.label,
  });

  final String type;
  final String url;
  final String label;
}

_ContactCollection _collectContacts(Map<String, dynamic> advisor) {
  final items = <_ContactItem>[];
  final contactInfo = advisor['contact_info'] is Map
      ? Map<String, dynamic>.from(advisor['contact_info'] as Map)
      : null;

  String? email = contactInfo?['email']?.toString();
  if (email == null || email.isEmpty) {
    final rawEmail = advisor['email'];
    if (rawEmail is List && rawEmail.isNotEmpty) {
      email = rawEmail.first.toString();
    } else if (rawEmail is String) {
      email = rawEmail;
    }
  }

  final phone = contactInfo?['phone']?.toString();
  if (email != null && email.isNotEmpty) {
    items.add(_ContactItem(type: 'email', url: 'mailto:$email', label: email));
  }
  if (phone != null && phone.isNotEmpty) {
    items.add(_ContactItem(type: 'phone', url: 'tel:$phone', label: phone));
  }

  final scholarId = advisor['google_scholar_id']?.toString();
  if (scholarId != null && scholarId.isNotEmpty) {
    items.add(
      _ContactItem(
        type: 'google_scholar',
        url: 'https://scholar.google.com/citations?user=$scholarId',
        label: 'Scholar',
      ),
    );
  }

  final homepage = advisor['personal_homepage']?.toString();
  if (homepage != null && homepage.isNotEmpty) {
    items.add(_ContactItem(type: 'homepage', url: homepage, label: 'Homepage'));
  }

  var additionalInfo = contactInfo?['other']?.toString() ?? '';
  if (additionalInfo.isNotEmpty) {
    final phonePatterns = [
      RegExp(r'(?:Phone|Tel|电话|手机)\s*[:：]\s*([+\d\s\-()]+)', caseSensitive: false),
      RegExp(r'(\+\d{1,4}[\s-]?\d{1,4}[\s-]?\d{4,})'),
    ];
    for (final pattern in phonePatterns) {
      for (final match in pattern.allMatches(additionalInfo)) {
        final phoneNumber = (match.group(1) ?? match.group(0))?.trim();
        if (phoneNumber != null &&
            phoneNumber.isNotEmpty &&
            !items.any((c) => c.type == 'phone')) {
          items.add(
            _ContactItem(
              type: 'phone',
              url: 'tel:${phoneNumber.replaceAll(' ', '')}',
              label: phoneNumber,
            ),
          );
          additionalInfo = additionalInfo.replaceFirst(match.group(0)!, '').trim();
        }
      }
    }

    final urlRegex = RegExp(r'(https?://[^\s]+)');
    for (final match in urlRegex.allMatches(additionalInfo)) {
      final url = match.group(0)!;
      if (url.contains('github.com/')) {
        final username = url.split('github.com/').last.split(RegExp(r'[/?#]')).first;
        items.add(_ContactItem(type: 'github', url: url, label: username.isNotEmpty ? username : 'GitHub'));
      } else if (url.contains('linkedin.com/')) {
        items.add(_ContactItem(type: 'linkedin', url: url, label: 'LinkedIn'));
      } else {
        final domain = url.replaceFirst(RegExp(r'^https?://'), '').split('/').first;
        items.add(_ContactItem(type: 'link', url: url, label: domain));
      }
      additionalInfo = additionalInfo.replaceFirst(url, '').trim();
    }
  }

  additionalInfo = additionalInfo.replaceAll(RegExp(r'^[,;:\s]+|[,;:\s]+$'), '').trim();
  if (RegExp(r'\*{2,}').hasMatch(additionalInfo)) {
    additionalInfo = '';
  }

  if (items.isEmpty && additionalInfo.isEmpty) {
    return _ContactCollection(const []);
  }
  return _ContactCollection(items, additionalInfo: additionalInfo.isEmpty ? null : additionalInfo);
}

Widget _contactIcon(String type) {
  switch (type) {
    case 'phone':
      return const Icon(Icons.phone_outlined, size: 14, color: AdvisorTheme.chipText);
    case 'google_scholar':
      return SvgPicture.asset(
        AdvisorTheme.iconGraduation,
        width: 14,
        height: 14,
        colorFilter: const ColorFilter.mode(AdvisorTheme.chipText, BlendMode.srcIn),
      );
    case 'github':
      return SvgPicture.asset(AdvisorTheme.iconGithub, width: 14, height: 14);
    case 'linkedin':
      return SvgPicture.asset(AdvisorTheme.iconLinkedin, width: 14, height: 14);
    default:
      return SvgPicture.asset(
        AdvisorTheme.iconExternalLink,
        width: 14,
        height: 14,
        colorFilter: const ColorFilter.mode(AdvisorTheme.chipText, BlendMode.srcIn),
      );
  }
}

class _ContactChip extends StatelessWidget {
  const _ContactChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final Widget icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AdvisorTheme.chipBg,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        hoverColor: AdvisorTheme.chipBgHover,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AdvisorTheme.chipText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmailCopyButton extends StatefulWidget {
  const _EmailCopyButton({required this.email});

  final String email;

  @override
  State<_EmailCopyButton> createState() => _EmailCopyButtonState();
}

class _EmailCopyButtonState extends State<_EmailCopyButton> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.email));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AdvisorTheme.chipBg,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: _copy,
        borderRadius: BorderRadius.circular(8),
        hoverColor: AdvisorTheme.chipBgHover,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_copied)
                SvgPicture.asset(
                  AdvisorTheme.iconCheck,
                  width: 14,
                  height: 14,
                  colorFilter: const ColorFilter.mode(Colors.green, BlendMode.srcIn),
                )
              else
                SvgPicture.asset(
                  AdvisorTheme.iconMail,
                  width: 14,
                  height: 14,
                  colorFilter: const ColorFilter.mode(AdvisorTheme.chipText, BlendMode.srcIn),
                ),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200),
                child: Text(
                  _copied ? 'Copied' : widget.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AdvisorTheme.chipText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialLinkWithMenu extends StatefulWidget {
  const _SocialLinkWithMenu({
    required this.type,
    required this.url,
    required this.label,
  });

  final String type;
  final String url;
  final String label;

  @override
  State<_SocialLinkWithMenu> createState() => _SocialLinkWithMenuState();
}

class _SocialLinkWithMenuState extends State<_SocialLinkWithMenu> {
  final _linkKey = GlobalKey();
  bool _open = false;

  String? get _userId => _extractUserId(widget.type, widget.url);

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return _ContactChip(
        icon: _contactIcon(widget.type),
        label: widget.label,
        onTap: () => _openUrl(widget.url),
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          key: _linkKey,
          color: _open ? AdvisorTheme.chipBgHover : AdvisorTheme.chipBg,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: () => setState(() => _open = !_open),
            borderRadius: BorderRadius.circular(8),
            hoverColor: AdvisorTheme.chipBgHover,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _contactIcon(widget.type),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 150),
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: _open ? AdvisorTheme.chipTextActive : AdvisorTheme.chipText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_open)
          Positioned(
            left: 0,
            top: 36,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              color: const Color(0xFFF3F4F6),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    _MenuAction(
                      label: 'Analyze',
                      icon: SvgPicture.asset(
                        AdvisorTheme.iconAnalyze,
                        width: 14,
                        height: 14,
                        colorFilter: const ColorFilter.mode(
                          Color(0xFF6B7280),
                          BlendMode.srcIn,
                        ),
                      ),
                      onTap: () {
                        setState(() => _open = false);
                        final analysisType =
                            widget.type == 'google_scholar' ? 'scholar' : widget.type;
                        final targetUrl =
                            '$analysisBaseUrl/$analysisType?user=${Uri.encodeComponent(_userId!)}';
                        _openUrl(targetUrl);
                      },
                    ),
                    Container(width: 1, height: 20, color: const Color(0xFFE5E7EB)),
                    _MenuAction(
                      label: 'Visit',
                      icon: SvgPicture.asset(
                        AdvisorTheme.iconExternalLink,
                        width: 14,
                        height: 14,
                        colorFilter: const ColorFilter.mode(
                          Color(0xFF6B7280),
                          BlendMode.srcIn,
                        ),
                      ),
                      onTap: () {
                        setState(() => _open = false);
                        _openUrl(widget.url);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MenuAction extends StatelessWidget {
  const _MenuAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final Widget icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 96,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF4B5563),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String? _extractUserId(String type, String url) {
  try {
    if (type == 'github') {
      final match = RegExp(r'github\.com/([^/?]+)').firstMatch(url);
      return match?.group(1);
    }
    if (type == 'google_scholar') {
      return Uri.parse(url).queryParameters['user'];
    }
    if (type == 'linkedin') {
      final match = RegExp(r'linkedin\.com/in/([^/?]+)').firstMatch(url);
      return match?.group(1);
    }
  } catch (_) {}
  return null;
}

Future<void> _openUrl(String url, {bool external = true}) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
