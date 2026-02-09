import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../services/discover_service.dart';
import '../../stores/search_store.dart';
import '../../stores/user_store.dart';
import 'prompt_template_grid_widget.dart';
import '../../pages/discover/chat_history_page.dart';
import 'agentic_search_logic.dart';
import 'message_group_view.dart';
import 'recommended_papers_widget.dart';
import 'search_box_widget.dart';

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
  const AgenticChatWidget({
    super.key,
    this.onSearchComplete,
  });

  /// 与 TSX onSearchComplete 一致：搜索完成且有关注人时回调
  final void Function(List<Map<String, dynamic>> candidates, String query)? onSearchComplete;

  @override
  State<AgenticChatWidget> createState() => _AgenticChatWidgetState();
}

class _AgenticChatWidgetState extends State<AgenticChatWidget> {
  // UI 状态
  String _talentMode = 'global'; // 'global' or 'dinq'
  String? _activeTool; // ToolType | null
  bool _isNearBottom = true;
  bool _inPapersView = false;

  // 滚动相关
  final ScrollController _scrollController = ScrollController();
  final ScrollController _initialScrollController = ScrollController();
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
    _initialScrollController.addListener(_handleInitialScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _screenHeight ??= MediaQuery.of(context).size.height;
    if (!_logicInitialized) {
      _logicInitialized = true;
      _logic = AgenticSearchLogic(
        discoverService: DiscoverService(),
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
    _initialScrollController.dispose();
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

  void _handleInitialScroll() {
    if (!_initialScrollController.hasClients) return;
    final position = _initialScrollController.position;
    final scrollRatio = position.pixels / position.viewportDimension;
    final inPapersView = scrollRatio > 0.4;
    if (inPapersView != _inPapersView) {
      setState(() {
        _inPapersView = inPapersView;
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

  // void _scrollToPapers() {
  //   // TODO: 实现滚动到 Papers 页面
  //   if (_initialScrollController.hasClients) {
  //     _initialScrollController.animateTo(
  //       _initialScrollController.position.viewportDimension * 0.7,
  //       duration: const Duration(milliseconds: 300),
  //       curve: Curves.easeOut,
  //     );
  //   }
  // }

  void _scrollToSearch() {
    if (_initialScrollController.hasClients) {
      _initialScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleSearch({required String query, bool simple = false}) {
    _logic?.handleSearch(query: query, simple: simple);
    setState(() => _isNearBottom = true);
  }

  Future<void> _handleDinqSearchSubmit(String query) async {
    await _logic?.handleDinqSearch(query);
    setState(() => _isNearBottom = true);
  }

  void _handleAdvisorSearch(AdvisorFormData data) {
    _logic?.handleAdvisorSearch();
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
    final messageGroups = logic.messageGroups;
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
        if (searchStore.isLoadingConversation && logic.messageGroups.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            logic.clearMessagesOnly();
          });
        }
        final user = userStore.user;
        final userName = user?.userData.name.isNotEmpty == true
            ? user!.userData.name
            : (user?.user.name.isNotEmpty == true ? user!.user.name : '');

        final hasMessages = messageGroups.isNotEmpty;
        final showSkeleton = searchStore.isLoadingConversation && !hasMessages;
        final bgColor = (hasMessages || showSkeleton)
            ? Colors.white
            : const Color(0xFFFDFDFD);

        // 获取固定屏幕高度（不受键盘影响），仅移动端样式，headerHeight 固定为 0
        final screenHeight =
            _screenHeight ?? MediaQuery.of(context).size.height;
        const headerHeight = 0.0;
        final availableHeight = screenHeight - headerHeight;

        final parentQuery = MediaQuery.of(context);
        final mediaQueryWithoutInsets = parentQuery.copyWith(
          viewInsets: EdgeInsets.zero,
          padding: parentQuery.padding,
          size: Size(parentQuery.size.width, screenHeight),
        );

        return MediaQuery(
          data: mediaQueryWithoutInsets,
          child: Container(
            color: bgColor,
            height: availableHeight,
            width: double.infinity,
            child: Column(
              children: [
                // 骨架屏 - 加载历史会话时显示
                if (showSkeleton) Expanded(child: _buildConversationSkeleton()),

                // 消息滚动区域
                if (hasMessages && !showSkeleton)
                  Expanded(child: _buildMessagesArea(logic)),

                // 初始状态 - 双页 snap 滚动
                if (!hasMessages && !showSkeleton)
                  Expanded(
                    child: _buildInitialState(userName, logic, userId: user?.user.id),
                  ),

                // SearchBox - 在有消息或骨架屏时固定底部
                if (hasMessages || showSkeleton) _buildBottomSearchBox(logic),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildConversationSkeleton() {
    return SingleChildScrollView(
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
    return Stack(
      children: [
        SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < groups.length; i++) ...[
                MessageGroupView(
                  key: ValueKey(groups[i].id),
                  group: MessageGroupData(
                    id: groups[i].id,
                    userQuery: groups[i].userQuery,
                    loading: groups[i].loading,
                    candidates: groups[i].candidates,
                  ),
                  isLatest: i == groups.length - 1,
                ),
              ],
              Container(
                key: _messagesEndKey,
                height: 80,
              ),
            ],
          ),
        ),
        // 底部渐变
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 72,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.white,
                  Colors.white.withOpacity(0.7),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInitialState(String userName, AgenticSearchLogic logic, {String? userId}) {
    return SingleChildScrollView(
      controller: _initialScrollController,
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // Section 1: 搜索页
          SizedBox(
            height: _screenHeight != null
                ? _screenHeight! * 0.8
                : MediaQuery.of(context).size.height * 0.8,
            child: Column(
              children: [
                // 顶部：左上 History，右上 Upgrade
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).push<Object?>(
                            MaterialPageRoute<Object?>(
                              builder: (_) => const ChatHistoryPage(),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.history,
                          size: 20,
                          color: Color.fromARGB(255, 0, 0, 0),
                        ),
                        label: const Text(
                          'History',
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
                ),
                // 居中内容
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 欢迎文字
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Logo
                              Image.asset(
                                'assets/logo/dinq-black.png',
                                width: 32,
                                height: 32,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.search,
                                    size: 32,
                                    color: Color(0xFF171717),
                                  );
                                },
                              ),
                              const SizedBox(width: 12),
                              // Welcome Text
                              Flexible(
                                child: Text(
                                  userName.isNotEmpty
                                      ? 'Welcome, $userName'
                                      : 'Welcome',
                                  style: const TextStyle(
                                    fontSize: 38,
                                    fontWeight: FontWeight.normal,
                                    color: Color(0xFF171717),
                                    letterSpacing: 0.02,
                                    fontFamily: 'Editor Note',
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          // 搜索框（外层白色背景容器）
                          Center(
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 768),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: SearchBoxWidget(
                                onSearch: _handleSearch,
                                onStop: _handleStop,
                                loading: logic.loading,
                                talentMode: _talentMode,
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
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Prompt Templates - 根据 activeTool 显示/隐藏
                          AnimatedSize(
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
                                  ? const PromptTemplateGridWidget()
                                  : const SizedBox.shrink(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Section 2: Papers 页
          SizedBox(
            height: _screenHeight ?? MediaQuery.of(context).size.height,
            child: RecommendedPapersWidget(
              userId: userId,
              isFullView: true,
              onBack: _scrollToSearch,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSearchBox(AgenticSearchLogic logic) {
    // 底部留出 MainTabBottomView 高度，避免输入框被遮挡
    final bottomInset = ConstantsTool.bottomTabHeight + 32;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      child: Stack(
        children: [
          // 滚动到底部按钮
          if (!_isNearBottom)
            Positioned(
              top: -48,
              left: 0,
              right: 0,
              child: Center(
                child: Material(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    onTap: _scrollToBottom,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.white.withOpacity(0.8),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Color(0xFF5A5A5A),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // 搜索框
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 768),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: SearchBoxWidget(
                onSearch: _handleSearch,
                onStop: _handleStop,
                loading: logic.loading,
                talentMode: _talentMode,
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
    );
  }
}
