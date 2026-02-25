import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../stores/search_store.dart';

// ============== Nord 配色（与 TSX 一致）==============
const Color _kGreen = Color(0xFFA3BE8C); // Aurora green
const Color _kGreenBg = Color(0xFFE8F0E3);
const Color _kBlue = Color(0xFF81A1C1);
const Color _kBlueDark = Color(0xFF5E81AC);
const Color _kBlueBg = Color(0xFFE8F1F8);
const Color _kGrayBorder = Color(0xFFD1D5DB);
const Color _kGrayDot = Color(0xFF9CA3AF);
const Color _kGrayBg = Color(0xFFF5F5F5);
const Color _kGray200 = Color(0xFFE5E7EB);
const Color _kGray100 = Color(0xFFF3F4F6);
const Color _kGray50 = Color(0xFFF9FAFB);
const Color _kTextGray900 = Color(0xFF111827);
const Color _kTextGray500 = Color(0xFF6B7280);
const Color _kTextGray400 = Color(0xFF9CA3AF);
const Color _kTextGray600 = Color(0xFF4B5563);
const Color _kMatchBg = Color(0x2688C0D0); // rgba(136,192,208,0.15)
const Color _kMatchBorder = Color(0xFF88C0D0);

// ============== 完整度（与 TSX candidate.ts 一致）==============
const List<String> _kCompletenessFields = [
  'name',
  'research_areas',
  'company',
  'position',
  'university',
  'one_liner',
  'social_links',
  'key_publications',
  'email',
  'image_url',
];

const Map<String, String> _kFieldLabels = {
  'name': 'Name',
  'image_url': 'Avatar',
  'company': 'Company',
  'position': 'Position',
  'university': 'University',
  'one_liner': 'Bio',
  'research_areas': 'Research Areas',
  'key_publications': 'Publications',
  'social_links': 'Social Links',
  'email': 'Email',
};

bool _hasFieldValue(Map<String, dynamic> c, String field) {
  final value = c[field];
  if (value == null) return false;
  if (value is List) return value.isNotEmpty;
  if (value is String) return value.trim().isNotEmpty;
  return true;
}

double getCandidateCompleteness(Map<String, dynamic> c) {
  var filled = 0;
  for (final f in _kCompletenessFields) {
    if (_hasFieldValue(c, f)) filled++;
  }
  return filled / _kCompletenessFields.length;
}

String _getFirstName(String name) {
  if (name.isEmpty) return 'candidate';
  return name.split(' ').first;
}

// 与 TSX getEnrichingText 一致（确定性选择）
final Map<String, List<String>> _kEnrichingTemplates = {
  'name': ['Identifying %s', "Confirming %s's identity", 'Verifying name'],
  'image_url': [
    "Finding %s's photo",
    "Searching for %s's avatar",
    'Looking for a profile picture',
    "Locating %s's headshot",
  ],
  'company': [
    "Looking up %s's company",
    "Finding where %s works",
    "Checking %s's current employer",
    'Searching for workplace info',
  ],
  'position': [
    "Checking %s's role",
    "Finding %s's title",
    'Looking up current position',
    "What does %s do?",
  ],
  'university': [
    "Finding %s's education",
    "Looking up %s's alma mater",
    'Checking academic background',
    "Where did %s study?",
  ],
  'one_liner': [
    "Writing %s's bio",
    "Summarizing %s's background",
    'Crafting a quick intro',
    'Generating profile summary',
  ],
  'research_areas': [
    "Exploring %s's research",
    "What does %s study?",
    'Finding areas of expertise',
    'Mapping research interests',
  ],
  'key_publications': [
    "Fetching %s's papers",
    'Searching for publications',
    'Finding notable works',
    "What has %s published?",
  ],
  'social_links': [
    "Finding %s's socials",
    'Locating online profiles',
    'Searching LinkedIn, Twitter',
    "Where is %s online?",
  ],
  'email': [
    "Finding %s's email",
    'Looking up contact info',
    'Searching for email address',
    "How to reach %s?",
  ],
};

String _getEnrichingText(String field, String firstName) {
  final options = _kEnrichingTemplates[field] ??
      ['Enriching ${firstName}\'s ${_kFieldLabels[field] ?? field}'];
  final hash =
      (firstName + field).split('').fold<int>(0, (acc, char) => acc + char.codeUnitAt(0));
  return options[hash % options.length].replaceAll('%s', firstName);
}

String? _getFieldDisplayValue(Map<String, dynamic> c, String field) {
  final value = c[field];
  if (value == null) return null;
  if (field == 'image_url') return '✓';
  if (field == 'research_areas' && value is List) {
    final list = value.map((e) => e.toString()).toList();
    final head = list.take(2).join(', ');
    return list.length > 2 ? '$head...' : head;
  }
  if (field == 'key_publications' && value is List) {
    return '${value.length} publications';
  }
  if (field == 'social_links' && value is List) {
    return '${value.length} links';
  }
  if (field == 'email' && value is List && value.isNotEmpty) {
    return value[0].toString();
  }
  if (value is String) {
    return value.length > 30 ? '${value.substring(0, 30)}...' : value;
  }
  return null;
}

// 从 URL 提取域名（与 TSX getDomainFromUrl 一致）
String _getDomainFromUrl(String url) {
  try {
    final uri = Uri.parse(url);
    final host = uri.host;
    return host.startsWith('www.') ? host.substring(4) : host;
  } catch (_) {
    return url;
  }
}

Map<String, List<Map<String, dynamic>>> _groupSourcesByDomain(
    List<dynamic> sources) {
  final acc = <String, List<Map<String, dynamic>>>{};
  for (final s in sources) {
    final m = s is Map ? Map<String, dynamic>.from(s) : null;
    if (m == null) continue;
    final url = m['url'] as String?;
    if (url == null || url.isEmpty) continue;
    final domain = _getDomainFromUrl(url);
    acc.putIfAbsent(domain, () => []).add(m);
  }
  return acc;
}

// 非线性进度（与 TSX getPerceivedProgress 一致）
double _getPerceivedProgress(double real) {
  if (real <= 0.7) return (real / 0.7) * 0.5;
  return 0.5 + ((real - 0.7) / 0.3) * 0.5;
}

String? _firstUnfilledField(Set<String> filled) {
  for (final f in _kCompletenessFields) {
    if (!filled.contains(f)) return f;
  }
  return null;
}

// ============== 里程碑顶栏（仅移动端：标题 + "Tap to view"，里程碑节点无文字）==============
class _MilestoneProgress extends StatelessWidget {
  const _MilestoneProgress({
    required this.candidateCount,
    required this.isSearching,
    required this.avgPercent,
    required this.candidates,
  });

  final int candidateCount;
  final bool isSearching;
  final int avgPercent;
  final List<Map<String, dynamic>> candidates;

  @override
  Widget build(BuildContext context) {
    final hasReadyCandidate = candidates.any((c) {
      final hasAvatar = (c['image_url']?.toString() ?? '').trim().isNotEmpty;
      final completeness = getCandidateCompleteness(c);
      return hasAvatar || completeness >= 0.7;
    });

    String stage;
    int stageIndex;
    if (!isSearching && candidateCount > 0) {
      stage = 'complete';
      stageIndex = 2;
    } else if (hasReadyCandidate) {
      stage = 'enriching';
      stageIndex = 1;
    } else if (candidateCount > 0) {
      stage = 'basic';
      stageIndex = 0;
    } else {
      stage = 'basic';
      stageIndex = 0;
    }

    final isComplete = stage == 'complete';
    final maxCompleteness = candidates.isEmpty
        ? 0.0
        : candidates.map(getCandidateCompleteness).reduce((a, b) => a > b ? a : b);
    final stageProgress = stage == 'basic' ? maxCompleteness : avgPercent / 100.0;
    final perceived = _getPerceivedProgress(stageProgress);
    final displayPercent = (perceived * 100).round().clamp(0, 99);

    // 移动端提示文案
    final stageHint = stage == 'basic'
        ? 'Found'
        : stage == 'enriching'
            ? 'Tap to view'
            : 'All ready';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _kGray50.withOpacity(0.8),
        border: Border(bottom: BorderSide(color: _kGray100)),
      ),
      child: Row(
        children: [
          Text(
            '$candidateCount Candidates',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _kTextGray600,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            '·',
            style: TextStyle(fontSize: 14, color: _kTextGray400),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              stageHint,
              style: const TextStyle(fontSize: 14, color: _kTextGray500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!isComplete)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _milestoneDot(0, stageIndex, displayPercent, true),
                _connector(0, stageIndex),
                _milestoneDot(1, stageIndex, displayPercent, false),
                _connector(1, stageIndex),
                _milestoneDot(2, stageIndex, displayPercent, false),
              ],
            ),
        ],
      ),
    );
  }

  Widget _milestoneDot(int idx, int stageIndex, int displayPercent, bool isLast) {
    final isCompleted = idx < stageIndex;
    final isCurrent = idx == stageIndex;
    Color bg = _kGrayBg;
    Color border = _kGrayBorder;
    Widget child = Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: _kGrayDot,
      ),
    );
    if (isCompleted) {
      bg = _kGreenBg;
      border = _kGreen;
      child = Icon(Icons.check, size: 12, color: _kGreen);
    } else if (isCurrent) {
      bg = _kBlueBg;
      border = _kBlue;
      child = const SizedBox(
        width: 12,
        height: 12,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(_kBlue),
        ),
      );
    }
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bg,
        border: Border.all(color: border),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }

  Widget _connector(int idx, int stageIndex) {
    final filled = stageIndex > idx;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: SizedBox(
        width: 16,
        height: 2,
        child: Container(
          decoration: BoxDecoration(
            color: filled ? _kGreen : _kGray200.withOpacity(0.6),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
    );
  }
}

// Source 标签（与 TSX SourceTag 一致，移动端）
class _SourceTag extends StatelessWidget {
  const _SourceTag({
    required this.domain,
    required this.count,
    required this.url,
  });

  final String domain;
  final int count;
  final String url;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: _kGray200),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              domain,
              style: const TextStyle(fontSize: 11, color: _kTextGray500),
            ),
            if (count > 1) ...[
              const SizedBox(width: 4),
              Text(
                '+${count - 1}',
                style: const TextStyle(fontSize: 11, color: _kTextGray400),
              ),
            ],
            const SizedBox(width: 4),
            Icon(Icons.open_in_new, size: 10, color: _kTextGray400),
          ],
        ),
      ),
    );
  }
}

/// 与 TSX ScholarsList 对应，只保留移动端样式
class ScholarsList extends StatelessWidget {
  const ScholarsList({
    super.key,
    required this.candidates,
    required this.groupId,
    required this.isLoading,
    this.onCandidateClick,
  });

  final List<Map<String, dynamic>> candidates;
  final int groupId;
  final bool isLoading;
  final void Function(Map<String, dynamic> candidate, int index, int groupId)?
      onCandidateClick;

  @override
  Widget build(BuildContext context) {
    if (candidates.isEmpty) return const SizedBox.shrink();

    final totalCompleteness =
        candidates.fold<double>(0, (sum, c) => sum + getCandidateCompleteness(c));
    final avgPercent = (totalCompleteness / candidates.length * 100).round();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _kGray200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _MilestoneProgress(
              candidateCount: candidates.length,
              isSearching: isLoading,
              avgPercent: avgPercent,
              candidates: candidates,
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 480),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: candidates.length,
                itemBuilder: (context, idx) {
                  final candidate = candidates[idx];
                  final isSelected = _isSelected(context, idx);
                  return _CandidateCard(
                    candidate: candidate,
                    isLast: idx == candidates.length - 1,
                    isLoading: isLoading,
                    isSelected: isSelected,
                    onTap: () {
                      if (onCandidateClick != null) {

                        debugPrint('candidate1111: $candidate');
                        onCandidateClick!(candidate, idx, groupId);
                      } else {
                        debugPrint('candidate22222: $candidate');
                        final store = context.read<SearchStore>();
                        final tabId = store.openTabWithClick(
                              candidate,
                              index: idx,
                              groupId: groupId,
                            );
                        if (tabId != null) store.setTabPanelOpen(true);
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSelected(BuildContext context, int idx) {
    final store = context.read<SearchStore>();
    final active = store.getActiveTab();
    if (active == null) return false;
    final c = active.candidate;
    final gId = c['groupId'];
    final orig = c['originalIndex'];
    return gId == groupId && orig == idx;
  }
}

class _CandidateCard extends StatefulWidget {
  const _CandidateCard({
    required this.candidate,
    required this.isLast,
    required this.isLoading,
    required this.isSelected,
    required this.onTap,
  });

  final Map<String, dynamic> candidate;
  final bool isLast;
  final bool isLoading;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_CandidateCard> createState() => _CandidateCardState();
}

class _CandidateCardState extends State<_CandidateCard> {
  bool _progressExpanded = false;
  bool _progressBarVisible = true;
  List<String> _fieldTimeline = [];
  String? _enrichingField;
  Set<String> _prevFilled = {};
  bool _isFlashing = false;
  Timer? _flashTimer;

  @override
  void initState() {
    super.initState();
    _progressBarVisible = widget.isLoading;
    _updateFilledAndTimeline();
  }

  @override
  void didUpdateWidget(covariant _CandidateCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.candidate != oldWidget.candidate || widget.isLoading != oldWidget.isLoading) {
      _updateFilledAndTimeline();
    }
    if (!widget.isLoading && oldWidget.isLoading) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          setState(() {
            _progressBarVisible = false;
            _progressExpanded = false;
          });
        }
      });
    }
    if (widget.isLoading && !oldWidget.isLoading) {
      setState(() => _progressBarVisible = true);
    }
  }

  void _updateFilledAndTimeline() {
    final current = _getFilledFieldsStatic(widget.candidate);
    final prev = _prevFilled;

    final newFields = current.where((f) => !prev.contains(f)).toList();
    if (newFields.isNotEmpty) {
      setState(() {
        _fieldTimeline = [..._fieldTimeline, ...newFields];
        _isFlashing = true;
        _enrichingField = _firstUnfilledField(current);
      });
      _flashTimer?.cancel();
      _flashTimer = Timer(const Duration(milliseconds: 800), () {
        if (mounted) setState(() => _isFlashing = false);
      });
    }
    if (_enrichingField == null && widget.isLoading) {
      _enrichingField = _firstUnfilledField(current);
    }
    if (!widget.isLoading) _enrichingField = null;
    _prevFilled = current;
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.candidate;
    final completeness = getCandidateCompleteness(c);
    final realPercent = (completeness * 100).round();
    final hasAvatar = (c['image_url']?.toString() ?? '').trim().isNotEmpty;
    final canClick = !widget.isLoading || hasAvatar || completeness >= 0.7;

    final isComplete = realPercent >= 80;
    final isMedium = realPercent >= 50 && realPercent < 80;
    Color progressColor = _kGrayDot;
    if (isComplete) progressColor = _kGreen;
    else if (isMedium) progressColor = _kBlue;

    final perceived = _getPerceivedProgress(completeness);
    final displayPercent = (perceived * 100).round().clamp(0, 99);

    final company = _parseCompany(c['company']);
    final position = _parseCompany(c['position']);
    final name = c['name'] as String? ?? 'Unknown';
    final matchReason = c['match_reason'] as String?;

    final timelineFields = _fieldTimeline.isNotEmpty
        ? _fieldTimeline.where((f) => _hasFieldValue(c, f)).toList()
        : _kCompletenessFields.where((f) => _hasFieldValue(c, f)).toList();
    final firstName = _getFirstName(name);
    final sources = c['sources'] as List<dynamic>? ?? [];
    final groupedSources = _groupSourcesByDomain(sources);
    final domains = groupedSources.keys.toList();

    Color bgColor = Colors.transparent;
    if (_isFlashing) bgColor = const Color(0x99FAF0C8);
    else if (widget.isSelected) bgColor = _kMatchBg;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: widget.isLast ? null : const Border(bottom: BorderSide(color: _kGray100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () {
              if (canClick) {
                widget.onTap();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Still enriching, please wait...')),
                );
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Row(
                    children: [
                      _buildAvatar(c['image_url'], name, widget.isLoading),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: _kTextGray900,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (company.isNotEmpty || position.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                [company, position].where((e) => e.isNotEmpty).join(' · '),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _kTextGray500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (widget.isLoading && !_progressBarVisible)
                        _buildProgressButton(realPercent, isComplete),
                      Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: canClick ? _kGray200 : Colors.transparent,
                      ),
                    ],
                  ),
                ),
                if (matchReason != null && matchReason.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _kMatchBg,
                            border: Border.all(color: _kMatchBorder),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'match',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: _kBlueDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            matchReason,
                            style: const TextStyle(
                              fontSize: 12,
                              color: _kTextGray500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          _buildProgressSection(
            progressBarVisible: _progressBarVisible,
            progressExpanded: _progressExpanded,
            realPercent: realPercent,
            displayPercent: displayPercent,
            isComplete: isComplete,
            progressColor: progressColor,
            timelineFields: timelineFields,
            enrichingField: _enrichingField,
            firstName: firstName,
            candidate: c,
            domains: domains,
            groupedSources: groupedSources,
            onToggleExpand: () => setState(() => _progressExpanded = !_progressExpanded),
            onHideProgress: () => setState(() {
              _progressBarVisible = false;
              _progressExpanded = false;
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(dynamic imageUrl, String name, bool loading) {
    final url = imageUrl?.toString() ?? '';
    return SizedBox(
      width: 40,
      height: 40,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: url.isEmpty
            ? Container(
                color: _kGray100,
                child: const Icon(Icons.person, size: 24, color: _kTextGray400),
              )
            : Image.network(
                url,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: _kGray100,
                    alignment: Alignment.center,
                    child: const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 24),
              ),
      ),
    );
  }

  Widget _buildProgressLabel({
    required bool progressExpanded,
    required int realPercent,
    required int displayPercent,
    required bool isComplete,
    required Color progressColor,
    required List<String> timelineFields,
    required String? enrichingField,
    required String firstName,
  }) {
    if (progressExpanded) {
      return Text(
        realPercent == 100
            ? 'Profile complete'
            : '${timelineFields.length} of ${_kCompletenessFields.length} fields',
        style: TextStyle(fontSize: 12, color: progressColor),
        overflow: TextOverflow.ellipsis,
      );
    }
    if (widget.isLoading && enrichingField != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '${_getEnrichingText(enrichingField, firstName)}...',
              style: const TextStyle(fontSize: 12, color: _kBlueDark),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }
    if (widget.isLoading && enrichingField == null && realPercent == 100) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check, size: 12, color: _kGreen),
          const SizedBox(width: 6),
          const Text(
            'Profile complete',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _kGreen),
          ),
        ],
      );
    }
    if (widget.isLoading && enrichingField == null && realPercent < 100) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              "Verifying $firstName's profile...",
              style: const TextStyle(fontSize: 12, color: _kBlueDark),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }
    if (!widget.isLoading && realPercent == 100) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check, size: 12, color: _kGreen),
          const SizedBox(width: 6),
          const Text(
            'Profile complete',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _kGreen),
          ),
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isComplete) Icon(Icons.check, size: 12, color: progressColor),
        if (isComplete) const SizedBox(width: 6),
        Flexible(
          child: Text(
            '${timelineFields.length} of ${_kCompletenessFields.length} fields enriched',
            style: TextStyle(
              fontSize: 12,
              fontWeight: isComplete ? FontWeight.w500 : null,
              color: progressColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressButton(int realPercent, bool isComplete) {
    return GestureDetector(
      onTap: () => setState(() {
        _progressBarVisible = true;
        _progressExpanded = true;
      }),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isComplete ? Icons.check : Icons.refresh,
              size: 12,
              color: isComplete ? _kGreen : _kBlue,
            ),
            const SizedBox(width: 4),
            Text(
              '$realPercent%',
              style: TextStyle(
                fontSize: 11,
                color: isComplete ? _kGreen : _kBlue,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection({
    required bool progressBarVisible,
    required bool progressExpanded,
    required int realPercent,
    required int displayPercent,
    required bool isComplete,
    required Color progressColor,
    required List<String> timelineFields,
    required String? enrichingField,
    required String firstName,
    required Map<String, dynamic> candidate,
    required List<String> domains,
    required Map<String, List<Map<String, dynamic>>> groupedSources,
    required VoidCallback onToggleExpand,
    required VoidCallback onHideProgress,
  }) {
    if (!progressBarVisible) return const SizedBox.shrink();

    return AnimatedCrossFade(
      firstChild: const SizedBox.shrink(),
      secondChild: Container(
        color: _kGray50.withOpacity(0.5),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    size: 12,
                    color: _kTextGray400,
                  ),
                  onPressed: onToggleExpand,
                  style: IconButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(24, 24),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: onToggleExpand,
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildProgressLabel(
                            progressExpanded: progressExpanded,
                            realPercent: realPercent,
                            displayPercent: displayPercent,
                            isComplete: isComplete,
                            progressColor: progressColor,
                            timelineFields: timelineFields,
                            enrichingField: enrichingField,
                            firstName: firstName,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 64,
                          height: 6,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: (isComplete ? realPercent : displayPercent) / 100.0,
                              backgroundColor: _kGray200,
                              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 32,
                          child: Text(
                            '${isComplete ? realPercent : displayPercent}%',
                            style: TextStyle(fontSize: 12, color: progressColor),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 12, color: _kTextGray400),
                  onPressed: onHideProgress,
                  style: IconButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(24, 24),
                  ),
                ),
              ],
            ),
            if (progressExpanded) ...[
              const SizedBox(height: 12),
              ...timelineFields.map((field) {
                final label = _kFieldLabels[field] ?? field;
                final value = _getFieldDisplayValue(candidate, field);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _kGreenBg,
                          border: Border.all(color: _kGreen),
                        ),
                        alignment: Alignment.center,
                        child: Icon(Icons.check, size: 10, color: _kGreen),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _kTextGray600,
                        ),
                      ),
                      if (value != null && value != '✓') ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: _kGray200),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              value,
                              style: const TextStyle(
                                fontSize: 11,
                                color: _kTextGray500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
              if (widget.isLoading && enrichingField != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _kBlueBg,
                          border: Border.all(color: _kBlue),
                        ),
                        alignment: Alignment.center,
                        child: const SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(_kBlue),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_getEnrichingText(enrichingField, firstName)}...',
                        style: const TextStyle(fontSize: 12, color: _kBlueDark),
                      ),
                    ],
                  ),
                ),
              if (domains.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.only(top: 12),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: _kGray100)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SOURCES',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 1,
                          color: _kTextGray400,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: domains.take(6).map((domain) {
                          final list = groupedSources[domain]!;
                          final url = list.isNotEmpty ? (list[0]['url'] as String? ?? '') : '';
                          return _SourceTag(
                            domain: domain,
                            count: list.length,
                            url: url,
                          );
                        }).toList(),
                      ),
                      if (domains.length > 6)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '+${domains.length - 6} more',
                            style: const TextStyle(fontSize: 12, color: _kTextGray400),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
      duration: const Duration(milliseconds: 300),
      crossFadeState:
          progressBarVisible ? CrossFadeState.showSecond : CrossFadeState.showFirst,
    );
  }

  String _parseCompany(dynamic v) {
    if (v == null) return '';
    final s = v.toString().trim();
    return s;
  }
}

// 避免递归：在类外定义
Set<String> _getFilledFieldsStatic(Map<String, dynamic> c) {
  final set = <String>{};
  for (final f in _kCompletenessFields) {
    if (_hasFieldValue(c, f)) set.add(f);
  }
  return set;
}
