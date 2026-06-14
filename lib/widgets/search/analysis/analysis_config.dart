/// 与 TSX `analysisConfig.ts` + `analysis/config.ts` 对齐。
class AnalysisPreviewCardConfig {
  const AnalysisPreviewCardConfig({
    required this.key,
    required this.dataKey,
    required this.component,
    this.fullWidth = false,
  });

  final String key;
  final String dataKey;
  final String component;
  final bool fullWidth;
}

abstract final class AnalysisPlatformConfig {
  AnalysisPlatformConfig._();

  static const scholarPreview = [
    AnalysisPreviewCardConfig(
      key: 'papers',
      dataKey: 'papers',
      component: 'PapersCard',
    ),
    AnalysisPreviewCardConfig(
      key: 'earnings',
      dataKey: 'earnings',
      component: 'EarningsCard',
    ),
  ];

  static const githubPreview = [
    AnalysisPreviewCardConfig(
      key: 'overview',
      dataKey: 'activity',
      component: 'OverviewCard',
    ),
    AnalysisPreviewCardConfig(
      key: 'valuation',
      dataKey: 'valuation',
      component: 'ValuationCard',
    ),
  ];

  static const linkedinPreview = [
    AnalysisPreviewCardConfig(
      key: 'work_experience',
      dataKey: 'profile',
      component: 'WorkExperienceCard',
    ),
    AnalysisPreviewCardConfig(
      key: 'money',
      dataKey: 'money',
      component: 'SalaryCard',
    ),
  ];

  static const scholarOrder = [
    'papers',
    'insight',
    'role_model',
    'collaborator',
    'earnings',
    'research_style',
    'representative_paper',
    'paper_of_year',
  ];

  static const githubOrder = [
    'overview',
    'activity_heatmap',
    'feature_project',
    'languages',
    'top_projects',
    'most_valuable_pr',
    'role_model',
    'valuation',
  ];

  static const linkedinOrder = [
    'skills',
    'role_model',
    'career',
    'money',
    'life_well_being',
    'colleagues',
  ];

  static const cardLabels = {
    'papers': 'Papers',
    'insight': 'Insight',
    'role_model': 'Role Model',
    'collaborator': 'Collaborator',
    'earnings': 'Earnings',
    'research_style': 'Research Style',
    'representative_paper': 'Representative Paper',
    'paper_of_year': 'Paper of Year',
    'overview': 'Overview',
    'activity_heatmap': 'Activity',
    'feature_project': 'Feature Project',
    'languages': 'Languages',
    'top_projects': 'Top Projects',
    'most_valuable_pr': 'Best PR',
    'valuation': 'Valuation',
    'skills': 'Skills',
    'career': 'Career',
    'money': 'Salary',
    'life_well_being': 'Life & Well-being',
    'colleagues': 'Colleagues',
    'profile': 'Profile',
    'work_experience': 'Work Experience',
  };

  static List<AnalysisPreviewCardConfig> previewCards(String platform) {
    return switch (platform) {
      'github' => githubPreview,
      'linkedin' => linkedinPreview,
      _ => scholarPreview,
    };
  }

  static List<String> cardOrder(String platform) {
    return switch (platform) {
      'github' => githubOrder,
      'linkedin' => linkedinOrder,
      _ => scholarOrder,
    };
  }

  static List<AnalysisPreviewCardConfig> allConfigs(String platform) {
    return switch (platform) {
      'github' => const [
        AnalysisPreviewCardConfig(key: 'overview', dataKey: 'activity', component: 'OverviewCard'),
        AnalysisPreviewCardConfig(key: 'activity_heatmap', dataKey: 'activity', component: 'ActivityHeatmapCard'),
        AnalysisPreviewCardConfig(key: 'feature_project', dataKey: 'feature_project', component: 'FeatureProjectCard'),
        AnalysisPreviewCardConfig(key: 'languages', dataKey: 'activity', component: 'LanguagesCard'),
        AnalysisPreviewCardConfig(key: 'top_projects', dataKey: 'top_projects', component: 'TopProjectsCard'),
        AnalysisPreviewCardConfig(key: 'most_valuable_pr', dataKey: 'most_valuable_pr', component: 'MostValuablePRCard'),
        AnalysisPreviewCardConfig(key: 'role_model', dataKey: 'role_model', component: 'RoleModelCard'),
        AnalysisPreviewCardConfig(key: 'valuation', dataKey: 'valuation', component: 'ValuationCard'),
      ],
      'linkedin' => const [
        AnalysisPreviewCardConfig(key: 'skills', dataKey: 'skills', component: 'SkillsCard'),
        AnalysisPreviewCardConfig(key: 'role_model', dataKey: 'role_model', component: 'RoleModelCard'),
        AnalysisPreviewCardConfig(key: 'career', dataKey: 'career', component: 'CareerCard'),
        AnalysisPreviewCardConfig(key: 'money', dataKey: 'money', component: 'SalaryCard'),
        AnalysisPreviewCardConfig(key: 'life_well_being', dataKey: 'life_well_being', component: 'LifeWellBeingCard'),
        AnalysisPreviewCardConfig(key: 'colleagues', dataKey: 'colleagues', component: 'ColleaguesCard'),
      ],
      _ => const [
        AnalysisPreviewCardConfig(key: 'papers', dataKey: 'papers', component: 'PapersCard'),
        AnalysisPreviewCardConfig(key: 'insight', dataKey: 'insight', component: 'InsightCard'),
        AnalysisPreviewCardConfig(key: 'role_model', dataKey: 'role_model', component: 'RoleModelCard'),
        AnalysisPreviewCardConfig(key: 'collaborator', dataKey: 'closest_collaborator', component: 'CollaboratorCard'),
        AnalysisPreviewCardConfig(key: 'earnings', dataKey: 'earnings', component: 'EarningsCard'),
        AnalysisPreviewCardConfig(key: 'research_style', dataKey: 'research_style', component: 'ResearchStyleCard'),
        AnalysisPreviewCardConfig(key: 'representative_paper', dataKey: 'representative_paper', component: 'RepresentativePaperCard'),
        AnalysisPreviewCardConfig(key: 'paper_of_year', dataKey: 'paper_of_year', component: 'PaperOfYearCard'),
      ],
    };
  }

  /// 与 TSX `extractCardProps` 对齐。
  static AnalysisCardProps? extractCardProps(
    String component,
    Map<String, dynamic> cardData,
  ) {
    switch (component) {
      case 'OverviewCard':
        final overview = cardData['overview'];
        return AnalysisCardProps(
          data: overview is Map ? Map<String, dynamic>.from(overview) : cardData,
        );
      case 'ActivityHeatmapCard':
        final activity = cardData['activity'];
        if (activity is List) {
          return AnalysisCardProps(data: {'activity': activity});
        }
        return AnalysisCardProps(data: cardData);
      case 'ValuationCard':
        final valuation = cardData['valuation_and_level'];
        return AnalysisCardProps(
          data: valuation is Map ? Map<String, dynamic>.from(valuation) : cardData,
        );
      case 'LanguagesCard':
        final codeCont = cardData['code_contribution'];
        if (codeCont is Map) {
          final languages = codeCont['languages'];
          return AnalysisCardProps(
            data: {
              'languages': languages is Map ? languages : {},
              'total': codeCont['total'] ?? 0,
            },
          );
        }
        return null;
      case 'WorkExperienceCard':
        final work = cardData['work_experience'];
        if (work is List) {
          return AnalysisCardProps(
            data: {'items': work},
            summary: cardData['work_experience_summary']?.toString(),
          );
        }
        return null;
      case 'EducationCard':
        final education = cardData['education'];
        if (education is List) {
          return AnalysisCardProps(
            data: {'items': education},
            summary: cardData['education_summary']?.toString(),
          );
        }
        return null;
      case 'RoastCard':
        if (cardData['roast'] != null || cardData is String) {
          final text = cardData is String
              ? cardData
              : (cardData['roast'] is Map
                  ? (cardData['roast'] as Map)['roast']?.toString()
                  : cardData['roast']?.toString());
          return AnalysisCardProps(data: {'text': text ?? ''});
        }
        return null;
      default:
        return AnalysisCardProps(data: cardData);
    }
  }
}

class AnalysisCardProps {
  const AnalysisCardProps({required this.data, this.summary});

  final Map<String, dynamic> data;
  final String? summary;
}
