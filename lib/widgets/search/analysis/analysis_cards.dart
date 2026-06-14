import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'analysis_card_shared.dart';
import 'analysis_card_shell.dart';
import 'analysis_cards_extra.dart';
import 'analysis_config.dart';
import 'analysis_format.dart';
import 'analysis_primitives.dart';
import 'analysis_theme.dart';

/// 根据 TSX component 名渲染对应卡片。
class AnalysisCardBuilder {
  AnalysisCardBuilder._();

  static Widget build({
    required String component,
    required String cardKey,
    required AnalysisCardProps props,
    required String platform,
    bool isStreaming = false,
    VoidCallback? onShare,
  }) {
    return switch (component) {
      'PapersCard' => ScholarPapersCard(
          data: props.data,
          isStreaming: isStreaming,
          onShare: onShare,
        ),
      'EarningsCard' => ScholarEarningsCard(
          data: props.data,
          isStreaming: isStreaming,
          onShare: onShare,
        ),
      'InsightCard' => ScholarInsightCard(
          data: props.data,
          isStreaming: isStreaming,
          onShare: onShare,
        ),
      'CollaboratorCard' => ScholarCollaboratorCard(
          data: props.data,
          isStreaming: isStreaming,
          onShare: onShare,
        ),
      'ResearchStyleCard' => ScholarResearchStyleCard(
          data: props.data,
          isStreaming: isStreaming,
          onShare: onShare,
        ),
      'RepresentativePaperCard' => ScholarPaperCard(
          data: props.data,
          title: 'Representative Paper',
          cardId: 'representative-paper',
          isStreaming: isStreaming,
          onShare: onShare,
        ),
      'PaperOfYearCard' => ScholarPaperCard(
          data: props.data,
          title: 'Paper of Year (${props.data['year'] ?? ''})',
          cardId: 'paper-of-year',
          showSummary: true,
          isStreaming: isStreaming,
          onShare: onShare,
        ),
      'RoleModelCard' => AnalysisRoleModelCard(
          platform: platform,
          data: props.data,
          isStreaming: isStreaming,
          onShare: onShare,
        ),
      'OverviewCard' => GithubOverviewCard(
          data: props.data,
          isStreaming: isStreaming,
          onShare: onShare,
        ),
      'ActivityHeatmapCard' => GithubActivityHeatmapCard(
          data: props.data['activity'] ?? props.data,
          isStreaming: isStreaming,
          onShare: onShare,
        ),
      'FeatureProjectCard' => GithubFeatureProjectCard(
          data: props.data,
          isStreaming: isStreaming,
          onShare: onShare,
        ),
      'LanguagesCard' => GithubLanguagesCard(
          data: props.data,
          isStreaming: isStreaming,
          onShare: onShare,
        ),
      'TopProjectsCard' => GithubTopProjectsCard(
          data: props.data,
          isStreaming: isStreaming,
          onShare: onShare,
        ),
      'MostValuablePRCard' => GithubMostValuablePRCard(
          data: props.data,
          isStreaming: isStreaming,
          onShare: onShare,
        ),
      'ValuationCard' => GithubValuationCard(
          data: props.data,
          isStreaming: isStreaming,
          onShare: onShare,
        ),
      'WorkExperienceCard' => LinkedinWorkExperienceCard(
          items: (props.data['items'] as List?) ?? const [],
          summary: props.summary,
          isStreaming: isStreaming,
          onShare: onShare,
        ),
      'SalaryCard' => LinkedinSalaryCard(
          data: props.data,
          isStreaming: isStreaming,
          onShare: onShare,
        ),
      'SkillsCard' => LinkedinSkillsCard(
          data: props.data,
          isStreaming: isStreaming,
          onShare: onShare,
        ),
      'CareerCard' => LinkedinCareerCard(
          data: props.data,
          isStreaming: isStreaming,
          onShare: onShare,
        ),
      'LifeWellBeingCard' => LinkedinLifeWellBeingCard(
          data: props.data,
          isStreaming: isStreaming,
          onShare: onShare,
        ),
      'ColleaguesCard' => LinkedinColleaguesCard(
          data: props.data,
          isStreaming: isStreaming,
          onShare: onShare,
        ),
      'EducationCard' => LinkedinEducationCard(
          items: (props.data['items'] as List?) ?? const [],
          summary: props.summary,
          isStreaming: isStreaming,
          onShare: onShare,
        ),
      'RoastCard' => AnalysisRoastCard(
          data: props.data['text']?.toString() ?? props.data['roast']?.toString() ?? '',
          iconAsset: props.data['icon']?.toString(),
          isStreaming: isStreaming,
          onShare: onShare,
        ),
      _ => AnalysisFallbackCard(
          cardKey: cardKey,
          component: component,
          data: props.data,
          isStreaming: isStreaming,
          onShare: onShare,
        ),
    };
  }
}

/// Shuffle 抽到尚未完整迁移的卡片时，用 CardShell 展示基础字段。
class AnalysisFallbackCard extends StatelessWidget {
  const AnalysisFallbackCard({
    super.key,
    required this.cardKey,
    required this.component,
    required this.data,
    this.isStreaming = false,
    this.onShare,
  });

  final String cardKey;
  final String component;
  final Map<String, dynamic> data;
  final bool isStreaming;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final title =
        AnalysisPlatformConfig.cardLabels[cardKey] ?? component.replaceAll('Card', '');
    final items = _flattenPreviewFields(data);
    return AnalysisCardShell(
      iconAsset: 'assets/images/analysis/document.svg',
      title: title,
      cardId: cardKey,
      showShareButton: !isStreaming,
      onShare: onShare,
      child: items.isEmpty
          ? const Text(
              'Loading card data…',
              style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
            )
          : AnalysisSegmentTable(items: items),
    );
  }

  List<AnalysisSegmentItem> _flattenPreviewFields(Map<String, dynamic> source) {
    final items = <AnalysisSegmentItem>[];
    for (final entry in source.entries) {
      final value = entry.value;
      if (value == null) continue;
      if (value is Map || value is List) continue;
      final label = _humanizeKey(entry.key);
      items.add(AnalysisSegmentItem(label: label, value: value));
      if (items.length >= 6) break;
    }
    return items;
  }

  String _humanizeKey(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((part) => part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}

class ScholarPapersCard extends StatelessWidget {
  const ScholarPapersCard({
    super.key,
    required this.data,
    this.isStreaming = false,
    this.onShare,
  });

  final Map<String, dynamic> data;
  final bool isStreaming;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final totalPapers = data['total_papers'];
    final papersValue = (totalPapers is num && totalPapers >= 500)
        ? '500+'
        : (totalPapers ?? '-');

    return AnalysisCardShell(
      iconAsset: 'assets/images/analysis/document.svg',
      title: 'Papers',
      cardId: 'papers',
      showShareButton: !isStreaming,
      onShare: onShare,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnalysisSegmentTable(
            items: [
              AnalysisSegmentItem(label: 'Papers', value: papersValue),
              AnalysisSegmentItem(label: 'Citations', value: data['total_citations']),
              AnalysisSegmentItem(label: 'H-index', value: data['h_index']),
            ],
          ),
          const SizedBox(height: 8),
          AnalysisPapersBarLineChart(
            yearlyPapers: _mapOf(data['yearly_stats']),
            yearlyCitations: _mapOf(data['yearly_citations']),
          ),
        ],
      ),
    );
  }
}

class ScholarEarningsCard extends StatelessWidget {
  const ScholarEarningsCard({
    super.key,
    required this.data,
    this.isStreaming = false,
    this.onShare,
  });

  final Map<String, dynamic> data;
  final bool isStreaming;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    return AnalysisCardShell(
      iconAsset: 'assets/images/analysis/wallet.svg',
      title: 'Estimated Salary',
      cardId: 'earnings',
      showShareButton: !isStreaming,
      onShare: onShare,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AnalysisFormat.formatSalary(data['earnings']),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 8, bottom: 16),
            child: Text(
              'Earnings Per Year',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF111827)),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AnalysisTheme.panelBg,
              borderRadius: BorderRadius.circular(AnalysisTheme.radiusSm),
            ),
            child: Text(
              data['reason']?.toString() ?? '',
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
            ),
          ),
        ],
      ),
    );
  }
}

class GithubOverviewCard extends StatelessWidget {
  const GithubOverviewCard({
    super.key,
    required this.data,
    this.isStreaming = false,
    this.onShare,
  });

  final Map<String, dynamic> data;
  final bool isStreaming;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    return AnalysisCardShell(
      iconAsset: 'assets/images/analysis/research.svg',
      title: 'Overview',
      cardId: 'overview',
      showShareButton: !isStreaming,
      onShare: onShare,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnalysisSegmentTable(
            items: [
              AnalysisSegmentItem(label: 'Work Experience', value: data['work_experience'] ?? 0),
              AnalysisSegmentItem(label: 'Stars', value: data['stars'] ?? 0),
              AnalysisSegmentItem(label: 'Issues', value: data['issues'] ?? 0),
              AnalysisSegmentItem(label: 'Pull Requests', value: data['pull_requests'] ?? 0),
              AnalysisSegmentItem(label: 'Repositories', value: data['repositories'] ?? 0),
              AnalysisSegmentItem(label: 'Active Days', value: data['active_days'] ?? 0),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Total Code Contribution',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final labelSize = constraints.maxWidth >= 640 ? 16.0 : 14.0;
              final valueSize = constraints.maxWidth >= 640 ? 30.0 : 20.0;
              return Row(
                children: [
                  Expanded(
                    child: _ContributionTile(
                      label: 'Additions',
                      value: '+ ${AnalysisFormat.formatNumber(data['additions'] ?? 0)}',
                      labelColor: const Color(0xFF5F6D94),
                      valueColor: const Color(0xFF5F6D94),
                      iconAsset: 'assets/images/analysis/additions.svg',
                      backgroundImage: 'assets/images/analysis/Group2x1.png',
                      labelSize: labelSize,
                      valueSize: valueSize,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ContributionTile(
                      label: 'Deletions',
                      value: '- ${AnalysisFormat.formatNumber(data['deletions'] ?? 0)}',
                      labelColor: const Color(0xFFCB7C5D),
                      valueColor: const Color(0xFFCB7C5D),
                      iconAsset: 'assets/images/analysis/trash-bin.svg',
                      backgroundImage: 'assets/images/analysis/Group2x.png',
                      labelSize: labelSize,
                      valueSize: valueSize,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class GithubValuationCard extends StatelessWidget {
  const GithubValuationCard({
    super.key,
    required this.data,
    this.isStreaming = false,
    this.onShare,
  });

  final Map<String, dynamic> data;
  final bool isStreaming;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final salary = AnalysisFormat.formatSalary(data['salary']).replaceFirst(r'$', '');

    return AnalysisCardShell(
      iconAsset: 'assets/images/analysis/level-up.svg',
      title: 'Valuation & Level',
      cardId: 'valuation',
      showShareButton: !isStreaming,
      onShare: onShare,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final valueSize = constraints.maxWidth >= 640 ? 24.0 : 18.0;
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _ValuationMetricTile(
                      title: 'Market Value(\$)',
                      subtitle: 'Earnings Per Year',
                      value: salary,
                      valueColor: const Color(0xFF6075AD),
                      background: const Color(0xFFEBEDF2),
                      iconAsset: 'assets/images/analysis/growth.svg',
                      iconBg: const Color(0xFFD0D5E3),
                      valueSize: valueSize,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _ValuationMetricTile(
                      title: 'Technical Level',
                      subtitle: 'Software Engineer',
                      value: data['level']?.toString() ?? '-',
                      valueColor: const Color(0xFF6A675D),
                      background: const Color(0xFFF1EFEB),
                      iconAsset: 'assets/images/analysis/pyramid.svg',
                      iconBg: const Color(0xFFDFDEDA),
                      valueSize: valueSize,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _ValuationMetricTile(
                      title: 'Industry Ranking',
                      subtitle: 'Tech',
                      value: data['industry_ranking'] is num
                          ? '${((data['industry_ranking'] as num) * 100).toStringAsFixed(1)}%'
                          : '-',
                      valueColor: const Color(0xFFA38B55),
                      background: const Color(0xFFF6F1E7),
                      iconAsset: 'assets/images/analysis/ranking.svg',
                      iconBg: const Color(0xFFE5DBC4),
                      valueSize: valueSize,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _ValuationMetricTile(
                      title: 'Growth Potential',
                      subtitle: '',
                      value: data['growth_potential']?.toString() ?? '-',
                      valueColor: const Color(0xFFC97676),
                      background: const Color(0xFFF6E6DF),
                      iconAsset: 'assets/images/analysis/growth-investing.svg',
                      iconBg: const Color(0xFFF1D5CB),
                      valueSize: valueSize,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class LinkedinWorkExperienceCard extends StatelessWidget {
  const LinkedinWorkExperienceCard({
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
      iconAsset: 'assets/images/analysis/briefcase.svg',
      title: 'Work Experience',
      cardId: 'Work-Experience',
      showShareButton: !isStreaming,
      onShare: onShare,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: items.length > 3 ? 230 : double.infinity,
            ),
            child: SingleChildScrollView(
              physics: items.length > 3
                  ? const BouncingScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    if (i > 0) const SizedBox(height: 8),
                    _WorkExperienceRow(
                      company: _readCompany(items[i]),
                      position: _readPosition(items[i]),
                      workTime: _readWorkTime(items[i]),
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
              color: AnalysisTheme.panelBg,
              borderRadius: BorderRadius.circular(AnalysisTheme.radiusMd),
            ),
            child: Text(
              summary ?? 'Work experience summary not available.',
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Color(0xFF4D4846),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LinkedinSalaryCard extends StatelessWidget {
  const LinkedinSalaryCard({
    super.key,
    required this.data,
    this.isStreaming = false,
    this.onShare,
  });

  final Map<String, dynamic> data;
  final bool isStreaming;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    return AnalysisCardShell(
      iconAsset: 'assets/images/analysis/wallet.svg',
      title: 'Estimated Salary',
      cardId: 'Estimated-Salary',
      showShareButton: !isStreaming,
      onShare: onShare,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Text(
                _salaryLabel(data['estimated_salary']),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const Text(
                'Estimated Annual Earnings',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF7C7C7C)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 270,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AnalysisTheme.panelBg,
              borderRadius: BorderRadius.circular(AnalysisTheme.radiusMd),
            ),
            child: Text(
              data['explanation']?.toString() ?? 'Salary analysis not available.',
              maxLines: 10,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Color(0xFF464646),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContributionTile extends StatelessWidget {
  const _ContributionTile({
    required this.label,
    required this.value,
    required this.labelColor,
    required this.valueColor,
    required this.iconAsset,
    required this.backgroundImage,
    this.labelSize = 14,
    this.valueSize = 20,
  });

  final String label;
  final String value;
  final Color labelColor;
  final Color valueColor;
  final String iconAsset;
  final String backgroundImage;
  final double labelSize;
  final double valueSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 100),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AnalysisTheme.radiusMd),
        image: DecorationImage(
          image: AssetImage(backgroundImage),
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: labelColor == const Color(0xFF5F6D94)
                      ? const Color(0xFFD0D5E3)
                      : const Color(0xFFF1D5CB),
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: const EdgeInsets.all(4),
                child: SvgPicture.asset(iconAsset),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(color: labelColor, fontWeight: FontWeight.w700, fontSize: labelSize),
                ),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: valueSize,
              fontWeight: FontWeight.w600,
              fontFamily: AnalysisTheme.fontUdc,
            ),
          ),
        ],
      ),
    );
  }
}

class _ValuationMetricTile extends StatelessWidget {
  const _ValuationMetricTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.valueColor,
    required this.background,
    required this.iconAsset,
    required this.iconBg,
    this.valueSize = 18,
  });

  final String title;
  final String subtitle;
  final String value;
  final Color valueColor;
  final Color background;
  final String iconAsset;
  final Color iconBg;
  final double valueSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 120),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AnalysisTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: const EdgeInsets.all(4),
                child: SvgPicture.asset(iconAsset),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: valueColor,
                  fontSize: valueSize,
                  fontWeight: FontWeight.w600,
                  fontFamily: AnalysisTheme.fontUdc,
                ),
              ),
              if (subtitle.isNotEmpty)
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF949291))),
            ],
          ),
        ],
      ),
    );
  }
}

class _WorkExperienceRow extends StatelessWidget {
  const _WorkExperienceRow({
    required this.company,
    required this.position,
    required this.workTime,
    required this.isFirst,
    required this.isLast,
    this.logoUrl,
  });

  final String company;
  final String position;
  final String workTime;
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
          SizedBox(
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
                      border: isFirst
                          ? Border.all(color: const Color(0xFFCB7C5D), width: 1.5)
                          : null,
                    ),
                  ),
                ),
                if (!isLast)
                  Positioned(
                    top: isFirst ? 20 : 24,
                    left: 3,
                    bottom: 0,
                    child: CustomPaint(
                      size: const Size(1, 56),
                      painter: _DashedLinePainter(),
                    ),
                  ),
              ],
            ),
          ),
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
                                color: isFirst
                                    ? const Color(0xFFC88D75)
                                    : const Color(0xFFDCDCDC),
                                width: 2,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              AnalysisCompanyLogo(url: logoUrl, radius: 21),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  company,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (workTime.isNotEmpty)
                        Text(
                          workTime,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6F6F6F),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    position,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 2,
                      color: Color(0xFF3C3C3C),
                    ),
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

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const dashHeight = 4.0;
    const gap = 4.0;
    final paint = Paint()
      ..color = const Color(0xFFCCCCCC)
      ..strokeWidth = 1;
    var y = 0.0;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(0, y + dashHeight), paint);
      y += dashHeight + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

String _readCompany(dynamic item) {
  if (item is! Map) return '';
  return (item['companyName'] ?? item['company'])?.toString() ?? '';
}

String _readPosition(dynamic item) {
  if (item is! Map) return '';
  return (item['title'] ?? item['position'])?.toString() ?? '';
}

String _readLogo(dynamic item) {
  if (item is! Map) return '';
  return item['logo']?.toString() ?? '';
}

String _readWorkTime(dynamic item) {
  if (item is! Map) return '';
  final fromDate = item['jobStartedOn'] ?? item['from'];
  final toDate = item['jobStillWorking'] == true
      ? 'Present'
      : (item['jobEndedOn'] ?? item['to']);
  return _formatWorkTime(fromDate?.toString(), toDate?.toString());
}

String _formatWorkTime(String? fromDate, String? toDate) {
  String formatDate(String? d) {
    if (d == null || d.isEmpty || d == '-' || !RegExp(r'\d').hasMatch(d)) return '';
    return d.replaceAll('-', '.');
  }

  final from = formatDate(fromDate);
  final to = formatDate(toDate);
  if (from.isEmpty && to.isEmpty) return '';
  if (from.isNotEmpty && to.isNotEmpty) return '$from-$to';
  return from.isNotEmpty ? from : to;
}

Map<String, dynamic> _mapOf(dynamic value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  return {};
}

String _salaryLabel(dynamic value) {
  if (value == null || value.toString().trim().isEmpty) return 'Not Available';
  final formatted = AnalysisFormat.formatSalary(value);
  return formatted == r'$0' ? 'Not Available' : formatted;
}
