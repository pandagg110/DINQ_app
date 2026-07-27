import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../common/asset_icon.dart';
import '../../../common/metric_display.dart';
import 'profile_signals_adapters.dart';
import 'profile_signals_analysis_button.dart';

class GitHubProfileSignalCard extends StatelessWidget {
  const GitHubProfileSignalCard({
    super.key,
    required this.metadata,
    this.url,
  });

  final Map<String, dynamic> metadata;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final cardUrl = url ?? metadata['url']?.toString() ?? '';
    final username = metadata['username']?.toString() ?? '';
    final starCount = (metadata['starCount'] as num?)?.toInt() ?? 0;
    final summary = metadata['summary']?.toString() ?? '';
    final representativeProject = metadata['representativeProject'];
    final displayMode = metadata['displayMode']?.toString() ?? 'project';
    final showActivity = displayMode == 'activity';

    final hasRepresentative =
        representativeProject != null &&
        (representativeProject['name'] as String?)?.isNotEmpty == true;
    final repoName = extractGitHubRepoNameFromUrl(cardUrl);
    final isRepoCard = !hasRepresentative && repoName != null;
    final summaryText = summary.trim().isNotEmpty
        ? summary
        : 'No summary available.';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AssetIcon(asset: 'icons/logo/Github.png', size: 40),
              if (!isRepoCard)
                _buildStarsOrUsername(
                  username: username,
                  starCount: starCount,
                  align: MetricAlign.end,
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (isRepoCard)
            _RepresentativeProjectCard(
              name: repoName,
              projectUrl: cardUrl,
              stars: starCount,
            )
          else if (hasRepresentative && !showActivity)
            _RepresentativeProjectCard(
              name: (representativeProject['name'] as String?) ?? '',
              projectUrl: representativeProject['url']?.toString(),
              stars: (representativeProject['stars'] as num?)?.toInt() ?? 0,
            )
          else if (username.isNotEmpty)
            SizedBox(
              height: 101,
              width: double.infinity,
              child: SvgPicture.network(
                'https://ghchart.rshah.org/$username',
                fit: BoxFit.cover,
                placeholderBuilder: (context) => Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                semanticsLabel: 'GitHub Contribution Chart',
                clipBehavior: Clip.antiAlias,
              ),
            ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F6F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              summaryText,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
          ),
          if (cardUrl.isNotEmpty) ...[
            const SizedBox(height: 16),
            ProfileSignalAnalysisButton(
              platform: 'github',
              url: cardUrl,
              fallbackId: username.isNotEmpty ? username : null,
            ),
          ],
        ],
      ),
    );
  }

  static Widget _buildStarsOrUsername({
    required String username,
    required int starCount,
    MetricAlign align = MetricAlign.start,
  }) {
    if (starCount > 0) {
      return MetricDisplay(
        label: 'Stars',
        value: starCount,
        align: align,
      );
    }

    return Text(
      username.isNotEmpty ? '@$username' : '',
      textAlign: align == MetricAlign.end ? TextAlign.right : TextAlign.left,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Color(0xFF171717),
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _RepresentativeProjectCard extends StatelessWidget {
  const _RepresentativeProjectCard({
    required this.name,
    this.projectUrl,
    required this.stars,
  });

  final String name;
  final String? projectUrl;
  final int stars;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCCE5FF)),
        color: Colors.white,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const BoxDecoration(
              color: Color(0xFFCCE5FF),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.code, size: 16, color: Color(0xFF374151)),
                const SizedBox(width: 6),
                Expanded(
                  child: projectUrl != null && projectUrl!.isNotEmpty
                      ? GestureDetector(
                          onTap: () async {
                            final uri = Uri.tryParse(projectUrl!);
                            if (uri != null && await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          },
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111827),
                              decoration: TextDecoration.underline,
                              decorationColor: Color(0xFF111827),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      : Text(
                          name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: MetricDisplay(
              label: 'Stars',
              value: stars,
              align: MetricAlign.start,
            ),
          ),
        ],
      ),
    );
  }
}
