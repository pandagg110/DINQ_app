import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../stores/user_store.dart';
import '../mydinq/mydinq_page.dart';

class AdminMyDinqPage extends StatelessWidget {
  const AdminMyDinqPage({super.key, this.initialTab = MyDinqTab.page});

  final MyDinqTab initialTab;

  @override
  Widget build(BuildContext context) {
    final userStore = context.watch<UserStore>();
    final domain = userStore.myFlow?.domain ?? '';
    if (domain.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Complete your DINQ generation first.')),
      );
    }
    return MyDinqPage(username: domain, initialTab: initialTab);
  }
}
