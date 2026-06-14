import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/search_service.dart';
import '../../stores/chat_history_store.dart';
import '../../stores/search_store.dart';
import '../../stores/settings_store.dart';
import '../../stores/user_store.dart';
import 'message_group/dinq_logo.dart';
import 'prompt_template_grid_widget.dart';
import 'agentic_search_logic.dart';
import 'search_box_widget.dart';
import 'search_panel_widget.dart';

// Placeholder 常量（与 React 版本一致）
const List<String> globalPlaceholders = [
  'Search millions of AI talents worldwide…',
  'Find my Alec Radford',
  'Find my Jianlin Su',
  'Find my Ilya Sutskever',
  'Find my Sam Gao',
];

const List<String> dinqPlaceholders = [
  'Search verified experts on DINQ Fellows…',
  'Find my Alec Radford',
  'Find my Jianlin Su',
  'Find my Ilya Sutskever',
  'Find my Sam Gao',
];

class AgenticChatWidget extends StatefulWidget {
  const AgenticChatWidget({super.key, this.onSearchComplete, this.showBackHome = false});

  /// 与 TSX onSearchComplete 一致：搜索完成且有关注人时回调
  final void Function(List<Map<String, dynamic>> candidates, String query)?
  onSearchComplete;
  final bool showBackHome;

  @override
  State<AgenticChatWidget> createState() => _AgenticChatWidgetState();
}

class _AgenticChatWidgetState extends State<AgenticChatWidget>
    with SingleTickerProviderStateMixin {
  // UI 状态
  String _talentMode = 'global'; // 'global' or 'dinq'
  bool _creditsOpen = false;
  final GlobalKey _creditsAnchorKey = GlobalKey();

  // 滚动相关
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _breathingController;

  /// 与 TSX useAgenticSearch 对应，逻辑在 agentic_search_logic.dart
  AgenticSearchLogic? _logic;
  bool _logicInitialized = false;
  int _lastResetVersion = 0;

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
        onSearchComplete: widget.onSearchComplete,
        onScrollToBottom: _scrollToBottom,
      );
      _logic!.addListener(_onLogicUpdate);
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

  void _handleSearch({
    required String query,
    bool simple = false,
    String? attachmentUrl,
    String? attachmentName,
  }) {
    _logic?.handleSearch(
      query: query,
      simple: simple,
      attachmentUrl: attachmentUrl,
      attachmentName: attachmentName,
    );
  }

  Future<void> _handleDinqSearchSubmit(String query) async {
    await _logic?.handleDinqSearch(query);
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
    if (segments.length != 2 || segments.first != 'search') return null;
    return _toolByRoute[segments[1]];
  }

  bool _isToolRoute(BuildContext context) => _routeToolFromPath(context) != null;

  void _syncToolWithRoute(SearchStore searchStore) {
    final routeTool = _routeToolFromPath(context);
    if (routeTool == searchStore.activeTool) return;
    if (routeTool != null) {
      searchStore.setActiveTool(routeTool);
      return;
    }
    if (searchStore.activeTool != null && !_isToolRoute(context)) {
      searchStore.clearActiveTool();
    }
  }

  void _handleActiveToolChange(SearchStore searchStore, String? tool) {
    final currentTool = searchStore.activeTool;
    if (currentTool == tool) return;
    if (tool == null) {
      searchStore.clearActiveTool();
      if (_isToolRoute(context)) context.go('/search');
      return;
    }
    searchStore.setActiveTool(tool);
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
        _syncToolWithRoute(searchStore);
        if (!mounted) return const SizedBox.shrink();
        if (searchStore.resetVersion != _lastResetVersion) {
          _lastResetVersion = searchStore.resetVersion;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) logic.clearMessages();
          });
        }
        if (searchStore.pendingConversation != null) {
          final pending = searchStore.pendingConversation!;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            logic.loadFromConversation(pending);
            searchStore.clearPendingConversation();
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
            final showMobileHeader = isMobile;

            final searchBox = _buildSearchBox(
              logic: logic,
              searchStore: searchStore,
              deepSearchMode: hasDeepSearchContent && searchStore.activeTool == null,
            );

            return Stack(
              children: [
                Container(
                  color: const Color(0xFFF8F7F3),
                  width: double.infinity,
                  child: Column(
                    children: [
                      if (showMobileHeader)
                        _buildTopBar(showBackHome: widget.showBackHome),
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
                                          onQuickReplySelect: (option) {
                                            logic.markQuickRepliesUsed(
                                              messageGroups.last.id,
                                            );
                                            _handleSearch(query: option);
                                          },
                                          onCandidateClick: (
                                            candidate,
                                            index,
                                            groupId,
                                          ) {
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
                                          bottomInset: 20,
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.fromLTRB(
                                          isMobile ? 12 : 24,
                                          0,
                                          isMobile ? 12 : 24,
                                          12,
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
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTopBar({required bool showBackHome}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 0, 6, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (showBackHome)
                TextButton.icon(
                  onPressed: () {
                    context.read<SearchStore>().clearAll();
                    context.go('/search');
                  },
                  icon: const Icon(Icons.arrow_back, size: 20, color: Colors.black),
                  label: const Text(
                    '',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color.fromARGB(255, 0, 0, 0),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    foregroundColor: const Color(0xFF6B7280),
                  ),
                ),
              TextButton.icon(
                onPressed: () {
                  context.read<ChatHistoryStore>().setMobileOpen(true);
                },
                icon: Image.asset(
                  'assets/icons/discover/history.png',
                  width: 20,
                  height: 20,
                ),
                label: const Text(
                  '',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color.fromARGB(255, 0, 0, 0),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  foregroundColor: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox({
    required AgenticSearchLogic logic,
    required SearchStore searchStore,
    required bool deepSearchMode,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SearchBoxWidget(
        onSearch: _handleSearch,
        onStop: _handleStop,
        loading: logic.loading,
        talentMode: _talentMode,
        deepSearchMode: deepSearchMode,
        onTalentModeChange: (mode) {
          setState(() => _talentMode = mode);
        },
        onDinqSearchSubmit: _handleDinqSearchSubmit,
        onAdvisorSearch: _handleAdvisorSearch,
        advisorLoading: logic.advisorLoading,
        onActiveToolChange: (tool) => _handleActiveToolChange(searchStore, tool),
        dropdownPosition: 'up',
      ),
    );
  }

  Widget _buildMobileWelcome({
    required String userName,
    required Widget searchBox,
  }) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const SizedBox(height: 56),
                Row(
                  children: [
                    SvgPicture.asset('assets/logo/dinq-black.svg', width: 22, height: 22),
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
                const Spacer(),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: searchBox,
          ),
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
