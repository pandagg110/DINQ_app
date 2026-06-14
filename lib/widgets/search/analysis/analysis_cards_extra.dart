import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'analysis_card_shared.dart';
import 'analysis_card_shell.dart';
import 'analysis_theme.dart';
import 'analysis_format.dart';
import 'analysis_primitives.dart';

class ScholarInsightCard extends StatelessWidget {
  const ScholarInsightCard({super.key, required this.data, this.isStreaming = false, this.onShare});
  final Map<String, dynamic> data;
  final bool isStreaming;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final totalPapers = data['total_papers'];
    final papersValue = (totalPapers is num && totalPapers >= 500) ? '500+' : (totalPapers ?? '-');
    return AnalysisCardShell(
      iconAsset: 'assets/images/analysis/pie-chart.svg',
      title: 'Insight',
      cardId: 'insight',
      showShareButton: !isStreaming,
      onShare: onShare,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AnalysisInfoBanner(text: 'Only analyze 500 most influential academic papers.'),
          AnalysisSegmentTable(
            items: [
              AnalysisSegmentItem(label: 'Top-tier papers', value: data['top_tier_papers'] ?? '-'),
              AnalysisSegmentItem(label: 'First-author papers', value: data['first_author_papers'] ?? '-'),
              AnalysisSegmentItem(label: 'First-author citations', value: data['first_author_citations'] ?? '-'),
              AnalysisSegmentItem(label: 'Total coauthors', value: data['total_coauthors'] ?? '-'),
              AnalysisSegmentItem(label: 'Last-author papers', value: data['last_author_papers'] ?? '-'),
              AnalysisSegmentItem(label: 'Total papers', value: papersValue),
            ],
          ),
          const SizedBox(height: 12),
          AnalysisDonutChart(
            conferenceDistribution: _mapOf(data['conference_distribution']),
            topTierPapers: data['top_tier_papers'] is num ? data['top_tier_papers'] as num : null,
          ),
        ],
      ),
    );
  }
}

class ScholarCollaboratorCard extends StatelessWidget {
  const ScholarCollaboratorCard({super.key, required this.data, this.isStreaming = false, this.onShare});
  final Map<String, dynamic> data;
  final bool isStreaming;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final hasData = data['full_name'] != null ||
        (data['coauthored_papers'] is num && (data['coauthored_papers'] as num) > 0);
    return AnalysisCardShell(
      iconAsset: 'assets/images/analysis/coorperation.svg',
      title: 'Closest Collaborator',
      cardId: 'collaborator',
      showShareButton: !isStreaming,
      onShare: onShare,
      child: hasData ? _buildContent() : _buildEmpty(),
    );
  }

  Widget _buildContent() {
    final paper = data['best_coauthored_paper'] is Map
        ? Map<String, dynamic>.from(data['best_coauthored_paper'] as Map)
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnalysisAvatar(url: data['avatar']?.toString()),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['full_name']?.toString() ?? '',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Image.asset('assets/images/analysis/verification-logo.png', width: 16, height: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          (data['affiliation']?.toString() ?? '') != 'N/A'
                              ? data['affiliation']?.toString() ?? 'Academic Collaborator'
                              : 'Academic Collaborator',
                          style: const TextStyle(fontSize: 14, color: Color(0xFF7C7C7C)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Number of co-authored papers: ${data['coauthored_papers'] ?? 0}',
                    style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (paper != null && paper['title']?.toString().isNotEmpty == true && paper['title'] != 'N/A')
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: AnalysisLeftAccentPanel(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (paper['venue'] != null || paper['year'] != null)
                    Text(
                      '${paper['venue'] != 'N/A' ? paper['venue'] ?? '' : ''} ${paper['year'] ?? ''}'.trim(),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  if (paper['venue'] != null || paper['year'] != null)
                    Container(height: 1, margin: const EdgeInsets.symmetric(vertical: 12), color: const Color(0xFFF2E8E4)),
                  Text(paper['title']?.toString() ?? '', maxLines: 3, overflow: TextOverflow.ellipsis),
                  if ((paper['citations'] is num) && (paper['citations'] as num) > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          SvgPicture.asset('assets/images/analysis/quot.svg', width: 16, height: 16),
                          const SizedBox(width: 8),
                          Text('Citations : ${AnalysisFormat.formatNumber(paper['citations'])}'),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Column(
      children: [
        const AnalysisAvatar(),
        const SizedBox(height: 16),
        const Text('No Frequent Collaborator Found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        const Text(
          'This researcher appears to work independently or has not published enough collaborative work to identify a closest collaborator.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }
}

class ScholarResearchStyleCard extends StatelessWidget {
  const ScholarResearchStyleCard({super.key, required this.data, this.isStreaming = false, this.onShare});
  final Map<String, dynamic> data;
  final bool isStreaming;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    return AnalysisCardShell(
      iconAsset: 'assets/images/analysis/analytics.svg',
      title: 'Researcher Character',
      cardId: 'research-style',
      showShareButton: !isStreaming,
      onShare: onShare,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _progressRow('Theoretical Research', 'Applied Research', data['theory_vs_practice'], 'react.svg', 'completed-task.svg'),
          const SizedBox(height: 16),
          _progressRow('Academic Depth', 'Academic Breadth', data['depth_vs_breadth'], 'book.svg', 'AcademicBreadth-light.svg'),
          const SizedBox(height: 16),
          _progressRow('Independent Research', 'Team Collaboration', data['individual_vs_team'], 'flag.svg', 'team.svg'),
          if (data['justification'] != null) ...[
            const SizedBox(height: 16),
            AnalysisReasonBox(text: data['justification'].toString(), maxLines: 6),
          ],
        ],
      ),
    );
  }

  Widget _progressRow(String left, String right, dynamic block, String leftIcon, String rightIcon) {
    final score = block is Map ? (block['score'] is num ? (block['score'] as num) * 10 : 0.0) : 0.0;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _label(left, leftIcon),
            _label(right, rightIcon, alignRight: true),
          ],
        ),
        const SizedBox(height: 8),
        AnalysisProgressBar(percentage: score.clamp(0, 100).toDouble()),
      ],
    );
  }

  Widget _label(String text, String icon, {bool alignRight = false}) {
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!alignRight) ...[
          SvgPicture.asset('assets/images/analysis/$icon', width: 14, height: 14),
          const SizedBox(width: 6),
        ],
        Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF374151))),
        if (alignRight) ...[
          const SizedBox(width: 6),
          SvgPicture.asset('assets/images/analysis/$icon', width: 14, height: 14),
        ],
      ],
    );
    return alignRight ? row : row;
  }
}

class ScholarPaperCard extends StatelessWidget {
  const ScholarPaperCard({
    super.key,
    required this.data,
    required this.title,
    required this.cardId,
    this.showSummary = false,
    this.isStreaming = false,
    this.onShare,
  });

  final Map<String, dynamic> data;
  final String title;
  final String cardId;
  final bool showSummary;
  final bool isStreaming;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    return AnalysisCardShell(
      iconAsset: 'assets/images/analysis/contract.svg',
      title: title,
      cardId: cardId,
      showShareButton: !isStreaming,
      onShare: onShare,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnalysisLeftAccentPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${data['venue'] ?? ''}${data['year'] != null ? ' ${data['year']}' : ''}'.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                Container(height: 1, margin: const EdgeInsets.symmetric(vertical: 12), color: const Color(0xFFE5E7EB)),
                Text(
                  data['title']?.toString() ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                if (data['citations'] != null || data['author_position'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (data['citations'] != null) ...[
                          SvgPicture.asset('assets/images/analysis/quot.svg', width: 16, height: 16),
                          const SizedBox(width: 6),
                          Text('Citations : ${AnalysisFormat.formatNumber(data['citations'])}'),
                          const SizedBox(width: 16),
                        ],
                        if (data['author_position'] != null) ...[
                          SvgPicture.asset('assets/images/analysis/author.svg', width: 16, height: 16),
                          const SizedBox(width: 6),
                          Text('Author Position : ${AnalysisFormat.formatAuthorPosition(data['author_position'])}'),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (showSummary && data['summary'] != null) ...[
            const SizedBox(height: 12),
            AnalysisReasonBox(text: data['summary'].toString(), maxLines: 6),
          ],
        ],
      ),
    );
  }
}

class AnalysisRoleModelCard extends StatelessWidget {
  const AnalysisRoleModelCard({
    super.key,
    required this.platform,
    required this.data,
    this.isStreaming = false,
    this.onShare,
  });

  final String platform;
  final Map<String, dynamic> data;
  final bool isStreaming;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    return AnalysisCardShell(
      iconAsset: 'assets/images/analysis/settings.svg',
      title: 'Role Model',
      cardId: 'role-model',
      showShareButton: !isStreaming,
      onShare: onShare,
      child: switch (platform) {
        'github' => _githubBody(),
        'linkedin' => _linkedinBody(),
        _ => _scholarBody(),
      },
    );
  }

  Widget _scholarBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (data['photo_url'] != null) AnalysisAvatar(url: data['photo_url']?.toString()),
            if (data['photo_url'] != null) const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['name']?.toString() ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                  if (data['position'] != null || data['institution'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Image.asset('assets/images/analysis/verification-logo.png', width: 16, height: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${data['position'] ?? ''} (${data['institution'] ?? ''})',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14, color: Color(0xFF7C7C7C)),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        if (data['achievement'] != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFFFDF0EB), borderRadius: BorderRadius.circular(2)),
            child: Row(
              children: [
                SvgPicture.asset('assets/images/analysis/medal.svg', width: 16, height: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(data['achievement'].toString(), maxLines: 2, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
        ],
        if (data['reason'] != null) ...[
          const SizedBox(height: 12),
          AnalysisReasonBox(text: data['reason'].toString(), maxLines: 6),
        ],
      ],
    );
  }

  Widget _githubBody() {
    final score = data['similarity_score'] is num ? ((data['similarity_score'] as num) * 100).toStringAsFixed(1) : '0.0';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            AnalysisAvatar(url: data['github']?.toString()),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['name']?.toString() ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                  Row(
                    children: [
                      Image.asset('assets/images/analysis/verification-logo.png', width: 16, height: 16),
                      const SizedBox(width: 6),
                      Text('Similarity Score: $score%'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AnalysisLeftAccentPanel(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SvgPicture.asset('assets/images/analysis/medal.svg', width: 24, height: 24),
                  const SizedBox(width: 8),
                  const Text('Achievement:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                ],
              ),
              Container(height: 1, margin: const EdgeInsets.symmetric(vertical: 12), color: const Color(0xFFF2E8E4)),
              Text(data['achievement']?.toString() ?? 'GitHub Developer', maxLines: 3, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AnalysisReasonBox(text: data['reason']?.toString() ?? 'No detailed information available', maxLines: 4),
      ],
    );
  }

  Widget _linkedinBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            AnalysisAvatar(url: data['photo_url']?.toString()),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['name']?.toString() ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                  if (data['position'] != null)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.asset('assets/images/analysis/verification-logo.png', width: 16, height: 16),
                        const SizedBox(width: 6),
                        Expanded(child: Text(data['position'].toString(), maxLines: 2, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AnalysisLeftAccentPanel(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SvgPicture.asset('assets/images/analysis/medal.svg', width: 16, height: 16),
                  const SizedBox(width: 8),
                  const Text('Achievement:', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF2C2C2C))),
                ],
              ),
              Container(height: 1, margin: const EdgeInsets.symmetric(vertical: 12), color: const Color(0xFFF2E8E4)),
              Text(data['achievement']?.toString() ?? 'No achievement info'),
            ],
          ),
        ),
        if (data['similarity_reason'] != null) ...[
          const SizedBox(height: 12),
          AnalysisReasonBox(text: data['similarity_reason'].toString(), maxLines: 8),
        ],
      ],
    );
  }
}

class GithubActivityHeatmapCard extends StatelessWidget {
  const GithubActivityHeatmapCard({super.key, required this.data, this.isStreaming = false, this.onShare});
  final dynamic data;
  final bool isStreaming;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final map = <String, int>{};
    if (data is List) {
      for (final item in data) {
        if (item is Map) {
          final date = item['date']?.toString();
          final count = item['contributions'];
          if (date != null && count is num) map[date] = count.toInt();
        }
      }
    }
    return AnalysisCardShell(
      iconAsset: 'assets/images/analysis/yearly.svg',
      title: 'Recent Activity (Last 12 Months)',
      cardId: 'activity-heatmap',
      showShareButton: !isStreaming,
      onShare: onShare,
      child: SizedBox(height: 337, child: AnalysisContributionHeatmap(contributionData: map)),
    );
  }
}

class GithubFeatureProjectCard extends StatelessWidget {
  const GithubFeatureProjectCard({super.key, required this.data, this.isStreaming = false, this.onShare});
  final Map<String, dynamic> data;
  final bool isStreaming;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    return AnalysisCardShell(
      iconAsset: 'assets/images/analysis/project.svg',
      title: 'Featured Project',
      cardId: 'feature-project',
      showShareButton: !isStreaming,
      onShare: onShare,
      child: Column(
        children: [
          AnalysisLeftAccentPanel(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['name']?.toString() ?? '', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                Container(height: 1, margin: const EdgeInsets.symmetric(vertical: 12), color: const Color(0xFFF2E8E4)),
                Text(data['description']?.toString() ?? '', maxLines: 6, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: AnalysisMetricBadge(value: '${data['stargazerCount'] ?? 0}', label: 'Stars', iconAsset: 'assets/images/analysis/stars.svg')),
              const SizedBox(width: 8),
              Expanded(child: AnalysisMetricBadge(value: '${data['forkCount'] ?? 0}', label: 'Forks', iconAsset: 'assets/images/analysis/forks.svg')),
              const SizedBox(width: 8),
              Expanded(child: AnalysisMetricBadge(value: '${data['monthly_trending'] ?? 'No'}', label: 'Monthly Trending', iconAsset: 'assets/images/analysis/trending.svg')),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: AnalysisMetricBadge(value: '${data['contributors'] ?? 0}', label: 'Contributors', iconAsset: 'assets/images/analysis/man.svg')),
              const SizedBox(width: 8),
              Expanded(child: AnalysisMetricBadge(value: '${data['used_by'] ?? 0}', label: 'Used by', iconAsset: 'assets/images/analysis/working.svg')),
            ],
          ),
        ],
      ),
    );
  }
}

class GithubLanguagesCard extends StatelessWidget {
  const GithubLanguagesCard({super.key, required this.data, this.isStreaming = false, this.onShare});
  final Map<String, dynamic> data;
  final bool isStreaming;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final langs = data['languages'] is Map ? Map<String, dynamic>.from(data['languages'] as Map) : <String, dynamic>{};
    return AnalysisCardShell(
      iconAsset: 'assets/images/analysis/closet.svg',
      title: 'Programming Languages',
      cardId: 'languages',
      showShareButton: !isStreaming,
      onShare: onShare,
      child: SizedBox(
        height: 360,
        child: AnalysisLanguageDonutChart(
          languages: langs,
          total: data['total'] is num ? data['total'] as num : 0,
        ),
      ),
    );
  }
}

class GithubTopProjectsCard extends StatelessWidget {
  const GithubTopProjectsCard({super.key, required this.data, this.isStreaming = false, this.onShare});
  final Map<String, dynamic> data;
  final bool isStreaming;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final projects = data['projects'] is List ? data['projects'] as List : const [];
    return AnalysisCardShell(
      iconAsset: 'assets/images/analysis/contributed.svg',
      title: 'Top Projects Contributed To',
      cardId: 'top-projects',
      showShareButton: !isStreaming,
      onShare: onShare,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final pad = constraints.maxWidth >= 768 ? 16.0 : 8.0;
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < projects.length.clamp(0, 3); i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(child: _projectTile(projects[i], pad)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _projectTile(dynamic raw, double padding) {
    final item = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    final repo = item['repository'] is Map ? Map<String, dynamic>.from(item['repository'] as Map) : {};
    final avatar = repo['owner']?['avatarUrl']?.toString();
    return Container(
      constraints: const BoxConstraints(minHeight: 360),
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: AnalysisTheme.panelBg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(bottom: 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF2E8E4))),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                  child: avatar == null
                      ? Image.asset(AnalysisTheme.defaultAvatar, width: 50, height: 50, fit: BoxFit.cover)
                      : null,
                ),
                const SizedBox(height: 4),
                Text(
                  repo['name']?.toString() ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBEAE3),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AnalysisTheme.primary),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: AnalysisTheme.primary, shape: BoxShape.circle),
                        child: SvgPicture.asset('assets/images/analysis/favorites.svg', width: 16, height: 16),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${repo['stargazerCount'] ?? 0} Stars',
                        style: const TextStyle(fontSize: 14, color: AnalysisTheme.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Text(
              repo['description']?.toString() ?? 'No description available',
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1E1F25)),
            ),
          ),
          Text.rich(
            TextSpan(
              style: const TextStyle(color: AnalysisTheme.primary),
              children: [
                TextSpan(
                  text: '${item['pull_requests'] ?? 0}',
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700),
                ),
                const TextSpan(text: ' PRs', style: TextStyle(fontSize: 18)),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class GithubMostValuablePRCard extends StatelessWidget {
  const GithubMostValuablePRCard({super.key, required this.data, this.isStreaming = false, this.onShare});
  final Map<String, dynamic> data;
  final bool isStreaming;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    return AnalysisCardShell(
      iconAsset: 'assets/images/analysis/pull.svg',
      title: 'Most Valuable Pull Request',
      cardId: 'most-valuable-pr',
      showShareButton: !isStreaming,
      onShare: onShare,
      child: Column(
        children: [
          AnalysisLeftAccentPanel(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['title']?.toString() ?? '', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                if (data['reason'] != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(data['reason'].toString(), maxLines: 2, overflow: TextOverflow.ellipsis)),
                Padding(padding: const EdgeInsets.only(top: 12), child: Text('Repository: ${data['repository'] ?? ''}', style: const TextStyle(fontSize: 14, color: Color(0xFF7C7C7C)))),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFFAF2EF), borderRadius: BorderRadius.circular(4)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SvgPicture.asset('assets/images/analysis/impact.svg', width: 24, height: 24),
                    const SizedBox(width: 8),
                    const Text('Impact', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 12),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 16, color: Color(0xFF4D4846)),
                    children: [
                      TextSpan(text: '+${AnalysisFormat.formatNumber(data['additions'])}', style: const TextStyle(color: Color(0xFFCB7C5D), fontWeight: FontWeight.w700)),
                      const TextSpan(text: ' additions, ', style: TextStyle(color: Color(0xFFC9A998))),
                      TextSpan(text: '-${AnalysisFormat.formatNumber(data['deletions'])}', style: const TextStyle(color: Color(0xFFCB7C5D), fontWeight: FontWeight.w700)),
                      const TextSpan(text: ' deletions', style: TextStyle(color: Color(0xFFC9A998))),
                    ],
                  ),
                ),
                if (data['impact'] != null) ...[
                  Container(height: 1, margin: const EdgeInsets.symmetric(vertical: 12), color: const Color(0xFFE8DCD7)),
                  Text(data['impact'].toString(), maxLines: 4, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LinkedinSkillsCard extends StatelessWidget {
  const LinkedinSkillsCard({super.key, required this.data, this.isStreaming = false, this.onShare});
  final Map<String, dynamic> data;
  final bool isStreaming;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    return AnalysisCardShell(
      iconAsset: 'assets/images/analysis/pencil.svg',
      title: 'Skills',
      cardId: 'Skills',
      showShareButton: !isStreaming,
      onShare: onShare,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(color: const Color(0xFFFFFCF7), borderRadius: BorderRadius.circular(4)),
            child: Row(
              children: [
                SvgPicture.asset('assets/images/analysis/info.svg', width: 16, height: 16),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Display top skills filtered by AI based on value and recognition',
                    style: TextStyle(fontSize: 12, color: Color(0xFF666666)),
                  ),
                ),
              ],
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 640;
              final tiles = [
                _skillTile('Industry Knowledge', data['industry_knowledge'], const Color(0xFFEBEDF2), const Color(0xFFD0D5E3), 'idea1.svg'),
                _skillTile('Tools & Technologies', data['tools_technologies'], const Color(0xFFF1EFEB), const Color(0xFFDFDEDA), 'blockchain.svg'),
                _skillTile('Interpersonal Skills', data['interpersonal_skills'], const Color(0xFFF6F1E7), const Color(0xFFE5DBC4), 'interpersonal-skills.svg'),
                _skillTile('Language', data['language'], const Color(0xFFF6E6DF), const Color(0xFFF1D5CB), 'global.svg'),
              ];
              if (!isWide) {
                return Column(
                  children: [
                    for (var i = 0; i < tiles.length; i++) ...[
                      if (i > 0) const SizedBox(height: 8),
                      tiles[i],
                    ],
                  ],
                );
              }
              return Column(
                children: [
                  Row(children: [Expanded(child: tiles[0]), const SizedBox(width: 8), Expanded(child: tiles[1])]),
                  const SizedBox(height: 8),
                  Row(children: [Expanded(child: tiles[2]), const SizedBox(width: 8), Expanded(child: tiles[3])]),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _skillTile(String title, dynamic items, Color bg, Color iconBg, String icon) {
    final list = items is List ? items.cast<dynamic>() : const [];
    return Container(
      height: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        image: const DecorationImage(
          image: AssetImage('assets/images/analysis/circle-quarter.png'),
          alignment: Alignment.bottomRight,
          fit: BoxFit.none,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(2)),
                padding: const EdgeInsets.all(4),
                child: SvgPicture.asset('assets/images/analysis/$icon'),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 14))),
            ],
          ),
          const SizedBox(height: 8),
          for (final item in list.take(4))
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Container(width: 4, height: 4, decoration: const BoxDecoration(color: Color(0xFF5A5554), shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item.toString(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Color(0xFF5A5554)))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class LinkedinCareerCard extends StatelessWidget {
  const LinkedinCareerCard({super.key, required this.data, this.isStreaming = false, this.onShare});
  final Map<String, dynamic> data;
  final bool isStreaming;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final advice = data['development_advice'] is Map
        ? Map<String, dynamic>.from(data['development_advice'] as Map)
        : const {};
    return AnalysisCardShell(
      iconAsset: 'assets/images/analysis/goal.svg',
      title: 'Career',
      cardId: 'Career',
      showShareButton: !isStreaming,
      onShare: onShare,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnalysisLeftAccentPanel(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SvgPicture.asset('assets/images/analysis/promotion.svg', width: 16, height: 16),
                    const SizedBox(width: 8),
                    const Text('Future Development Potential', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF2C2C2C))),
                  ],
                ),
                Container(height: 1, margin: const EdgeInsets.symmetric(vertical: 12), color: const Color(0xFFF2E8E4)),
                Text(data['future_development_potential']?.toString() ?? 'Not available.', maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SvgPicture.asset('assets/images/analysis/chat-bubble.svg', width: 16, height: 16),
              const SizedBox(width: 8),
              const Text('Development Advice', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF2C2C2C))),
            ],
          ),
          const AnalysisSectionDivider(),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 640;
              final past = _adviceBox('Past Evaluation', advice['past_evaluation']?.toString() ?? 'Not available.', 'clipboard.svg');
              final future = _adviceBox('Future Advice', advice['future_advice']?.toString() ?? 'Not available.', 'advice.svg');
              if (!isWide) return Column(children: [past, const SizedBox(height: 12), future]);
              return Row(children: [Expanded(child: past), const SizedBox(width: 12), Expanded(child: future)]);
            },
          ),
        ],
      ),
    );
  }

  Widget _adviceBox(String title, String text, String icon) {
    return Container(
      height: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFFAF2EF), borderRadius: BorderRadius.circular(4)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(color: const Color(0xFFF4D9CE), borderRadius: BorderRadius.circular(2)),
                padding: const EdgeInsets.all(4),
                child: SvgPicture.asset('assets/images/analysis/$icon'),
              ),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(child: Text(text, maxLines: 4, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF464646)))),
        ],
      ),
    );
  }
}

class LinkedinLifeWellBeingCard extends StatelessWidget {
  const LinkedinLifeWellBeingCard({super.key, required this.data, this.isStreaming = false, this.onShare});
  final Map<String, dynamic> data;
  final bool isStreaming;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final life = data['life_suggestion'] is Map ? Map<String, dynamic>.from(data['life_suggestion'] as Map) : {};
    final health = data['health'] is Map ? Map<String, dynamic>.from(data['health'] as Map) : {};
    return AnalysisCardShell(
      iconAsset: 'assets/images/analysis/healthcare.svg',
      title: 'Life & Well-being',
      cardId: 'Life-Well-being',
      showShareButton: !isStreaming,
      onShare: onShare,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _section('Life suggestion', life['advice']?.toString() ?? 'Not available.', life['actions']),
          const SizedBox(height: 16),
          _section('Health', health['advice']?.toString() ?? 'Not available.', health['actions']),
        ],
      ),
    );
  }

  Widget _section(String title, String advice, dynamic actions) {
    final list = actions is List ? actions : const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF2C2C2C))),
        const AnalysisSectionDivider(),
        Text(advice, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF464646))),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < list.length && i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 14),
              Expanded(
                child: Container(
                  height: 70,
                  decoration: BoxDecoration(color: const Color(0xFFF6F2F1), borderRadius: BorderRadius.circular(4)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(list[i] is Map ? (list[i]['emoji']?.toString() ?? '') : ''),
                      Text(
                        list[i] is Map ? (list[i]['phrase']?.toString() ?? '') : '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, color: Color(0xFF3C3C3C)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class LinkedinColleaguesCard extends StatelessWidget {
  const LinkedinColleaguesCard({super.key, required this.data, this.isStreaming = false, this.onShare});
  final Map<String, dynamic> data;
  final bool isStreaming;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final highlights = data['highlights'] is List ? data['highlights'] as List : const [];
    final improvements = data['areas_for_improvement'] is List ? data['areas_for_improvement'] as List : const [];
    return AnalysisCardShell(
      iconAsset: 'assets/images/analysis/colleagues.svg',
      title: "Colleagues' View of You",
      cardId: 'Colleagues-View',
      showShareButton: !isStreaming,
      onShare: onShare,
      child: Column(
        children: [
          _panel('Highlights', highlights, const Color(0xFFFFFBF2), const Color(0xFFFFF3CF), 'idea2.svg', const Color(0xFFDECA8F)),
          const SizedBox(height: 12),
          _panel('Areas for Improvement', improvements, const Color(0xFFFAF2EF), const Color(0xFFF4D9CE), 'growth3.svg', const Color(0xFFC88D75)),
        ],
      ),
    );
  }

  Widget _panel(String title, List items, Color bg, Color iconBg, String icon, Color accent) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(6)),
                child: SvgPicture.asset('assets/images/analysis/$icon'),
              ),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF2C2C2C))),
            ],
          ),
          AnalysisSectionDivider(accentWidth: 100),
          Text(
            items.isEmpty ? 'No data available.' : items.map((e) => e.toString()).join('\n'),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, color: Color(0xFF464646)),
          ),
        ],
      ),
    );
  }
}

Map<String, dynamic> _mapOf(dynamic value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  return {};
}

/// 与 TSX `EducationCard.tsx` 对齐。
class LinkedinEducationCard extends StatelessWidget {
  const LinkedinEducationCard({
    super.key,
    required this.items,
    this.summary,
    this.isStreaming = false,
    this.onShare,
  });

  final List<dynamic> items;
  final String? summary;
  final bool isStreaming;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    return AnalysisCardShell(
      iconAsset: 'assets/images/analysis/graduation.svg',
      title: 'Education',
      cardId: 'Education',
      showShareButton: !isStreaming,
      onShare: onShare,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: items.length > 3 ? 230 : double.infinity),
            child: SingleChildScrollView(
              physics: items.length > 3 ? const BouncingScrollPhysics() : const NeverScrollableScrollPhysics(),
              child: Column(
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    if (i > 0) const SizedBox(height: 8),
                    _EducationRow(
                      school: _readSchool(items[i]),
                      major: _readMajor(items[i]),
                      time: _readEducationTime(items[i]),
                      isFirst: i == 0,
                      isLast: i == items.length - 1,
                      logoUrl: _readLogo(items[i]),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 118,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AnalysisTheme.panelBgMuted,
              borderRadius: BorderRadius.circular(AnalysisTheme.radiusMd),
            ),
            child: Text(
              summary ?? 'Education summary not available.',
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, height: 1.5, color: AnalysisTheme.textBody),
            ),
          ),
        ],
      ),
    );
  }
}

class _EducationRow extends StatelessWidget {
  const _EducationRow({
    required this.school,
    required this.major,
    required this.time,
    required this.isFirst,
    required this.isLast,
    this.logoUrl,
  });

  final String school;
  final String major;
  final String time;
  final bool isFirst;
  final bool isLast;
  final String? logoUrl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TimelineDot(isFirst: isFirst, isLast: isLast),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.only(left: 8, right: 16),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: isFirst ? const Color(0xFFC88D75) : const Color(0xFFDCDCDC),
                                width: 2,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              AnalysisCompanyLogo(url: logoUrl, radius: 21),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(school, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (time.isNotEmpty)
                        Text(time, style: const TextStyle(fontSize: 12, color: Color(0xFF6F6F6F))),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    major,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, height: 2, color: Color(0xFF3C3C3C)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineDot extends StatelessWidget {
  const _TimelineDot({required this.isFirst, required this.isLast});
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 8,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: isFirst ? 12 : 16,
            left: 0,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isFirst ? Colors.white : const Color(0xFFCCCCCC),
                border: isFirst ? Border.all(color: AnalysisTheme.primary, width: 1.5) : null,
              ),
            ),
          ),
          if (!isLast)
            Positioned(
              top: isFirst ? 20 : 24,
              left: 3,
              bottom: 0,
              child: CustomPaint(size: const Size(1, 56), painter: _DashedLinePainter()),
            ),
        ],
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const dashHeight = 4.0;
    const gap = 4.0;
    final paint = Paint()..color = const Color(0xFFCCCCCC)..strokeWidth = 1;
    var y = 0.0;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(0, y + dashHeight), paint);
      y += dashHeight + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

String _readSchool(dynamic item) {
  if (item is! Map) return '';
  return (item['title'] ?? item['school'])?.toString() ?? '';
}

String _readMajor(dynamic item) {
  if (item is! Map) return '';
  return (item['subtitle'] ?? item['major'])?.toString() ?? '';
}

String _readEducationTime(dynamic item) {
  if (item is! Map) return '';
  final period = item['period'];
  if (period is Map) {
    final start = period['startedOn']?['year'];
    final end = period['endedOn']?['year'];
    if (start != null && end != null) return '$start-$end';
    if (start != null) return '$start';
    if (end != null) return '$end';
  }
  return item['time']?.toString().replaceAll('-', '.') ?? '';
}

String _readLogo(dynamic item) {
  if (item is! Map) return '';
  return item['logo']?.toString() ?? '';
}

/// 与 TSX `RoastCard.tsx` 对齐。
class AnalysisRoastCard extends StatelessWidget {
  const AnalysisRoastCard({
    super.key,
    required this.data,
    this.iconAsset,
    this.isStreaming = false,
    this.onShare,
  });

  final String data;
  final String? iconAsset;
  final bool isStreaming;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    return AnalysisCardShell(
      iconAsset: iconAsset ?? 'assets/images/analysis/chat-bubble.svg',
      title: 'Roast',
      cardId: 'roast',
      showShareButton: !isStreaming,
      onShare: onShare,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AnalysisTheme.panelBg,
          borderRadius: BorderRadius.circular(AnalysisTheme.radiusSm),
        ),
        child: Text(
          data.isEmpty ? 'No roast available' : data,
          style: const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF111827)),
        ),
      ),
    );
  }
}
