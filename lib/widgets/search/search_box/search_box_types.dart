import 'package:flutter/material.dart';

/// 与 TSX SearchBox / ToolsMenu 对齐的类型定义

typedef SearchToolType = String; // find-advisor | who-cites-me | analysis

enum CitationMode { author, paper }

class AdvisorFormData {
  AdvisorFormData({
    required this.resumeUrl,
    this.resumeName,
    required this.additionalInfo,
    required this.countries,
    this.maxAdvisors = 5,
  });

  final String resumeUrl;
  final String? resumeName;
  final String additionalInfo;
  final List<String> countries;
  final int maxAdvisors;
}

class DeepSearchSubmitParams {
  DeepSearchSubmitParams({
    this.query = '',
    this.displayQuery,
    this.modelProvider = 'anthropic-hao',
    this.attachment,
    this.attachmentName,
  });

  final String query;
  final String? displayQuery;
  final String modelProvider;
  final String? attachment;
  final String? attachmentName;
}

class AnalysisSearchParams {
  AnalysisSearchParams({
    required this.platform,
    required this.query,
    this.candidateData,
  });

  final String platform; // scholar | github | linkedin
  final String query;
  final Map<String, dynamic>? candidateData;
}

class SearchToolDefinition {
  const SearchToolDefinition({
    required this.id,
    required this.label,
    required this.icon,
    required this.iconColor,
  });

  final SearchToolType id;
  final String label;
  final IconData icon;
  final Color iconColor;
}

const List<SearchToolDefinition> kSearchTools = [
  SearchToolDefinition(
    id: 'find-advisor',
    label: 'Find Advisor',
    icon: Icons.school_outlined,
    iconColor: Color(0xFFD97706),
  ),
  SearchToolDefinition(
    id: 'who-cites-me',
    label: 'Who Cites Me',
    icon: Icons.menu_book_outlined,
    iconColor: Color(0xFF2563EB),
  ),
  SearchToolDefinition(
    id: 'analysis',
    label: 'Analysis',
    icon: Icons.bar_chart_outlined,
    iconColor: Color(0xFFCB7C5D),
  ),
];

const Map<String, String> kAnalysisPlatformLabels = {
  'scholar': 'Scholar',
  'github': 'GitHub',
  'linkedin': 'LinkedIn',
};

const Map<String, String> kAnalysisPlaceholders = {
  'scholar': 'Enter scholar name or Google Scholar URL...',
  'github': 'Enter GitHub username or profile URL...',
  'linkedin': 'Enter name or LinkedIn profile URL...',
};

const double kSearchBoxMinHeight = 28;
const double kSearchBoxMaxHeight = 240;
const int kSearchBoxMaxLength = 2000;
const int kSearchBoxShowLimitThreshold = 1800;

const Set<String> kAttachmentExtensions = {
  'txt',
  'md',
  'csv',
  'docx',
  'pdf',
  'png',
  'jpg',
  'jpeg',
  'webp',
  'gif',
};

/// 工具面板统一句柄（与 TSX ToolPanelRef 对齐）
class ToolPanelHandle {
  bool Function()? getCanSubmit;
  VoidCallback? submit;

  bool get canSubmit => getCanSubmit?.call() ?? false;

  void trySubmit() => submit?.call();
}

/// 工具面板顶部选项区（仅底部分割线，不再叠加圆角边框）
const BoxDecoration kToolPanelHeaderDecoration = BoxDecoration(
  color: Color(0xFFFDFCFB),
  border: Border(bottom: BorderSide(color: Color(0xFFF5F5F5))),
);

InputDecoration searchBoxInputDecoration({
  required String hintText,
  EdgeInsetsGeometry contentPadding = EdgeInsets.zero,
}) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: const TextStyle(color: Color(0xFFA5A39E)),
    border: InputBorder.none,
    enabledBorder: InputBorder.none,
    focusedBorder: InputBorder.none,
    disabledBorder: InputBorder.none,
    errorBorder: InputBorder.none,
    focusedErrorBorder: InputBorder.none,
    isDense: true,
    contentPadding: contentPadding,
    counterText: '',
  );
}
