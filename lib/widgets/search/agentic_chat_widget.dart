import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../constants/app_constants.dart';
import '../../services/search_service.dart';
import '../../stores/chat_history_store.dart';
import '../../stores/quick_replies_store.dart';
import '../../stores/search_store.dart';
import '../../stores/settings_store.dart';
import '../../stores/user_store.dart';
import 'message_group/dinq_logo.dart';
import 'prompt_template_grid_widget.dart';
import 'agentic_search_logic.dart';
import 'search_box/model_channels.dart';
import 'search_box_widget.dart';
import 'search_panel/mobile_results_workspace.dart';
import 'search_panel/result_entry_card.dart';
import 'search_panel_widget.dart';
import 'deep_search/deep_search_models.dart';

class AgenticChatWidget extends StatefulWidget {
  const AgenticChatWidget({
    super.key,
    this.onSearchComplete,
    this.embeddedInMainTab = true,
    this.onEnrichRowClick,
    this.enrichSelectedRowId,
  });

  /// 与 TSX onSearchComplete 一致：搜索完成且有关注人时回调
  final void Function(List<Map<String, dynamic>> candidates, String query)?
  onSearchComplete;
  /// 在 MainTab 内时为 true，单独 /search/:id 页面为 false，不预留底栏高度。
  final bool embeddedInMainTab;
  /// 对齐 Web `onRowClick={enrich.openEnrich}`。
  final void Function(Map<String, dynamic> row)? onEnrichRowClick;
  final String? enrichSelectedRowId;

  @override
  State<AgenticChatWidget> createState() => _AgenticChatWidgetState();
}

class _AgenticChatWidgetState extends State<AgenticChatWidget>
    with SingleTickerProviderStateMixin {
  // UI 状态
  bool _creditsOpen = false;
  CitationMode _citationMode = CitationMode.author;
  String _analysisPlatform = 'scholar';
  final GlobalKey _creditsAnchorKey = GlobalKey();

  // 滚动相关
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _breathingController;

  /// 与 TSX useAgenticSearch 对应，逻辑在 agentic_search_logic.dart
  AgenticSearchLogic? _logic;
  bool _logicInitialized = false;
  int _lastResetVersion = 0;
  String? _lastSyncedToolKey;
  List<ModelOption> _modelOptions = modelOptionsFromResponse(fallbackChannelsResponse);
  bool _modelChannelsLoaded = false;
  bool _mobileResultsOpen = false;
  int? _activeResultsGroupId;

  // bool _initialQueryProcessed = false; // TODO: 实现 URL 参数处理时使用

  // 固定屏幕高度（避免键盘影响布局）
  double? _screenHeight;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _breathingController.repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _screenHeight ??= MediaQuery.of(context).size.height;
    if (!_logicInitialized) {
      _logicInitialized = true;
      _logic = AgenticSearchLogic(
        searchService: SearchService(),
        searchStore: context.read<SearchStore>(),
        resolveUserId: () => context.read<UserStore>().user?.user.id,
        onSearchComplete: widget.onSearchComplete,
        onScrollToBottom: _scrollToBottom,
      );
      _logic!.addListener(_onLogicUpdate);
      _loadModelChannels();
    }
  }

  Future<void> _loadModelChannels() async {
    await ModelChannelsCache.instance.ensureLoaded(
      searchService: SearchService(),
    );
    if (!mounted) return;
    final searchStore = context.read<SearchStore>();
    setState(() {
      _modelOptions = ModelChannelsCache.instance.options;
      _modelChannelsLoaded = true;
    });
    if (searchStore.modelProvider == null) {
      searchStore.setModelProvider(ModelChannelsCache.instance.defaultProvider);
    }
  }

  void _onLogicUpdate() => setState(() {});

  @override
  void dispose() {
    _logic?.removeListener(_onLogicUpdate);
    _logic?.dispose();
    _scrollController.dispose();
    _breathingController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _startFreshDeepSearch({
    required String query,
    String? displayQuery,
    String? attachmentUrl,
    String? attachmentName,
    String? modelProvider,
    bool simple = false,
  }) {
    final searchStore = context.read<SearchStore>();
    final logic = _logic;
    if (logic == null) return;

    final resolvedProvider = modelProvider ??
        searchStore.modelProvider ??
        ModelChannelsCache.instance.defaultProvider;

    final request = PendingDeepSearchRequest(
      query: query,
      displayQuery: displayQuery,
      attachmentUrl: attachmentUrl,
      attachmentName: attachmentName,
      modelProvider: resolvedProvider,
      simple: simple,
    );

    final needsNavigate =
        widget.embeddedInMainTab && searchStore.deepSearchSessionId == null;

    if (needsNavigate) {
      final newSessionId = const Uuid().v4();
      logic.bindSessionId(newSessionId);
      searchStore.setPendingDeepSearch(request);
      context.go('/search/$newSessionId');
      return;
    }

    logic.handleSearch(
      query: query,
      simple: simple,
      displayQuery: displayQuery,
      attachmentUrl: attachmentUrl,
      attachmentName: attachmentName,
      modelProvider: resolvedProvider,
    );
  }

  void _consumePendingDeepSearch(
    SearchStore searchStore,
    AgenticSearchLogic logic,
  ) {
    final pending = searchStore.pendingDeepSearch;
    if (pending == null) return;

    searchStore.clearPendingDeepSearch();

    final sessionId = searchStore.deepSearchSessionId;
    if (sessionId != null && logic.activeSessionId != sessionId) {
      logic.bindSessionId(sessionId);
    }

    logic.handleSearch(
      query: pending.query,
      simple: pending.simple,
      displayQuery: pending.displayQuery,
      attachmentUrl: pending.attachmentUrl,
      attachmentName: pending.attachmentName,
      modelProvider: pending.modelProvider ??
          searchStore.modelProvider ??
          ModelChannelsCache.instance.defaultProvider,
    );
  }

  void _handleDeepSearch(DeepSearchSubmitParams params) {
    _startFreshDeepSearch(
      query: params.query,
      displayQuery: params.displayQuery,
      attachmentUrl: params.attachment,
      attachmentName: params.attachmentName,
      modelProvider: params.modelProvider,
    );
  }

  void _handleCitationSearch(({String query}) params) {
    _logic?.handleCitationSearch(
      query: params.query,
      mode: _citationMode,
    );
  }

  void _handleAnalysisSearch(AnalysisSearchParams params) {
    _logic?.handleAnalysisSearch(
      platform: params.platform,
      query: params.query,
      candidateData: params.candidateData,
    );
  }

  void _handleAdvisorSearch(AdvisorFormData data) {
    _logic?.handleAdvisorSearch(data);
  }

  void _handleStop() => _logic?.handleStop();

  static const Map<String, String> _toolRouteByTool = {
    'find-advisor': 'advisor',
    'who-cites-me': 'citation',
    'analysis': 'analyze',
  };

  static const Map<String, String> _toolByRoute = {
    'advisor': 'find-advisor',
    'citation': 'who-cites-me',
    'analyze': 'analysis',
  };

  String? _routeToolFromPath(BuildContext context) {
    final segments = GoRouterState.of(context).uri.pathSegments;
    if (segments.length < 2 || segments.first != 'search') return null;
    return _toolByRoute[segments[1]];
  }

  /// 仅 /search/advisor|citation|analyze（无会话 id）
  bool _isToolRoute(BuildContext context) {
    final segments = GoRouterState.of(context).uri.pathSegments;
    return segments.length == 2 &&
        segments.first == 'search' &&
        _toolByRoute.containsKey(segments[1]);
  }

  void _clearQuickRepliesStore() {
    if (!mounted) return;
    context.read<QuickRepliesStore>().clear();
  }

  void _syncQuickRepliesStoreFromLogic(AgenticSearchLogic logic) {
    if (!mounted) return;
    final store = context.read<QuickRepliesStore>();
    // 与 Web quickRepliesStore 一致：reload 后 usedIds 从空开始，
    // 仅同步「已实际消费」的 block（后续轮次 / 已跑搜索 / 用户点过选项）。
    store.clear();
    for (final group in logic.messageGroups) {
      store.markAllUsed(group.usedQuickReplyBlockIds);
    }
  }

  void _syncToolWithRoute(SearchStore searchStore, AgenticSearchLogic logic) {
    final segments = GoRouterState.of(context).uri.pathSegments;
    final routeTool = _routeToolFromPath(context);

    if (routeTool != null) {
      final key = 'tool-$routeTool';
      if (_lastSyncedToolKey == key && searchStore.activeTool == routeTool) {
        return;
      }
      logic.handleStop();
      logic.clearMessages();
      _clearQuickRepliesStore();
      logic.clearAnalysisCandidates();
      searchStore.setActiveTool(routeTool);
      _lastSyncedToolKey = key;
      return;
    }

    // 仅 bare /search（非 /search/:id 会话页）
    if (segments.length == 1 && segments.first == 'search') {
      const key = 'deep-search';
      if (_lastSyncedToolKey == key && searchStore.activeTool == null) {
        return;
      }
      logic.handleStop();
      logic.clearMessages();
      _clearQuickRepliesStore();
      logic.clearAnalysisCandidates();
      searchStore.clearActiveTool();
      _lastSyncedToolKey = key;
    }
  }

  void _handleActiveToolChange(SearchStore searchStore, String? tool) {
    if (tool == null) {
      if (_isToolRoute(context)) context.go('/search');
      return;
    }

    final segment = _toolRouteByTool[tool];
    if (segment == null) return;

    final nextPath = '/search/$segment';
    if (GoRouterState.of(context).uri.path != nextPath) {
      context.go(nextPath);
    }
  }

  // 处理候选人点击
  // void _handleCandidateClick(Map<String, dynamic> candidate, int index, int groupId) {
  //   // TODO: 实现 openTab 逻辑
  //   // final searchStore = context.read<SearchStore>();
  //   // searchStore.openTabWithClick(candidate, index: index, groupId: groupId);
  // }

  @override
  Widget build(BuildContext context) {
    final logic = _logic;
    if (logic == null) return const SizedBox.shrink();
    return Consumer3<SearchStore, UserStore, SettingsStore>(
      builder: (context, searchStore, userStore, settingsStore, _) {
        _syncToolWithRoute(searchStore, logic);
        if (!mounted) return const SizedBox.shrink();
        if (searchStore.resetVersion != _lastResetVersion) {
          _lastResetVersion = searchStore.resetVersion;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              logic.clearMessages();
              _clearQuickRepliesStore();
              _lastSyncedToolKey = searchStore.activeTool != null
                  ? 'tool-${searchStore.activeTool}'
                  : 'deep-search';
            }
          });
        }
        if (searchStore.pendingConversation != null) {
          final pending = searchStore.pendingConversation!;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            logic.loadFromConversation(pending);
            _syncQuickRepliesStoreFromLogic(logic);
            searchStore.clearPendingConversation();
            _lastSyncedToolKey = searchStore.activeTool != null
                ? 'tool-${searchStore.activeTool}'
                : 'deep-search';
          });
        }
        if (searchStore.pendingDeepSearch != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            final store = context.read<SearchStore>();
            if (store.pendingDeepSearch == null) return;
            _consumePendingDeepSearch(store, logic);
          });
        }
        if (searchStore.isLoadingConversation &&
            logic.messageGroups.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            logic.clearMessagesOnly();
          });
        }
        final user = userStore.user;
        final userName = user?.userData.name.isNotEmpty == true
            ? user!.userData.name
            : (user?.user.name.isNotEmpty == true ? user!.user.name : 'DINQer');
        final creditsBalance = userStore.subscription?.creditsBalance ?? 0;
        final planLabel = userStore.subscription?.basePlan ?? 'free';
        final isMobile = settingsStore.isMobile;

        return ListenableBuilder(
          listenable: logic,
          builder: (context, child) {
            final messageGroups = logic.messageGroups;
            final hasDeepSearchContent = messageGroups.isNotEmpty;
            final isToolActive = searchStore.activeTool != null;
            final showRestoring =
                searchStore.isLoadingConversation && messageGroups.isEmpty;
            final showChatContent = hasDeepSearchContent || isToolActive;
            final path = GoRouterState.of(context).uri.path;
            final showBackHome =
                !widget.embeddedInMainTab || searchStore.activeTool != null;

            final searchBox = _buildSearchBox(
              logic: logic,
              searchStore: searchStore,
              isMobile: isMobile,
            );

            final canUseMobileResults =
                isMobile && !isToolActive && messageGroups.isNotEmpty;
            if (!canUseMobileResults && _mobileResultsOpen) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() => _mobileResultsOpen = false);
              });
            }

            AgenticMessageGroup? mobileResultsGroup;
            if (_activeResultsGroupId != null) {
              for (final group in messageGroups) {
                if (group.id == _activeResultsGroupId) {
                  mobileResultsGroup = group;
                  break;
                }
              }
            }
            mobileResultsGroup ??= () {
              for (final group in messageGroups.reversed) {
                if (group.toolType == null &&
                    groupHasResultWorkspace(
                      group,
                      isSearching: groupRoundStatus(group) ==
                          DeepSearchRoundStatus.searching,
                    )) {
                  return group;
                }
              }
              return null;
            }();

            final activeMobileResultsGroup = mobileResultsGroup;
            final showMobileResultsWorkspace = canUseMobileResults &&
                _mobileResultsOpen &&
                activeMobileResultsGroup != null;
            final mobileResultsStatus = activeMobileResultsGroup == null
                ? DeepSearchRoundStatus.idle
                : groupRoundStatus(activeMobileResultsGroup);

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  color: const Color(0xFFFAF9F6),
                  width: double.infinity,
                  child: Column(
                    children: [
                      Expanded(
                        child: showRestoring
                            ? Center(
                                child: BreathingLogo(
                                  size: 28,
                                  animation: _breathingController,
                                ),
                              )
                            : showChatContent
                                ? Column(
                                    children: [
                                      Expanded(
                                        child: SearchPanelWidget(
                                          messageGroups: messageGroups,
                                          scrollController: _scrollController,
                                          activeTool: searchStore.activeTool,
                                          hideUserQueryBubble: false,
                                          selectedRowId: widget.enrichSelectedRowId,
                                          onQuickReplySelect: (option, blockId) {
                                            _handleDeepSearch(
                                              DeepSearchSubmitParams(
                                                query: option,
                                                displayQuery: option,
                                              ),
                                            );
                                          },
                                          onConfirmStart:
                                              (query, displayQuery, blockId) {
                                            _startFreshDeepSearch(
                                              query: query,
                                              displayQuery: displayQuery,
                                            );
                                          },
                                          onCandidateClick: (
                                            candidate,
                                            index,
                                            groupId,
                                          ) {
                                            if (widget.onEnrichRowClick != null) {
                                              widget.onEnrichRowClick!(candidate);
                                              return;
                                            }
                                            final tabId = searchStore.openTabWithClick(
                                              candidate,
                                              index: index,
                                              groupId: groupId,
                                              matchByName: true,
                                            );
                                            if (tabId != null) {
                                              searchStore.setTabPanelOpen(true);
                                            }
                                          },
                                          onAdvisorShuffle: logic.shuffleAdvisors,
                                          advisorShuffleLoading:
                                              logic.advisorShuffleLoading,
                                          bottomInset: widget.embeddedInMainTab ? 20 : 12,
                                          analysisPlatform: _analysisPlatform,
                                          citationMode: _citationMode.name,
                                          showInlineResults: !isMobile,
                                          resultEntryMode: isMobile
                                              ? ResultEntryMode.mobile
                                              : ResultEntryMode.desktop,
                                          activeResultsRoundId:
                                              _activeResultsGroupId,
                                          onOpenResultsRound: isMobile
                                              ? (roundId) {
                                                  setState(() {
                                                    _activeResultsGroupId =
                                                        roundId;
                                                    _mobileResultsOpen = true;
                                                  });
                                                }
                                              : null,
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.fromLTRB(
                                          isMobile ? 12 : 24,
                                          0,
                                          isMobile ? 12 : 24,
                                          isMobile
                                              ? _mobileBottomBarInset(context)
                                              : 12,
                                        ),
                                        child: Center(
                                          child: ConstrainedBox(
                                            constraints: const BoxConstraints(maxWidth: 768),
                                            child: searchBox,
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : isMobile
                                    ? _buildMobileWelcome(
                                        userName: userName,
                                        searchBox: searchBox,
                                      )
                                    : _buildDesktopWelcome(
                                        userName: userName,
                                        searchBox: searchBox,
                                      ),
                      ),
                    ],
                  ),
                ),
                if (isMobile)
                  Positioned(
                    top: MediaQuery.paddingOf(context).top + 16,
                    left: 16,
                    child: _buildHistoryButton(),
                  ),
                if (isMobile && showBackHome)
                  Positioned(
                    top: MediaQuery.paddingOf(context).top + 16,
                    right: 16,
                    child: _buildBackHomeButton(),
                  ),
                if (!isMobile)
                  Positioned(
                    top: 12,
                    right: 14,
                    child: _buildCreditsButton(
                      creditsBalance: creditsBalance,
                      planLabel: planLabel,
                      path: path,
                    ),
                  ),
                if (showMobileResultsWorkspace)
                  Positioned.fill(
                    child: MobileResultsWorkspace(
                      candidates: activeMobileResultsGroup.candidates,
                      isSearching: mobileResultsStatus ==
                          DeepSearchRoundStatus.searching,
                      isInterrupted: mobileResultsStatus ==
                          DeepSearchRoundStatus.interrupted,
                      selectedRowId: widget.enrichSelectedRowId,
                      roundStatus: mobileResultsStatus,
                      contentBlocks: activeMobileResultsGroup.contentBlocks,
                      subAgents: activeMobileResultsGroup.subAgents,
                      sessionId: searchStore.deepSearchSessionId,
                      sseEventsId: activeMobileResultsGroup.sseEventsId,
                      onClose: () => setState(() => _mobileResultsOpen = false),
                      onRowClick: (row) {
                        if (widget.onEnrichRowClick != null) {
                          widget.onEnrichRowClick!(row);
                          return;
                        }
                        final idx = activeMobileResultsGroup.candidates.indexWhere(
                          (c) =>
                              c['row_id']?.toString() ==
                                  row['row_id']?.toString() ||
                              c['name'] == row['name'],
                        );
                        final tabId = searchStore.openTabWithClick(
                          row,
                          index: idx >= 0 ? idx : 0,
                          groupId: activeMobileResultsGroup.id,
                          matchByName: true,
                        );
                        if (tabId != null) {
                          searchStore.setTabPanelOpen(true);
                        }
                      },
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  static const Color _chromeForeground = Color(0xFF2A2826);
  static const List<BoxShadow> _chromeShadow = [
    BoxShadow(
      color: Color.fromRGBO(42, 40, 38, 0.07),
      blurRadius: 18,
      offset: Offset(0, 8),
    ),
  ];

  /// 与 TSX MobileSearchHistoryButton / MobileSearchBackHomeButton 一致的玻璃态浮层按钮。
  Widget _mobileChromeButton({
    required Widget child,
    required VoidCallback onPressed,
    EdgeInsetsGeometry? padding,
    double? width,
    double height = 40,
    String? tooltip,
  }) {
    final borderRadius = BorderRadius.circular(999);
    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: borderRadius,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            boxShadow: _chromeShadow,
          ),
          child: ClipRRect(
            borderRadius: borderRadius,
            child: Stack(
              children: [
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: const ColoredBox(color: Colors.transparent),
                  ),
                ),
                Container(
                  width: width,
                  height: height,
                  padding: padding,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: borderRadius,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: child,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (tooltip == null) return button;

    return Tooltip(
      message: tooltip,
      preferBelow: false,
      child: button,
    );
  }

  Widget _buildHistoryButton() {
    return _mobileChromeButton(
      width: 40,
      tooltip: 'Open history',
      onPressed: () {
        context.read<ChatHistoryStore>().setMobileOpen(true);
      },
      child: SvgPicture.asset(
        'assets/icons/search/history.svg',
        width: 20,
        height: 20,
        colorFilter: const ColorFilter.mode(
          _chromeForeground,
          BlendMode.srcIn,
        ),
      ),
    );
  }

  Widget _buildBackHomeButton() {
    return _mobileChromeButton(
      tooltip: 'Home',
      padding: const EdgeInsets.symmetric(horizontal: 14),
      onPressed: () {
        context.read<SearchStore>().clearAll();
        context.go('/search');
      },
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.home_outlined, size: 16, color: _chromeForeground),
          SizedBox(width: 6),
          Text(
            'Home',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _chromeForeground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox({
    required AgenticSearchLogic logic,
    required SearchStore searchStore,
    required bool isMobile,
  }) {
    return SearchBoxWidget(
      activeTool: searchStore.activeTool,
      onActiveToolChange: (tool) => _handleActiveToolChange(searchStore, tool),
      onDeepSearch: _handleDeepSearch,
      onDeepSearchStop: _handleStop,
      deepSearchLoading: logic.loading,
      modelOptions: _modelChannelsLoaded ? _modelOptions : null,
      modelProvider: searchStore.modelProvider ??
          ModelChannelsCache.instance.defaultProvider,
      onModelProviderChange: searchStore.setModelProvider,
      onAdvisorSearch: _handleAdvisorSearch,
      advisorLoading: logic.advisorLoading,
      onCitationSearch: _handleCitationSearch,
      citationLoading: logic.citationLoading,
      citationMode: _citationMode,
      onCitationModeChange: (mode) => setState(() => _citationMode = mode),
      onAnalysisSearch: _handleAnalysisSearch,
      analysisLoading: logic.analysisLoading,
      analysisCandidates: logic.analysisCandidates,
      onClearAnalysisCandidates: logic.clearAnalysisCandidates,
      analysisPlatform: _analysisPlatform,
      onAnalysisPlatformChange: (platform) =>
          setState(() => _analysisPlatform = platform),
      confirmToolSwitch: logic.messageGroups.isNotEmpty,
      dropdownPosition: 'up',
      variant: 'glass',
      fullWidth: true,
      isMobile: isMobile,
    );
  }

  /// 为 MainTab 浮动底栏预留空间（与 main_tab_bottom_view 高度一致）。
  double _mobileBottomBarInset(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    if (!widget.embeddedInMainTab) {
      return math.max(12, safeBottom);
    }
    return ConstantsTool.bottomTabHeight +
        math.max(26, safeBottom) +
        12;
  }

  Widget _buildMobileWelcome({
    required String userName,
    required Widget searchBox,
  }) {
    final bottomInset = _mobileBottomBarInset(context);

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SvgPicture.asset(
                            'assets/logo/dinq-black.svg',
                            width: 22,
                            height: 22,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                text: 'Welcome, ',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontFamily: 'Editor Note',
                                  color: Color(0xFF6B6862),
                                  fontWeight: FontWeight.w400,
                                  height: 1.1,
                                ),
                                children: [
                                  TextSpan(
                                    text: userName,
                                    style: const TextStyle(
                                      color: Color(0xFF171717),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const PromptTemplateGridWidget(),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset),
          child: searchBox,
        ),
      ],
    );
  }

  Widget _buildDesktopWelcome({
    required String userName,
    required Widget searchBox,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 768),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset('assets/logo/dinq-black.svg', width: 24, height: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Welcome, $userName',
                    style: const TextStyle(
                      fontSize: 38,
                      height: 1.2,
                      fontFamily: 'Editor Note',
                      color: Color(0xFF171717),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              searchBox,
              const SizedBox(height: 16),
              const PromptTemplateGridWidget(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreditsButton({
    required int creditsBalance,
    required String planLabel,
    required String path,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        TextButton.icon(
          key: _creditsAnchorKey,
          onPressed: () => setState(() => _creditsOpen = !_creditsOpen),
          icon: const Icon(Icons.auto_awesome, size: 16, color: Color(0xFF171717)),
          label: Text(
            creditsBalance.toString(),
            style: const TextStyle(
              color: Color(0xFF171717),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          style: TextButton.styleFrom(
            backgroundColor: Colors.white.withAlpha(220),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
              side: const BorderSide(color: Color(0xFFE8E4DF)),
            ),
          ),
        ),
        if (_creditsOpen)
          Positioned(
            top: 42,
            right: 0,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              elevation: 6,
              child: Container(
                width: 248,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEAE8E3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            planLabel,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF171717),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() => _creditsOpen = false);
                            context.go('/settings/subscription');
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFF1C1B1A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          child: const Text('Upgrade'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F4F0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Available Credits',
                              style: TextStyle(fontSize: 13, color: Color(0xFF8A8880)),
                            ),
                          ),
                          Text(
                            creditsBalance.toString(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF171717),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        setState(() => _creditsOpen = false);
                        context.go('/settings/subscription');
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                      ),
                      child: const Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Usage details',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF8A8880),
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: Color(0xFF8A8880),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      path,
                      style: const TextStyle(fontSize: 10, color: Color(0xFFB7B3AB)),
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
