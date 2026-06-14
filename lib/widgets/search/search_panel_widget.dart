import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';

import 'agentic_search_logic.dart';
import 'deep_search/deep_search_models.dart';
import 'deep_search/deep_search_results_helpers.dart';
import 'search_panel/round_section.dart';

class SearchPanelWidget extends StatefulWidget {
  const SearchPanelWidget({
    super.key,
    required this.messageGroups,
    required this.scrollController,
    required this.activeTool,
    required this.onQuickReplySelect,
    required this.onCandidateClick,
    this.bottomInset = 24,
    this.hideUserQueryBubble = false,
    this.onAdvisorShuffle,
    this.advisorShuffleLoading,
    this.analysisPlatform,
    this.citationMode,
  });

  final List<AgenticMessageGroup> messageGroups;
  final ScrollController scrollController;
  final String? activeTool;
  final ValueChanged<String> onQuickReplySelect;
  final void Function(Map<String, dynamic> candidate, int index, int groupId)
  onCandidateClick;
  final double bottomInset;
  final bool hideUserQueryBubble;
  final VoidCallback? onAdvisorShuffle;
  final bool? advisorShuffleLoading;
  final String? analysisPlatform;
  final String? citationMode;

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
    if (!widget.scrollController.hasClients || widget.messageGroups.isEmpty) return;

    final expanded = _viewportHeight > 0
        ? _viewportHeight
        : widget.scrollController.position.viewportDimension;
    if ((expanded - _spacerHeight).abs() > 2) {
      setState(() => _spacerHeight = expanded);
    }

    final lastRoundId = widget.messageGroups.last.id;
    final targetKey = _roundKeys[lastRoundId];
    final targetBox = targetKey?.currentContext?.findRenderObject() as RenderBox?;
    final listBox = _listViewKey.currentContext?.findRenderObject() as RenderBox?;
    if (targetBox == null || listBox == null) return;

    final topInViewport = targetBox.localToGlobal(
      Offset.zero,
      ancestor: listBox,
    ).dy;
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
    if (!widget.scrollController.hasClients || widget.messageGroups.isEmpty) return;
    if (_isUserScrolled || _isProgrammaticScroll) return;

    final last = widget.messageGroups.last;
    final isToolRound = last.searchType == 'advisor' || last.searchType == 'dinq';
    if (isToolRound) return;
    if (!_isStreaming(last)) return;

    if (_lastRoundHeight < _viewportHeight * 0.8) return;

    widget.scrollController.jumpTo(widget.scrollController.position.maxScrollExtent);
  }

  bool _isStreaming(AgenticMessageGroup group) {
    if (group.loading || group.assistantStreaming) return true;
    return group.subAgents.values.any((agent) =>
        agent.status == DeepSearchRoundStatus.searching ||
        agent.contentBlocks.any((block) =>
            block is ThinkingPart && block.block.isStreaming ||
            block is ToolCallPart &&
                block.block.status == ToolCallStatus.running));
  }

  void _recalcSpacer() {
    if (!mounted) return;
    final minSpacer = widget.bottomInset;
    final computed = (_viewportHeight - _lastRoundHeight).clamp(minSpacer, 2000.0);
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

        return Stack(
          children: [
            if (groups.isEmpty)
              _ToolWelcome(activeTool: widget.activeTool)
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
                            onQuickReplySelect:
                                i == groups.length - 1 ? widget.onQuickReplySelect : null,
                            onCandidateClick: widget.onCandidateClick,
                            copied: _copiedRoundId == groups[i].id,
                            onCopyMarkdown: () => _copyRoundMarkdown(groups[i]),
                            onAdvisorShuffle: widget.onAdvisorShuffle,
                            advisorShuffleLoading:
                                widget.advisorShuffleLoading ?? false,
                          ),
                        ),
                      ),
                    ),
                    if (i != groups.length - 1) const SizedBox(height: 10),
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
  const _MeasureSize({
    required this.onChange,
    required super.child,
  });

  final OnWidgetSizeChange onChange;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _MeasureSizeRenderObject(onChange);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderObject renderObject,
  ) {
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

class _ToolWelcome extends StatelessWidget {
  const _ToolWelcome({required this.activeTool});

  final String? activeTool;

  static const _title = <String, String>{
    'find-advisor': 'Find Advisors',
    'who-cites-me': 'Who Cites Me',
    'analysis': 'Post Analysis',
  };

  static const _subtitle = <String, String>{
    'find-advisor': 'Upload a resume and add context to discover suitable advisors.',
    'who-cites-me': 'Track who cited your work and get citation insights quickly.',
    'analysis': 'Analyze post performance and audience engagement patterns.',
  };

  static const _examples = <String, List<String>>{
    'find-advisor': [
      'Find advisors with strong startup GTM background',
      'Match advisors for AI infra product strategy',
    ],
    'who-cites-me': [
      'Who cited my NeurIPS 2023 paper?',
      'Find recent citations by top universities',
    ],
    'analysis': [
      'Analyze this post for conversion potential',
      'Which audience segment engaged the most?',
    ],
  };

  @override
  Widget build(BuildContext context) {
    final tool = activeTool ?? '';
    final title = _title[tool] ?? 'Deep Search';
    final subtitle =
        _subtitle[tool] ?? 'Search and reason across candidates and public profiles.';
    final examples = _examples[tool] ?? const ['Find AI researchers in NLP'];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 38, 16, 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 768),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  color: Color(0xFF171717),
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B6862),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              for (final text in examples)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE6E1DA)),
                  ),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFF6B6862),
                    ),
                  ),
                ),
              if (activeTool == null || activeTool == 'deep-search') ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    SvgPicture.asset('assets/logo/dinq-black.svg', width: 16, height: 16),
                    const SizedBox(width: 6),
                    const Text(
                      'Start with a prompt below',
                      style: TextStyle(fontSize: 12, color: Color(0xFF9E9B93)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
