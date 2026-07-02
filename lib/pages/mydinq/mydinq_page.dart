import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/user_models.dart';
import '../../services/profile_service.dart';
import '../../stores/card_store.dart';
import '../../stores/main_store.dart';
import '../../theme/dinq_tokens.dart';
import '../../widgets/profile/mydinq_top_bar.dart';
import '../../widgets/profile/share_profile_dialog.dart';
import '../profile/profile_page.dart';
import 'mydinq_resume_content.dart';

enum MyDinqTab { page, resume }

/// 对齐 Web `mydinq/layout.tsx`：顶栏 + Page（编辑）/ Resume（独立页）切换。
class MyDinqPage extends StatefulWidget {
  const MyDinqPage({
    super.key,
    required this.username,
    this.initialTab = MyDinqTab.page,
  });

  final String username;
  final MyDinqTab initialTab;

  @override
  State<MyDinqPage> createState() => _MyDinqPageState();
}

class _MyDinqPageState extends State<MyDinqPage> {
  late MyDinqTab _tab;
  UserData? _userData;
  MainStore? _mainStore;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
    // mounted 守卫：返回时 go('/me') 重置路由栈可能让本页重挂载后立即卸载，
    // 迟到的 hide 回调若在 dispose 的 show 之后执行，会把底部导航永久隐藏。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<MainStore>().hideBottomNavigation();
    });
    _loadUserData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _mainStore = context.read<MainStore>();
  }

  @override
  void dispose() {
    _mainStore?.showBottomNavigation();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await ProfileService().getUserData(widget.username);
      if (!mounted) return;
      setState(() => _userData = userData);
    } catch (_) {}
  }

  void _onTabChanged(bool isPageTab) {
    setState(() => _tab = isPageTab ? MyDinqTab.page : MyDinqTab.resume);
  }

  void _openShare() {
    final userData = _userData;
    if (userData == null) return;
    ShareProfileDialog.show(
      context: context,
      username: widget.username,
      userData: userData,
      cards: context.read<CardStore>().cards,
    );
  }

  void _goBackToMainMyTab() {
    context.read<MainStore>().showBottomNavigation();
    context.go('/me');
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = context.watch<CardStore>().isSaving;
    return Scaffold(
      backgroundColor: DinqTokens.bgPage,
      resizeToAvoidBottomInset: false,
      appBar: MyDinqTopBar(
        context,
        isPageTab: _tab == MyDinqTab.page,
        onTabChanged: _onTabChanged,
        isSaving: isSaving,
        onShare: _openShare,
        onBack: _goBackToMainMyTab,
      ),
      body: IndexedStack(
        index: _tab == MyDinqTab.page ? 0 : 1,
        children: [
          ProfilePage(
            key: ValueKey('mydinq-page-${widget.username}'),
            username: widget.username,
            embeddedInMyDinq: true,
          ),
          const MyDinqResumeContent(),
        ],
      ),
    );
  }
}
