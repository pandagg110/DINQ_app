import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../stores/search_store.dart';
import '../../stores/settings_store.dart';
import '../../stores/user_store.dart';
import 'prompt_template_grid_widget.dart';
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
  const AgenticChatWidget({super.key});

  @override
  State<AgenticChatWidget> createState() => _AgenticChatWidgetState();
}

class _AgenticChatWidgetState extends State<AgenticChatWidget> {
  // UI 状态
  String _talentMode = 'global'; // 'global' or 'dinq'
  String? _activeTool; // ToolType | null
  bool _isNearBottom = true;
  bool _inPapersView = false;
  bool _headerMounted = false;
  
  // 滚动相关
  final ScrollController _scrollController = ScrollController();
  final ScrollController _initialScrollController = ScrollController();
  final GlobalKey _messagesEndKey = GlobalKey();
  
  // 消息组（待实现完整逻辑）
  List<dynamic> _messageGroups = [];
  bool _loading = false;
  bool _advisorLoading = false;
  // int _resetVersion = 0; // TODO: 实现重置逻辑时使用
  
  // bool _initialQueryProcessed = false; // TODO: 实现 URL 参数处理时使用
  
  // 固定屏幕高度（避免键盘影响布局）
  double? _screenHeight;

  @override
  void initState() {
    super.initState();
    // 延迟显示 header
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _headerMounted = true;
        });
      }
    });
    
    // 监听滚动
    _scrollController.addListener(_handleScroll);
    _initialScrollController.addListener(_handleInitialScroll);
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 只在第一次获取屏幕高度，之后不再更新
    _screenHeight ??= MediaQuery.of(context).size.height;
  }

  @override
  void dispose() {
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

  // 处理搜索
  void _handleSearch({required String query, bool simple = false}) {
    if (query.trim().isEmpty) return;
    
    // TODO: 实现付费墙检查
    // if (!consumeCredit(1)) return;
    
    setState(() {
      _isNearBottom = true;
      _loading = true;
    });
    
    // TODO: 实现搜索逻辑
    // executeSearch({ query, mode: simple ? "fast" : "research" });
    
    // 临时：模拟搜索
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _loading = false;
          // _messageGroups = [...]; // 添加消息组
        });
      }
    });
    
    // 滚动到底部
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollToBottom();
    });
  }

  // 处理 DINQ 搜索提交
  void _handleDinqSearchSubmit(String query) {
    if (query.trim().isEmpty) return;
    
    setState(() {
      _isNearBottom = true;
    });
    
    // TODO: 实现 DINQ 搜索逻辑
    // executeDinqSearch({ query });
    
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollToBottom();
    });
  }

  // 处理 Advisor 搜索
  void _handleAdvisorSearch(AdvisorFormData data) {
    // TODO: 实现付费墙检查
    // if (!consumeCredit(1)) return;
    
    setState(() {
      _isNearBottom = true;
      _advisorLoading = true;
    });
    
    // TODO: 实现 Advisor 搜索逻辑
    // executeAdvisorSearch(data);
    
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollToBottom();
    });
  }

  // 处理停止
  void _handleStop() {
    // TODO: 实现停止逻辑
    setState(() {
      _loading = false;
      _advisorLoading = false;
    });
  }

  // 处理候选人点击
  // void _handleCandidateClick(Map<String, dynamic> candidate, int index, int groupId) {
  //   // TODO: 实现 openTab 逻辑
  //   // final searchStore = context.read<SearchStore>();
  //   // searchStore.openTabWithClick(candidate, index: index, groupId: groupId);
  // }

  @override
  Widget build(BuildContext context) {
    return Consumer3<SearchStore, SettingsStore, UserStore>(
      builder: (context, searchStore, settingsStore, userStore, _) {
        final isMobile = settingsStore.isMobile;
        final user = userStore.user;
        final userName = user?.userData.name.isNotEmpty == true
            ? user!.userData.name
            : (user?.user.name.isNotEmpty == true ? user!.user.name : '');
        // final userId = user?.userData.userId; // TODO: 如果需要 userId
        
        final hasMessages = _messageGroups.isNotEmpty;
        final showSkeleton = searchStore.isLoadingConversation && !hasMessages;
        final bgColor = (hasMessages || showSkeleton) 
            ? Colors.white 
            : const Color(0xFFFDFDFD);
        
        // 获取固定屏幕高度（不受键盘影响）
        final screenHeight = _screenHeight ?? MediaQuery.of(context).size.height;
        final headerHeight = isMobile ? 0.0 : 44.0;
        final availableHeight = screenHeight - headerHeight;

        return MediaQuery.removeViewInsets(
          removeBottom: true,
          context: context,
          child: Container(
            color: bgColor,
            height: availableHeight,
            child: Column(
              children: [
              // Header - 移动端不需要
              if (!isMobile)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Color(0xFFE5E5E5))),
                    color: Color(0xFFFDFDFD),
                  ),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: _headerMounted ? 1.0 : 0.0,
                    child: AnimatedSlide(
                      duration: const Duration(milliseconds: 300),
                      offset: _headerMounted ? Offset.zero : const Offset(0, -1),
                      child: Row(
                        children: [
                          const Text(
                            'Discover',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF171717),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // 骨架屏 - 加载历史会话时显示
              if (showSkeleton)
                Expanded(
                  child: _buildConversationSkeleton(),
                ),

              // 消息滚动区域
              if (hasMessages && !showSkeleton)
                Expanded(
                  child: _buildMessagesArea(),
                ),

              // 初始状态 - 双页 snap 滚动
              if (!hasMessages && !showSkeleton)
                Expanded(
                  child: _buildInitialState(userName),
                ),

              // SearchBox - 在有消息或骨架屏时固定底部
              if (hasMessages || showSkeleton)
                _buildBottomSearchBox(),
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

  Widget _buildMessagesArea() {
    return Stack(
      children: [
        SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            children: [
              // TODO: 实现 MessageGroupView
              // for (var group in _messageGroups)
              //   MessageGroupView(...)
              
              // 占位：显示消息组
              Container(
                key: _messagesEndKey,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 80),
                child: const Text(
                  'Messages will appear here',
                  style: TextStyle(color: Color(0xFF9CA3AF)),
                ),
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

  Widget _buildInitialState(String userName) {
    return SingleChildScrollView(
      controller: _initialScrollController,
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // Section 1: 搜索页
          SizedBox(
            height: (_screenHeight ?? MediaQuery.of(context).size.height) * 0.8,
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
                            userName.isNotEmpty ? 'Welcome, $userName' : 'Welcome',
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
                        loading: _loading,
                        talentMode: _talentMode,
                        onTalentModeChange: (mode) {
                          setState(() {
                            _talentMode = mode;
                          });
                        },
                        onDinqSearchSubmit: _handleDinqSearchSubmit,
                        onAdvisorSearch: _handleAdvisorSearch,
                        advisorLoading: _advisorLoading,
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
                      duration: Duration(milliseconds: _activeTool != null ? 200 : 400),
                      curve: Curves.easeOut,
                      child: AnimatedOpacity(
                        duration: Duration(milliseconds: _activeTool != null ? 150 : 300),
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
          
          // Section 2: Papers 页（待实现 RecommendedPapers）
          SizedBox(
            height: _screenHeight ?? MediaQuery.of(context).size.height,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Recommended Papers',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF171717),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _scrollToSearch,
                    child: const Text('Back to Search'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSearchBox() {
    return Container(
      padding: const EdgeInsets.all(24),
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
              loading: _loading,
              talentMode: _talentMode,
              onTalentModeChange: (mode) {
                setState(() {
                  _talentMode = mode;
                });
              },
              onDinqSearchSubmit: _handleDinqSearchSubmit,
              onAdvisorSearch: _handleAdvisorSearch,
              advisorLoading: _advisorLoading,
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
