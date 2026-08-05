import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../stores/chat_history_store.dart';
import '../../stores/main_store.dart';
import '../../stores/deep_search_enrich_store.dart';
import '../../stores/search_store.dart';
import '../../stores/settings_store.dart';
import '../../widgets/search/agentic_search_content_widget.dart';
import '../../widgets/search/chat_history_mobile_widget.dart';
import '../../widgets/search/tab_panel_mobile_widget.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key, this.contentOverride});

  /// 仅替换主内容区；路由状态同步、history/tab 面板仍按真实页面运行。
  /// 主要用于对 URL ↔ SearchStore 的竞态做隔离测试。
  @visibleForTesting
  final Widget? contentOverride;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  bool _hasLoggedBuild = false;
  MediaQueryData? _fixedMediaQuery;
  bool _listenersRegistered = false;
  ChatHistoryStore? _chatHistoryStoreForDispose;
  SearchStore? _searchStoreForDispose;
  DeepSearchEnrichStore? _enrichStoreForDispose;
  String? _lastRoutePath;
  int _routeSyncEpoch = 0;

  void _syncBottomNav() {
    if (!mounted) return;
    final mainStore = context.read<MainStore>();
    final chatOpen = context.read<ChatHistoryStore>().isMobileOpen;
    final tabOpen = context.read<SearchStore>().isTabPanelOpen;
    final enrichOpen = context.read<DeepSearchEnrichStore>().isOpen;
    final path = GoRouterState.of(context).uri.path;
    final isSearchDetail = path.startsWith('/search/');
    mainStore.setShowBottomNav(
      !chatOpen && !tabOpen && !enrichOpen && !isSearchDetail,
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fixedMediaQuery ??= MediaQuery.of(context);
    if (!_listenersRegistered) {
      _listenersRegistered = true;
      final ch = context.read<ChatHistoryStore>();
      final ss = context.read<SearchStore>();
      final es = context.read<DeepSearchEnrichStore>();
      ch.addListener(_syncBottomNav);
      ss.addListener(_syncBottomNav);
      es.addListener(_syncBottomNav);
      _chatHistoryStoreForDispose = ch;
      _searchStoreForDispose = ss;
      _enrichStoreForDispose = es;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncBottomNav();
      });
    }
    _syncRouteState();
  }

  void _syncRouteState() {
    final state = GoRouterState.of(context);
    final currentPath = state.uri.path;
    if (currentPath == _lastRoutePath) return;
    _lastRoutePath = currentPath;
    final routeSyncEpoch = ++_routeSyncEpoch;

    final segments = state.uri.pathSegments;
    // `/` 与 `/search` 都是 App 的 Search 首页。根路由不能直接跳过，
    // 否则从详情返回首页后旧会话仍会被 history 当作 active。
    if (segments.isNotEmpty && segments.first != 'search') return;

    const toolRouteMap = <String, String>{
      'advisor': 'find-advisor',
      'citation': 'who-cites-me',
      'analyze': 'analysis',
    };

    final searchStore = context.read<SearchStore>();
    final chatHistoryStore = context.read<ChatHistoryStore>();
    final router = GoRouter.of(context);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      bool isCurrentRouteSync() =>
          mounted &&
          routeSyncEpoch == _routeSyncEpoch &&
          router.routeInformationProvider.value.uri.path == currentPath;
      if (!isCurrentRouteSync()) return;

      // / | /search: clear detail context.
      if (segments.isEmpty || segments.length == 1) {
        chatHistoryStore.setActiveConversationId(null);
        searchStore.clearExtraType();
        searchStore.setCurrentConversationId(null);
        searchStore.setDeepSearchSessionId(null);
        searchStore.clearPendingConversation();
        searchStore.clearPendingDeepSearch();
        searchStore.setLoadingConversation(false);
        return;
      }

      // /search/advisor | /search/citation | /search/analyze: tool route only.
      if (segments.length == 2 && toolRouteMap.containsKey(segments[1])) {
        chatHistoryStore.setActiveConversationId(null);
        searchStore.clearExtraType();
        searchStore.setCurrentConversationId(null);
        searchStore.clearPendingConversation();
        searchStore.clearPendingDeepSearch();
        searchStore.setDeepSearchSessionId(null);
        searchStore.setLoadingConversation(false);
        searchStore.setActiveTool(toolRouteMap[segments[1]]);
        return;
      }

      String? type;
      String? idText;
      if (segments.length >= 3) {
        type = segments[1];
        idText = segments[2];
      } else {
        idText = segments[1];
      }
      if (idText.isEmpty) {
        searchStore.setCurrentConversationId(null);
        searchStore.setLoadingConversation(false);
        return;
      }

      final conversationId = int.tryParse(idText);
      if (conversationId == null && segments.length == 2) {
        // Web 的 sessionId 与 rounds 同在全局 Zustand；App 的 rounds 则在
        // 当前 AgenticChat logic 内。因此这里既接受尚未消费的同 UUID
        // handoff，也接受当前挂载 chat view 实际持有该 UUID，不能只比较
        // 全局 deepSearchSessionId（页面重挂载时它可能是旧值）。
        final sessionMatchesRoute = searchStore.deepSearchSessionId == idText;
        final hasMatchingHandoff =
            sessionMatchesRoute && searchStore.pendingDeepSearch != null;
        final alreadyLoadedInCurrentView =
            sessionMatchesRoute &&
            searchStore.activeAgenticViewHasSession(idText);
        if (hasMatchingHandoff || alreadyLoadedInCurrentView) {
          chatHistoryStore.setActiveConversationId(
            idText,
            type: ChatHistoryStore.searchConversationType,
          );
          searchStore.clearExtraType();
          searchStore.setCurrentConversationId(null);
          searchStore.clearPendingConversation();
          searchStore.setLoadingConversation(false);
          return;
        }

        // pending 属于其他 UUID 时不能在当前路由消费，否则旧 query 会在
        // 被点击的历史 session 中启动。
        searchStore.clearPendingDeepSearch();

        // /search/:uuid — 历史 discover 会话，走 discover/sessions API 恢复
        const convType = 'discover';
        chatHistoryStore.setActiveConversationId(idText, type: convType);
        searchStore.clearExtraType();
        searchStore.setCurrentConversationId(null);
        searchStore.setDeepSearchSessionId(idText);
        searchStore.clearPendingConversation();
        searchStore.setLoadingConversation(true);

        try {
          final detail = await chatHistoryStore.fetchConversationDetail(
            idText,
            convType,
          );
          if (!isCurrentRouteSync()) return;
          if (detail != null) {
            searchStore.setPendingConversation(
              _mergeDiscoverDetail(detail, idText, chatHistoryStore),
            );
          }
        } finally {
          if (isCurrentRouteSync()) {
            searchStore.setLoadingConversation(false);
          }
        }
        return;
      }

      if (type != null && type.isNotEmpty) {
        searchStore.setExtraType(type);
      } else {
        searchStore.clearExtraType();
      }

      final convType = type ?? 'discover';
      chatHistoryStore.setActiveConversationId(idText, type: convType);
      searchStore.setCurrentConversationId(conversationId);
      searchStore.clearPendingConversation();
      searchStore.setLoadingConversation(true);

      try {
        final detail = await chatHistoryStore.fetchConversationDetail(
          idText,
          convType,
        );
        if (!isCurrentRouteSync()) return;
        if (detail != null) {
          final pending = convType == 'discover'
              ? _mergeDiscoverDetail(detail, idText, chatHistoryStore)
              : {...detail, if (!detail.containsKey('type')) 'type': convType};
          searchStore.setPendingConversation(pending);
        }
      } finally {
        if (isCurrentRouteSync()) {
          searchStore.setLoadingConversation(false);
        }
      }
    });
  }

  /// 详情接口缺字段时用列表快照补齐；不把历史恢复误标为 local pending。
  Map<String, dynamic> _mergeDiscoverDetail(
    Map<String, dynamic> detail,
    String idText,
    ChatHistoryStore chatHistoryStore,
  ) {
    const convType = 'discover';
    final listItem = chatHistoryStore.findDiscoverById(idText);
    final merged = <String, dynamic>{
      ...detail,
      if (!detail.containsKey('type')) 'type': convType,
    };

    if (listItem != null) {
      if (!merged.containsKey('is_running')) {
        merged['is_running'] = listItem.isRunning;
      }
      if (!merged.containsKey('search_state') && listItem.searchState != null) {
        merged['search_state'] = listItem.searchState;
      }
      final title = merged['title']?.toString().trim() ?? '';
      if (title.isEmpty && listItem.title.trim().isNotEmpty) {
        merged['title'] = listItem.title;
      }
    }

    return merged;
  }

  @override
  void dispose() {
    _chatHistoryStoreForDispose?.removeListener(_syncBottomNav);
    _searchStoreForDispose?.removeListener(_syncBottomNav);
    _enrichStoreForDispose?.removeListener(_syncBottomNav);
    super.dispose();
  }

  bool _isMainTabHomeRoute(GoRouterState state) {
    final segments = state.uri.pathSegments;
    return segments.isEmpty ||
        (segments.length == 1 &&
            (segments.first == 'search' || segments.first == 'me'));
  }

  bool _isEmbeddedInMainTab(BuildContext context) {
    return _isMainTabHomeRoute(GoRouterState.of(context));
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasLoggedBuild) {
      _hasLoggedBuild = true;
    }
    return Consumer3<SearchStore, ChatHistoryStore, SettingsStore>(
      builder: (context, searchStore, chatHistoryStore, settingsStore, _) {
        final isMobileHeaderVisible = settingsStore.isMobileHeaderVisible;
        final embeddedInMainTab = _isEmbeddedInMainTab(context);
        return _buildMobileLayout(
          context,
          searchStore,
          chatHistoryStore,
          isMobileHeaderVisible,
          embeddedInMainTab: embeddedInMainTab,
        );
      },
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    SearchStore searchStore,
    ChatHistoryStore chatHistoryStore,
    bool isMobileHeaderVisible, {
    required bool embeddedInMainTab,
  }) {
    final mq = MediaQuery.of(context);
    // 主搜索输入保持原有键盘上移；历史侧栏搜索只弹键盘，不推动侧栏内容。
    final keyboardHeight = chatHistoryStore.isMobileOpen
        ? 0.0
        : mq.viewInsets.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      resizeToAvoidBottomInset: false,
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: ClipRect(
          child: Transform.translate(
            offset: Offset(0, -keyboardHeight),
            child: SizedBox(
              height: mq.size.height,
              width: double.infinity,
              child: Padding(
                // 键盘顶起后 SafeArea 会随内容上移，补回等高的 top padding 避免与状态栏重叠
                padding: EdgeInsets.only(top: keyboardHeight),
                child: SafeArea(
                  bottom: false,
                  child: Stack(
                    children: [
                      // 主聊天区域
                      widget.contentOverride ??
                          AgenticSearchContentWidget(
                            embeddedInMainTab: embeddedInMainTab,
                          ),

                      // 聊天历史移动端面板（左侧滑入）
                      ChatHistoryMobileWidget(
                        isOpen: chatHistoryStore.isMobileOpen,
                        onClose: () => chatHistoryStore.setMobileOpen(false),
                      ),

                      // Tab 用户信息面板（底部滑入，与 history 同方式）
                      TabPanelMobileWidget(
                        isOpen: searchStore.isTabPanelOpen,
                        onClose: () => searchStore.setTabPanelOpen(false),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

@Deprecated('Use SearchPage instead.')
class DiscoverPage extends SearchPage {
  const DiscoverPage({super.key});
}
