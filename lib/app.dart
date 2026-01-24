import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'router/app_router.dart';
import 'stores/card_store.dart';
import 'stores/messages_store.dart';
import 'stores/notifications_store.dart';
import 'stores/search_store.dart';
import 'stores/settings_store.dart';
import 'stores/user_store.dart';
import 'theme/app_theme.dart';

class DinqApp extends StatelessWidget {
  DinqApp({super.key});

  final router = AppRouter.create();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsStore()),
        ChangeNotifierProvider(create: (_) => UserStore()),
        ChangeNotifierProvider(create: (_) => CardStore()),
        ChangeNotifierProvider(create: (_) => MessagesStore()),
        ChangeNotifierProvider(create: (_) => NotificationsStore()),
        ChangeNotifierProvider(create: (_) => SearchStore()),
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
                routerConfig: router,
                theme: AppTheme.lightTheme,
                debugShowCheckedModeBanner: false,
              );
            },
          );
        },
      ),
    );
  }
}
