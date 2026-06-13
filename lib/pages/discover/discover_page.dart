import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../stores/chat_history_store.dart';
import '../../stores/main_store.dart';
import '../../stores/search_store.dart';
import '../../stores/settings_store.dart';
import '../../widgets/search_bak/agentic_chat_widget.dart';
import '../../widgets/search_bak/chat_history_mobile_widget.dart';
import '../../widgets/search_bak/tab_panel_mobile_widget.dart';

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
  String? _lastRoutePath;

  void _syncBottomNav() {
    if (!mounted) return;
    final mainStore = context.read<MainStore>();
    final chatOpen = context.read<ChatHistoryStore>().isMobileOpen;
    final tabOpen = context.read<SearchStore>().isTabPanelOpen;
    mainStore.setShowBottomNav(!chatOpen && !tabOpen);
  }

  @override
  void initState() {
    super.initState();
    print('🔍 SearchPage: initState - 进入 Search 页面');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fixedMediaQuery ??= MediaQuery.of(context);
    if (!_hasLoggedBuild) {
      print('🔍 SearchPage: didChangeDependencies - Search 页面依赖已更新');
    }
    if (!_listenersRegistered) {
      _listenersRegistered = true;
      final ch = context.read<ChatHistoryStore>();
      final ss = context.read<SearchStore>();
      ch.addListener(_syncBottomNav);
      ss.addListener(_syncBottomNav);
      _chatHistoryStoreForDispose = ch;
      _searchStoreForDispose = ss;
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

    final searchStore = context.read<SearchStore>();
    final chatHistoryStore = context.read<ChatHistoryStore>();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      // /search: clear detail context.
      if (segments.length == 1) {
        searchStore.clearExtraType();
        searchStore.setCurrentConversationId(null);
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

      if (type != null && type.isNotEmpty) {
        searchStore.setExtraType(type);
      } else {
        searchStore.clearExtraType();
      }

      final convType = type ?? 'discover';
      final conversationId = int.tryParse(idText);
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasLoggedBuild) {
      print('🔍 SearchPage: build - 正在构建 Search 页面');
      _hasLoggedBuild = true;
    }
    return Consumer3<SearchStore, ChatHistoryStore, SettingsStore>(
      builder: (context, searchStore, chatHistoryStore, settingsStore, _) {
        final isMobileHeaderVisible = settingsStore.isMobileHeaderVisible;
        final pathSegments = GoRouterState.of(context).uri.pathSegments;
        final isSearchDetail = pathSegments.isNotEmpty &&
            pathSegments.first == 'search' &&
            pathSegments.length > 1;
        final showBackHome = isSearchDetail ||
            (pathSegments.length == 1 &&
                pathSegments.first == 'search' &&
                searchStore.activeTool != null);
        return _buildMobileLayout(
          context,
          searchStore,
          chatHistoryStore,
          isMobileHeaderVisible,
          showBackHome,
        );
      },
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    SearchStore searchStore,
    ChatHistoryStore chatHistoryStore,
    bool isMobileHeaderVisible,
    bool showBackHome,
  ) {
    final mq = MediaQuery.of(context);
    // 不修改内容高度：Scaffold 不 resize，用 Transform.translate 把整块内容顶上去
    final keyboardHeight = mq.viewInsets.bottom;

    return Scaffold(
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
              child: Container(
                padding: EdgeInsets.only(top: isMobileHeaderVisible ? 56 : 0),
                child: Stack(
                  children: [
                // 主聊天区域
                AgenticChatWidget(showBackHome: showBackHome),

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
    );
  }
}

@Deprecated('Use SearchPage instead.')
class DiscoverPage extends SearchPage {
  const DiscoverPage({super.key});
}
