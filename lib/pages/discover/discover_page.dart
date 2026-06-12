import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../stores/chat_history_store.dart';
import '../../stores/main_store.dart';
import '../../stores/search_store.dart';
import '../../stores/settings_store.dart';
import '../../widgets/search/agentic_chat_widget.dart';
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
        return _buildMobileLayout(
          context,
          searchStore,
          chatHistoryStore,
          isMobileHeaderVisible,
        );
      },
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    SearchStore searchStore,
    ChatHistoryStore chatHistoryStore,
    bool isMobileHeaderVisible,
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
                const AgenticChatWidget(),

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
