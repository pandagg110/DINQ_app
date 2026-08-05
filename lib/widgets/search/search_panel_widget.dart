import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';

import '../../stores/search_store.dart';
import 'agentic_search_logic.dart';
import 'deep_search/deep_search_models.dart';
import 'deep_search/deep_search_results_helpers.dart';
import 'message_group/quick_replies_widget.dart';
import 'search_panel/result_entry_card.dart';
import 'search_panel/round_section.dart';
import 'search_panel/search_interaction_scope.dart';

class SearchPanelWidget extends StatefulWidget {
  const SearchPanelWidget({
    super.key,
    required this.messageGroups,
    required this.scrollController,
    required this.activeTool,
    required this.onQuickReplySelect,
    this.onConfirmStart,
    required this.onCandidateClick,
    this.bottomInset = 24,
    this.hideUserQueryBubble = false,
    this.onAdvisorShuffle,
    this.advisorShuffleLoading,
    this.analysisPlatform,
    this.citationMode,
    this.selectedRowId,
    this.showInlineResults = true,
    this.resultEntryMode = ResultEntryMode.desktop,
    this.onOpenResultsRound,
    this.activeResultsRoundId,
    this.onRetryRound,
    this.backgroundProcessing = false,
  });

  final List<AgenticMessageGroup> messageGroups;
  final ScrollController scrollController;
  final String? activeTool;
  final QuickReplySelectCallback onQuickReplySelect;
  final ConfirmStartCallback? onConfirmStart;
  final void Function(Map<String, dynamic> candidate, int index, int groupId)
  onCandidateClick;
  final double bottomInset;
  final bool hideUserQueryBubble;
  final VoidCallback? onAdvisorShuffle;
  final bool? advisorShuffleLoading;
  final String? analysisPlatform;
  final String? citationMode;
  final String? selectedRowId;
  final bool showInlineResults;
  final ResultEntryMode resultEntryMode;
  final void Function(int roundId)? onOpenResultsRound;
  final int? activeResultsRoundId;
  final void Function(AgenticMessageGroup group)? onRetryRound;

  /// 与 Web SearchPanel `backgroundProcessing` 对齐：最后一轮强制展示进行中态
  final bool backgroundProcessing;

  @override
  State<SearchPanelWidget> createState() => _SearchPanelWidgetState();
}

class _SearchPanelWidgetState extends State<SearchPanelWidget> {
  static const _topOffset = 64.0;
  static const _smoothDurationMs = 500;

  final GlobalKey _listViewKey = GlobalKey();
  final Map<int, GlobalKey> _roundKeys = {};

  bool _showScrollToBottom = false;
  bool _isUserScrolled = false;
  bool _isProgrammaticScroll = false;

  int _prevRoundsLen = 0;
  String _lastStreamSignature = '';
  double _viewportHeight = 0;
  double _lastRoundHeight = 0;
  double _spacerHeight = 24;
  int? _copiedRoundId;

  @override
  void initState() {
    super.initState();
    _prevRoundsLen = widget.messageGroups.length;
    _lastStreamSignature = _streamSignature(widget.messageGroups);
    _spacerHeight = widget.bottomInset;
    widget.scrollController.addListener(_handleScroll);
  }

  @override
  void didUpdateWidget(covariant SearchPanelWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController.removeListener(_handleScroll);
      widget.scrollController.addListener(_handleScroll);
    }

    final rounds = widget.messageGroups;
    final len = rounds.length;
    if (len > _prevRoundsLen) {
      _prevRoundsLen = len;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _scrollNewRoundToTop();
      });
    } else {
      _prevRoundsLen = len;
    }

    final signature = _streamSignature(rounds);
    if (signature != _lastStreamSignature) {
      _lastStreamSignature = signature;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _stickToBottomDuringStreaming();
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _recalcSpacer();
    });
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_handleScroll);
    super.dispose();
  }

  void _handleScroll() {
    if (!widget.scrollController.hasClients) return;
    if (_isProgrammaticScroll) return;
    final position = widget.scrollController.position;
    final dist = position.maxScrollExtent - position.pixels;
    _isUserScrolled = dist > 80;
    final show = dist > 220;
    if (show != _showScrollToBottom && mounted) {
      setState(() => _showScrollToBottom = show);
    }
  }

  void _scrollToBottom() {
    if (!widget.scrollController.hasClients) return;
    widget.scrollController.animateTo(
      widget.scrollController.position.maxScrollExtent + 40,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
    );
    _isUserScrolled = false;
    if (_showScrollToBottom) {
      setState(() => _showScrollToBottom = false);
    }
  }

  String _streamSignature(List<AgenticMessageGroup> groups) {
    if (groups.isEmpty) return 'empty';
    final last = groups.last;
    final subBlocks = last.subAgents.values.fold<int>(
      0,
      (sum, agent) => sum + agent.contentBlocks.length,
    );
    return [
      groups.length,
      last.id,
      last.loading,
      last.assistantStreaming,
      last.candidates.length,
      last.thinkingSteps.length,
      subBlocks,
      last.assistantText.length,
    ].join('|');
  }

  void _scrollNewRoundToTop() {
    if (!widget.scrollController.hasClients || widget.messageGroups.isEmpty) {
      return;
    }

    final expanded = _viewportHeight > 0
        ? _viewportHeight
        : widget.scrollController.position.viewportDimension;
    if ((expanded - _spacerHeight).abs() > 2) {
      setState(() => _spacerHeight = expanded);
    }

    final lastRoundId = widget.messageGroups.last.id;
    final targetKey = _roundKeys[lastRoundId];
    final targetBox =
        targetKey?.currentContext?.findRenderObject() as RenderBox?;
    final listBox =
        _listViewKey.currentContext?.findRenderObject() as RenderBox?;
    if (targetBox == null || listBox == null) return;

    final topInViewport = targetBox
        .localToGlobal(Offset.zero, ancestor: listBox)
        .dy;
    final current = widget.scrollController.offset;
    final target = (current + topInViewport - _topOffset).clamp(
      0.0,
      widget.scrollController.position.maxScrollExtent,
    );

    _isProgrammaticScroll = true;
    _isUserScrolled = false;
    widget.scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: _smoothDurationMs),
      curve: Curves.easeOut,
    );
    Future<void>.delayed(const Duration(milliseconds: _smoothDurationMs), () {
      if (!mounted) return;
      _isProgrammaticScroll = false;
    });
  }

  void _stickToBottomDuringStreaming() {
    if (!widget.scrollController.hasClients || widget.messageGroups.isEmpty) {
      return;
    }
    if (_isUserScrolled || _isProgrammaticScroll) return;

    final last = widget.messageGroups.last;
    final isToolRound =
        last.searchType == 'advisor' || last.searchType == 'dinq';
    if (isToolRound) return;
    if (!_isStreaming(last)) return;

    if (_lastRoundHeight < _viewportHeight * 0.8) return;

    widget.scrollController.jumpTo(
      widget.scrollController.position.maxScrollExtent,
    );
  }

  bool _isStreaming(AgenticMessageGroup group) {
    if (group.loading || group.assistantStreaming) return true;
    return group.subAgents.values.any(
      (agent) =>
          agent.status == DeepSearchRoundStatus.searching ||
          agent.contentBlocks.any(
            (block) =>
                block is ThinkingPart && block.block.isStreaming ||
                block is ToolCallPart &&
                    block.block.status == ToolCallStatus.running,
          ),
    );
  }

  void _recalcSpacer() {
    if (!mounted) return;
    final minSpacer = widget.bottomInset;
    final computed = (_viewportHeight - _lastRoundHeight).clamp(
      minSpacer,
      2000.0,
    );
    if ((computed - _spacerHeight).abs() > 2) {
      setState(() => _spacerHeight = computed);
    }
  }

  GlobalKey _keyForRound(int id) {
    return _roundKeys.putIfAbsent(id, GlobalKey.new);
  }

  @override
  Widget build(BuildContext context) {
    final groups = widget.messageGroups;
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = constraints.maxHeight;
        if ((viewport - _viewportHeight).abs() > 2) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _viewportHeight = viewport;
            _recalcSpacer();
          });
        }

        return SearchInteractionScope(
          onQuickReplySelect: widget.onQuickReplySelect,
          onConfirmStart: widget.onConfirmStart,
          child: Stack(
            children: [
              if (groups.isEmpty)
                _ToolWelcome(
                  activeTool: widget.activeTool,
                  analysisPlatform: widget.analysisPlatform ?? 'scholar',
                  citationMode: widget.citationMode ?? 'author',
                )
              else
                ListView(
                  key: _listViewKey,
                  controller: widget.scrollController,
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  children: [
                    for (var i = 0; i < groups.length; i++) ...[
                      _MeasureSize(
                        onChange: (size) {
                          if (i == groups.length - 1) {
                            _lastRoundHeight = size.height;
                            _recalcSpacer();
                          }
                        },
                        child: Container(
                          key: _keyForRound(groups[i].id),
                          alignment: Alignment.center,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 768),
                            child: RoundSection(
                              group: groups[i],
                              isLatest: i == groups.length - 1,
                              hideUserQueryBubble: widget.hideUserQueryBubble,
                              backgroundProcessing:
                                  widget.backgroundProcessing &&
                                  i == groups.length - 1,
                              onCandidateClick: widget.onCandidateClick,
                              selectedRowId: widget.selectedRowId,
                              copied: _copiedRoundId == groups[i].id,
                              onCopyMarkdown: () =>
                                  _copyRoundMarkdown(groups[i]),
                              onAdvisorShuffle: widget.onAdvisorShuffle,
                              advisorShuffleLoading:
                                  widget.advisorShuffleLoading ?? false,
                              showInlineResults: widget.showInlineResults,
                              resultEntryMode: widget.resultEntryMode,
                              onOpenResultsRound: widget.onOpenResultsRound,
                              activeResultsRoundId: widget.activeResultsRoundId,
                              onRetry: widget.onRetryRound == null
                                  ? null
                                  : () => widget.onRetryRound!(groups[i]),
                            ),
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: _spacerHeight),
                  ],
                ),
              if (_showScrollToBottom)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 16,
                  child: Center(
                    child: SizedBox(
                      width: 34,
                      height: 34,
                      child: Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        elevation: 1,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _scrollToBottom,
                          child: const Icon(
                            Icons.arrow_downward,
                            size: 18,
                            color: Color(0xFF6B6862),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _copyRoundMarkdown(AgenticMessageGroup group) async {
    final markdown = _buildRoundMarkdown(group);
    await Clipboard.setData(ClipboardData(text: markdown));
    if (!mounted) return;
    setState(() => _copiedRoundId = group.id);
    Future<void>.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted || _copiedRoundId != group.id) return;
      setState(() => _copiedRoundId = null);
    });
  }

  String _buildRoundMarkdown(AgenticMessageGroup group) {
    final rows = group.candidates;
    final summary = (group.assistantText).trim().isNotEmpty
        ? group.assistantText.trim()
        : (group.summary ?? '').trim();
    final results = buildSearchResultsMarkdown(rows);
    if (summary.isEmpty) return results;
    return '$results\n\n## Summary\n\n$summary';
  }
}

typedef OnWidgetSizeChange = void Function(Size size);

class _MeasureSize extends SingleChildRenderObjectWidget {
  const _MeasureSize({required this.onChange, required super.child});

  final OnWidgetSizeChange onChange;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _MeasureSizeRenderObject(onChange);
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _MeasureSizeRenderObject).onChange = onChange;
  }
}

class _MeasureSizeRenderObject extends RenderProxyBox {
  _MeasureSizeRenderObject(this.onChange);

  OnWidgetSizeChange onChange;
  Size? _oldSize;

  @override
  void performLayout() {
    super.performLayout();
    final newSize = child?.size;
    if (newSize == null || _oldSize == newSize) return;
    _oldSize = newSize;
    WidgetsBinding.instance.addPostFrameCallback((_) => onChange(newSize));
  }
}

/// 与 TSX DeepSearchWelcome 对齐
class _ToolWelcome extends StatelessWidget {
  const _ToolWelcome({
    required this.activeTool,
    this.analysisPlatform = 'scholar',
    this.citationMode = 'author',
  });

  final String? activeTool;
  final String analysisPlatform;
  final String citationMode;

  static const _advisorWelcomeText =
      "Hi! I'm your **Advisor Matching** assistant 👋\n\n"
      'Describe your ideal advisor below. You\'ll also need to **upload your resume** '
      'and **pick a target region** so I can find the best matches.';

  static const _advisorExamples = [
    'Advisors working on AI safety',
    'Computer vision researchers at top US schools',
    'LLM alignment researchers',
  ];

  static const _citationWelcomeText =
      "Hi! I'm your **Citation Finder** 👋\n\n"
      'Switch between **By Author** and **By Paper** below, then enter what you want to look up.';

  static const _citationExamplesAuthor = [
    'Andrew Ng',
    'Yann LeCun',
    'Geoffrey Hinton',
  ];

  static const _citationExamplesPaper = [
    'Attention Is All You Need',
    'Deep Residual Learning',
    'Word2Vec',
  ];

  static const _analysisWelcomeText =
      "Hi! I'm your **Profile Analyzer** 👋\n\n"
      'Enter a name or paste a **LinkedIn / GitHub / Google Scholar** URL below — '
      "I'll auto-detect the platform and break down what makes them interesting.";

  static const _analysisExamplesScholar = [
    'Andrew Ng',
    'Yann LeCun',
    'Geoffrey Hinton',
  ];

  static const _analysisExamplesGithub = [
    'torvalds',
    'sindresorhus',
    'gaearon',
  ];

  static const _analysisExamplesLinkedin = [
    'Satya Nadella',
    'Reid Hoffman',
    'Jensen Huang',
  ];

  bool get _isWelcomeTool =>
      activeTool == 'find-advisor' ||
      activeTool == 'who-cites-me' ||
      activeTool == 'analysis';

  (String text, List<String> examples) _welcomeContent() {
    switch (activeTool) {
      case 'find-advisor':
        return (_advisorWelcomeText, _advisorExamples);
      case 'who-cites-me':
        return (
          _citationWelcomeText,
          citationMode == 'paper'
              ? _citationExamplesPaper
              : _citationExamplesAuthor,
        );
      case 'analysis':
        switch (analysisPlatform) {
          case 'github':
            return (_analysisWelcomeText, _analysisExamplesGithub);
          case 'linkedin':
            return (_analysisWelcomeText, _analysisExamplesLinkedin);
          default:
            return (_analysisWelcomeText, _analysisExamplesScholar);
        }
      default:
        return ('', const []);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isWelcomeTool) return const SizedBox.shrink();

    final (text, examples) = _welcomeContent();
    final isMobile = MediaQuery.sizeOf(context).width < 768;
    // 移动端浮动 History/Home 按钮：safe-area + 16 + 40(h) + 12(gap)
    final topPadding = isMobile
        ? MediaQuery.paddingOf(context).top + 68.0
        : 48.0;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, topPadding, 16, 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 768),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MarkdownBody(
                data: text,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Color(0xFF4A4845),
                  ),
                  strong: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3A3835),
                  ),
                ),
              ),
              QuickRepliesWidget(
                blockId: 'welcome-examples',
                options: examples,
                ephemeral: true,
                onSelect: context.read<SearchStore>().fillSearchBox,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
