import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:provider/provider.dart';

import 'router/app_router.dart';
import 'stores/card_store.dart';
import 'stores/chat_history_store.dart';
import 'stores/messages_store.dart';
import 'stores/notifications_store.dart';
import 'stores/search_store.dart';
import 'stores/settings_store.dart';
import 'stores/user_store.dart';
import 'theme/app_theme.dart';
import 'widgets/cards/placeholder/use_placeholders.dart';

class DinqApp extends StatelessWidget {
  DinqApp({super.key}) : _userStore = UserStore();

  final UserStore _userStore;
  late final _router = AppRouter.create(_userStore);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsStore()),
        ChangeNotifierProvider.value(value: _userStore),
        ChangeNotifierProvider(create: (_) => CardStore()),
        ChangeNotifierProvider(create: (_) => MessagesStore()),
        ChangeNotifierProvider(create: (_) => NotificationsStore()),
        ChangeNotifierProvider(create: (_) => SearchStore()),
        ChangeNotifierProvider(create: (_) => ChatHistoryStore()),
        ChangeNotifierProvider(create: (_) => PlaceholderNotifier()),
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
