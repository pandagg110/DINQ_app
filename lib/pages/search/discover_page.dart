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
  const SearchPage({super.key});

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
      _syncBottomNav();
    }
    _syncRouteState();
  }

  void _syncRouteState() {
    final state = GoRouterState.of(context);
    final currentPath = state.uri.path;
    if (currentPath == _lastRoutePath) return;
    _lastRoutePath = currentPath;

    final segments = state.uri.pathSegments;
    if (segments.isEmpty || segments.first != 'search') return;

    const toolRouteMap = <String, String>{
      'advisor': 'find-advisor',
      'citation': 'who-cites-me',
      'analyze': 'analysis',
    };

    final searchStore = context.read<SearchStore>();
    final chatHistoryStore = context.read<ChatHistoryStore>();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      // /search: clear detail context.
      if (segments.length == 1) {
        searchStore.clearExtraType();
        searchStore.setCurrentConversationId(null);
        searchStore.setDeepSearchSessionId(null);
        return;
      }

      // /search/advisor | /search/citation | /search/analyze: tool route only.
      if (segments.length == 2 && toolRouteMap.containsKey(segments[1])) {
        searchStore.clearExtraType();
        searchStore.setCurrentConversationId(null);
        searchStore.clearPendingConversation();
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
        return;
      }

      final conversationId = int.tryParse(idText);
      if (conversationId == null && segments.length == 2) {
        if (searchStore.pendingDeepSearch != null) {
          searchStore.clearExtraType();
          searchStore.setCurrentConversationId(null);
          searchStore.setDeepSearchSessionId(idText);
          return;
        }

        // /search/:uuid — 历史 discover 会话，走 discover/sessions API 恢复
        const convType = 'discover';
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
          if (!mounted) return;
          if (detail != null) {
            chatHistoryStore.setActiveConversationId(idText, type: convType);
            searchStore.setPendingConversation({
              ...detail,
              if (!detail.containsKey('type')) 'type': convType,
            });
          }
        } finally {
          if (mounted) {
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
      searchStore.setCurrentConversationId(conversationId);
      searchStore.clearPendingConversation();
      searchStore.setLoadingConversation(true);

      try {
        final detail = await chatHistoryStore.fetchConversationDetail(
          idText,
          convType,
        );
        if (!mounted) return;
        if (detail != null) {
          chatHistoryStore.setActiveConversationId(idText, type: convType);
          searchStore.setPendingConversation({
            ...detail,
            if (!detail.containsKey('type')) 'type': convType,
          });
        }
      } finally {
        if (mounted) {
          searchStore.setLoadingConversation(false);
        }
      }
    });
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
