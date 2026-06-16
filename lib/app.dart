import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:provider/provider.dart';

import 'router/app_router.dart';
import 'services/push_service.dart';
import 'stores/card_store.dart';
import 'stores/viewer_card_store.dart';
import 'stores/chat_history_store.dart';
import 'stores/main_store.dart';
import 'stores/messages_store.dart';
import 'stores/notifications_store.dart';
import 'stores/quick_replies_store.dart';
import 'stores/search_store.dart';
import 'stores/shortlist_store.dart';
import 'stores/settings_store.dart';
import 'stores/user_store.dart';
import 'theme/app_theme.dart';
import 'widgets/cards/placeholder/use_placeholders.dart';

class DinqApp extends StatelessWidget {
  DinqApp({super.key}) : _userStore = UserStore() {
    // 推送点击跳转 → 交给 go_router
    PushService.instance.onNavigate = (route) => _router.go(route);
  }

  final UserStore _userStore;
  late final _router = AppRouter.create(_userStore);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsStore()),
        ChangeNotifierProvider.value(value: _userStore),
        ChangeNotifierProvider(create: (_) => CardStore()),
        ChangeNotifierProvider(create: (_) => ViewerCardStore()),
        ChangeNotifierProvider(create: (_) => MessagesStore()),
        ChangeNotifierProvider(create: (_) => NotificationsStore()),
        ChangeNotifierProvider(create: (_) => SearchStore()),
        ChangeNotifierProvider(create: (_) => ShortlistStore()),
        ChangeNotifierProvider(create: (_) => ChatHistoryStore()),
        ChangeNotifierProvider(create: (_) => MainStore()),
        ChangeNotifierProvider(create: (_) => PlaceholderNotifier()),
        ChangeNotifierProvider(create: (_) => QuickRepliesStore()),
      ],
      child: Builder(
        builder: (context) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final settings = context.read<SettingsStore>();
              final isMobile = constraints.maxWidth < 900;
              if (settings.isMobile != isMobile) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  settings.setIsMobile(isMobile);
                });
              }

              return MaterialApp.router(
                title: 'DINQ',
                routerConfig: _router,
                theme: AppTheme.lightTheme,
                debugShowCheckedModeBanner: false,
                builder: EasyLoading.init(),
              );
            },
          );
        },
      ),
    );
  }
}
