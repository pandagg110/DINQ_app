import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../constants/dinq_page_prompt.dart';
import '../../stores/user_store.dart';
import '../../utils/dinq_page_gate.dart';
import '../../widgets/common/confirm_dialog.dart';
import '../mydinq/mydinq_page.dart';

/// 对齐 Web `AuthenticatedLayout` + `MyDinqClient`：进入 My DINQ 时若无 Page 则弹窗确认。
class AdminMyDinqPage extends StatefulWidget {
  const AdminMyDinqPage({super.key, this.initialTab = MyDinqTab.page});

  final MyDinqTab initialTab;

  @override
  State<AdminMyDinqPage> createState() => _AdminMyDinqPageState();
}

class _AdminMyDinqPageState extends State<AdminMyDinqPage> {
  bool _prompted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybePromptForDinqPage());
  }

  Future<void> _maybePromptForDinqPage() async {
    if (!mounted || _prompted) return;

    final userStore = context.read<UserStore>();
    if (!userStore.isInitialized) return;
    // 用户数据没加载成功（如网络失败）时无法判断是否已建 page，
    // 不弹「创建」确认框，避免误导已建卡用户
    if (userStore.user == null) return;

    final flow = userStore.myFlow;
    final userData = userStore.user?.userData;
    if (hasExistingDinqPage(flow, userData)) return;

    _prompted = true;
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: DinqPagePrompt.title,
      content: DinqPagePrompt.message,
      okText: DinqPagePrompt.confirmText,
      cancelText: DinqPagePrompt.cancelText,
    );

    if (!mounted) return;
    if (confirmed == true) {
      final next = Uri.encodeComponent('/admin/mydinq');
      context.go('/generation?next=$next');
      return;
    }
    context.go('/search');
  }

  @override
  Widget build(BuildContext context) {
    final userStore = context.watch<UserStore>();
    final flow = userStore.myFlow;
    final userData = userStore.user?.userData;
    final domain = resolveDinqDomain(flow, userData);

    if (domain == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F6F2),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return MyDinqPage(username: domain, initialTab: widget.initialTab);
  }
}
