import 'package:flutter/material.dart';
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
  const MyDinqPage({super.key, required this.username});

  final String username;

  @override
  State<MyDinqPage> createState() => _MyDinqPageState();
}

class _MyDinqPageState extends State<MyDinqPage> {
  MyDinqTab _tab = MyDinqTab.page;
  UserData? _userData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MainStore>().hideBottomNavigation();
    });
    _loadUserData();
  }

  @override
  void dispose() {
    context.read<MainStore>().showBottomNavigation();
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

  @override
  Widget build(BuildContext context) {
    final isSaving = context.watch<CardStore>().isSaving;
    return Scaffold(
      backgroundColor: DinqTokens.bgPage,
      appBar: MyDinqTopBar(
        context,
        isPageTab: _tab == MyDinqTab.page,
        onTabChanged: _onTabChanged,
        isSaving: isSaving,
        onShare: _openShare,
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
