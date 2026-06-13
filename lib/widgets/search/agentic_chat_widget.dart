import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/search_service.dart';
import '../../stores/chat_history_store.dart';
import '../../stores/search_store.dart';
import '../../stores/user_store.dart';
import 'discover_quick_actions_widget.dart';
import 'prompt_template_grid_widget.dart';
import '../../pages/discover/recommended_papers_page.dart';
import 'agentic_search_logic.dart';
import 'message_group_view.dart';
import 'search_box_widget.dart';
import '../../constants/app_constants.dart';

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

class _AgenticChatWidgetState extends State<AgenticChatWidget> {
  // UI 状态
  String _talentMode = 'global'; // 'global' or 'dinq'
  String? _activeTool; // ToolType | null
  bool _isNearBottom = true;

  // 滚动相关
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _messagesEndKey = GlobalKey();

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
    // 监听滚动
    _scrollController.addListener(_handleScroll);
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
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final isNearBottom = position.pixels >= position.maxScrollExtent - 100;
    if (isNearBottom != _isNearBottom) {
      setState(() {
        _isNearBottom = isNearBottom;
      });
    }
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

  void _openPapersPage() {
    Navigator.of(context)
        .push<Object?>(
          MaterialPageRoute<Object?>(
            builder: (_) => const RecommendedPapersPage(),
          ),
        )
        .then((result) {
          // 返回后下一帧再收起焦点，避免 Flutter 焦点恢复后再把键盘带出来
          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                FocusScope.of(context).unfocus();
                FocusManager.instance.primaryFocus?.unfocus();
              }
            });
          }
          if (result != null && result is String) {
            _handleSearch(query: result);
          }
        });
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
    setState(() => _isNearBottom = true);
  }

  Future<void> _handleDinqSearchSubmit(String query) async {
    await _logic?.handleDinqSearch(query);
    setState(() => _isNearBottom = true);
  }

  void _handleAdvisorSearch(AdvisorFormData data) {
    _logic?.handleAdvisorSearch(data);
    setState(() => _isNearBottom = true);
  }

  void _handleStop() => _logic?.handleStop();

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
    return Consumer2<SearchStore, UserStore>(
      builder: (context, searchStore, userStore, _) {
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
            : (user?.user.name.isNotEmpty == true ? user!.user.name : '');

        // 监听 logic 变化，流事件更新 messageGroups 后触发重建，才能渲染返回值
        return ListenableBuilder(
          listenable: logic,
          builder: (context, __) {
            final messageGroups = logic.messageGroups;
            final hasMessages = messageGroups.isNotEmpty;
            final isToolActive =
                (searchStore.activeTool ?? _activeTool) != null;
            final showContentArea = hasMessages || isToolActive;
            final showSkeleton =
                searchStore.isLoadingConversation && !hasMessages;
            final bgColor = (hasMessages || showSkeleton)
                ? Colors.white
                : const Color(0xFFFDFDFD);

            final mq = MediaQuery.of(context);
            // 父级用 Transform.translate 顶起，这里保持一屏高度不压缩
            final contentHeight = mq.size.height;

            return Container(
              color: bgColor,
              height: contentHeight,
              width: double.infinity,
              child: Column(
                children: [
                  // 顶部栏
                  Padding(
                    padding: const EdgeInsets.only(top: 0),
                    child: _buildTopBar(showBackHome: widget.showBackHome),
                  ),
                  // 内容在上，使用 Expanded；点击聊天区域时收起键盘
                  Expanded(
                    child: GestureDetector(
                      onTap: () => FocusScope.of(context).unfocus(),
                      behavior: HitTestBehavior.translucent,
                      child: showSkeleton
                          ? _buildConversationSkeleton()
                          : showContentArea
                          ? _buildMessagesArea(logic)
                          : const SizedBox.shrink(),
                    ),
                  ),
                  // 搜索框和 Prompt 在下；键盘弹起时底部 padding 设为 0
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: ConstantsTool.bottomTabHeight + 32,
                    ),
                    child: _buildBottomSection(
                      userName: userName,
                      logic: logic,
                      searchStore: searchStore,
                      showWelcome: !showContentArea,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildConversationSkeleton() {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // 用户消息骨架 - 右对齐
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                constraints: const BoxConstraints(maxWidth: 280),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: 160,
                      decoration: BoxDecoration(
                        color: const Color(0xFF636363).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 16,
                      width: 96,
                      decoration: BoxDecoration(
                        color: const Color(0xFF636363).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // AI 回复骨架 - 左对齐
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: 256,
                      decoration: BoxDecoration(
                        color: const Color(0xFF636363).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 16,
                      width: 192,
                      decoration: BoxDecoration(
                        color: const Color(0xFF636363).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 16,
                      width: 224,
                      decoration: BoxDecoration(
                        color: const Color(0xFF636363).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesArea(AgenticSearchLogic logic) {
    final groups = logic.messageGroups;
    return PrimaryScrollController(
      controller: _scrollController,
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        interactive: true,
        child: ListView(
          controller: _scrollController,
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          children: [
            for (var i = 0; i < groups.length; i++) ...[
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 768),
                  child: MessageGroupView(
                    key: ValueKey(groups[i].id),
                    group: MessageGroupData(
                      id: groups[i].id,
                      userQuery: groups[i].userQuery,
                      loading: groups[i].loading,
                      candidates: groups[i].candidates,
                      searchType: groups[i].searchType ?? 'global',
                      thinkingSteps: groups[i].thinkingSteps,
                      thinkingExpanded: groups[i].thinkingExpanded,
                      dinqResults: groups[i].dinqResults,
                      advisorResults: groups[i].advisorResults,
                      pdfAttachment: groups[i].pdfAttachment,
                      llmMessage: groups[i].llmMessage,
                      summary: groups[i].summary,
                      assistantText: groups[i].assistantText,
                      assistantStreaming: groups[i].assistantStreaming,
                      quickRepliesUsed: groups[i].quickRepliesUsed,
                      isDeepSearch: groups[i].isDeepSearch,
                      deepSearchToolCount: groups[i].deepSearchToolCount,
                      deepSearchDurationMs: groups[i].deepSearchDurationMs,
                      searchCompleted: groups[i].searchCompleted,
                      subAgents: groups[i].subAgents,
                    ),
                    onToggleThinking: () =>
                        logic.setThinkingExpanded(groups[i].id),
                    onQuickReplySelect: i == groups.length - 1
                        ? (option) {
                            logic.markQuickRepliesUsed(groups[i].id);
                            _handleSearch(query: option);
                          }
                        : null,
                    onCandidateClick: (candidate, index, groupId) {
                      final store = context.read<SearchStore>();
                      final tabId = store.openTabWithClick(
                        candidate,
                        index: index,
                        groupId: groupId,
                        matchByName: true,
                      );
                      if (tabId != null) store.setTabPanelOpen(true);
                    },
                    isLatest: i == groups.length - 1,
                  ),
                ),
              ),
            ],
            Container(key: _messagesEndKey, height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar({required bool showBackHome}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
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
          Row(
            children: [
              TextButton.icon(
                onPressed: _openPapersPage,
                icon: const Icon(
                  Icons.article,
                  size: 20,
                  color: Color.fromARGB(255, 0, 0, 0),
                ),
                label: const Text(
                  'Papers',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color.fromARGB(255, 0, 0, 0),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  foregroundColor: const Color(0xFF6B7280),
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: 跳转升级页
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  foregroundColor: const Color(0xFF6B7280),
                ),
                child: const Text(
                  'Upgrade',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection({
    required String userName,
    required AgenticSearchLogic logic,
    required SearchStore searchStore,
    required bool showWelcome,
  }) {
    final hasMessages = logic.messageGroups.isNotEmpty;
    final deepSearchMode = hasMessages && searchStore.activeTool == null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Welcome 和 Prompt Templates（只在没有消息时显示）
        if (showWelcome) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        userName.isNotEmpty ? 'Welcome,' : 'Welcome',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Color(0xA3303030),
                          letterSpacing: 0.02,
                          fontFamily: 'Editor Note',
                          height: 2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        userName.isNotEmpty ? '$userName' : '',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF171717),
                          letterSpacing: 0.02,
                          fontFamily: 'Editor Note',
                          height: 2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: AnimatedSize(
                    duration: Duration(
                      milliseconds: _activeTool != null ? 200 : 400,
                    ),
                    curve: Curves.easeOut,
                    child: AnimatedOpacity(
                      duration: Duration(
                        milliseconds: _activeTool != null ? 150 : 300,
                      ),
                      opacity: _activeTool != null ? 0.0 : 1.0,
                      child: _activeTool == null
                          ? PromptTemplateGridWidget(
                              onQueryFromPapers: (query) =>
                                  _handleSearch(query: query),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        // 搜索框区域（始终显示）
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!hasMessages && searchStore.activeTool != 'find-advisor')
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 768),
                    child: DiscoverQuickActionsWidget(
                      onFindAdvisor: () {
                        // TODO: 打开 Find Advisor 流程（如与搜索框顾问入口一致）
                      },
                      onSalaryAnalysis: () {
                        // TODO: 打开 Salary Analysis 流程
                      },
                    ),
                  ),
                ),
              if (!hasMessages && searchStore.activeTool != 'find-advisor')
                const SizedBox(height: 16),
              Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 768),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SearchBoxWidget(
                    onSearch: _handleSearch,
                    onStop: _handleStop,
                    loading: logic.loading,
                    talentMode: _talentMode,
                    deepSearchMode: deepSearchMode,
                    onTalentModeChange: (mode) {
                      setState(() {
                        _talentMode = mode;
                      });
                    },
                    onDinqSearchSubmit: _handleDinqSearchSubmit,
                    onAdvisorSearch: _handleAdvisorSearch,
                    advisorLoading: logic.advisorLoading,
                    onActiveToolChange: (tool) {
                      setState(() {
                        _activeTool = tool;
                      });
                    },
                    dropdownPosition: 'up',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
