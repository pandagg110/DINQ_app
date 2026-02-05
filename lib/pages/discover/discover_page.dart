import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../stores/chat_history_store.dart';
import '../../stores/search_store.dart';
import '../../stores/settings_store.dart';
import '../../widgets/discover/agentic_chat_widget.dart';
import '../../widgets/discover/chat_history_mobile_widget.dart';
import '../../widgets/discover/tab_bar_widget.dart';
import '../../widgets/discover/user_info_widget.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  bool _isMobileSheetOpen = false;
  int _prevTabClickVersion = 0;
  bool _hasLoggedBuild = false;
  MediaQueryData? _fixedMediaQuery;

  @override
  void initState() {
    super.initState();
    print('🔍 DiscoverPage: initState - 进入 Discover 页面');
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 固定 MediaQuery，避免键盘影响布局
    _fixedMediaQuery ??= MediaQuery.of(context);
    if (!_hasLoggedBuild) {
      print('🔍 DiscoverPage: didChangeDependencies - Discover 页面依赖已更新');
    }
  }


  @override
  Widget build(BuildContext context) {
    if (!_hasLoggedBuild) {
      print('🔍 DiscoverPage: build - 正在构建 Discover 页面');
      _hasLoggedBuild = true;
    }
    return Consumer3<SearchStore, ChatHistoryStore, SettingsStore>(
      builder: (context, searchStore, chatHistoryStore, settingsStore, _) {
        final isMobileHeaderVisible = settingsStore.isMobileHeaderVisible;
        
        // 初始化 prevTabClickVersion
        if (_prevTabClickVersion == 0) {
          _prevTabClickVersion = searchStore.tabClickVersion;
        }
        
        // 监听 tabClickVersion 变化，展开 BottomSheet
        if (searchStore.tabClickVersion != _prevTabClickVersion) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _isMobileSheetOpen = true;
                _prevTabClickVersion = searchStore.tabClickVersion;
              });
            }
          });
        }

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
    final activeTab = searchStore.getActiveTab();
    final hasOpenTabs = searchStore.openTabs.isNotEmpty;

    // 使用固定的 MediaQuery，完全移除键盘影响
    final fixedQuery = _fixedMediaQuery ?? MediaQuery.of(context);
    final mediaQueryWithoutInsets = fixedQuery.copyWith(
      viewInsets: EdgeInsets.zero,
      // 保持原始 padding，确保布局不变
      padding: fixedQuery.padding,
    );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: MediaQuery(
        data: mediaQueryWithoutInsets,
        child: SizedBox(
          height: fixedQuery.size.height,
          width: double.infinity,
          child: Container(
            padding: EdgeInsets.only(top: isMobileHeaderVisible ? 56 : 0),
            child: Stack(
              children: [
                // 主聊天区域
                const AgenticChatWidget(),

                // BottomSheet - 用户信息面板
                if (hasOpenTabs && _isMobileSheetOpen)
                  _buildMobileBottomSheet(context, searchStore, activeTab),

                // 聊天历史移动端面板
                ChatHistoryMobileWidget(
                  isOpen: chatHistoryStore.isMobileOpen,
                  onClose: () => chatHistoryStore.setMobileOpen(false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileBottomSheet(
    BuildContext context,
    SearchStore searchStore,
    SearchTabData? activeTab,
  ) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // 标题栏
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFE5E5E5))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        activeTab?.candidate['name']?.toString() ?? 'User Profile',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF171717),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _isMobileSheetOpen = false;
                        });
                      },
                    ),
                  ],
                ),
              ),
              // TabBar
              const TabBarWidget(),
              // UserInfo Content
              if (activeTab != null)
                Expanded(
                  child: UserInfoWidget(
                    tabData: activeTab,
                    onClose: () {
                      if (searchStore.activeTabId != null) {
                        searchStore.closeTab(searchStore.activeTabId!);
                      }
                    },
                    resetKey: searchStore.activeTabId,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
