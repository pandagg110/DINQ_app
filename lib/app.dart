import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:provider/provider.dart';

import 'router/app_router.dart';
import 'services/push_service.dart';
import 'services/apple_iap_service.dart';
import 'services/google_play_iap_service.dart';
import 'stores/card_store.dart';
import 'stores/viewer_card_store.dart';
import 'stores/chat_history_store.dart';
import 'stores/main_store.dart';
import 'stores/messages_store.dart';
import 'stores/notifications_store.dart';
import 'stores/deep_search_enrich_store.dart';
import 'stores/privacy_consent_store.dart';
import 'stores/quick_replies_store.dart';
import 'stores/resume_store.dart';
import 'stores/search_store.dart';
import 'stores/shortlist_store.dart';
import 'stores/settings_store.dart';
import 'stores/user_store.dart';
import 'theme/app_theme.dart';
import 'widgets/account/privacy_consent_gate.dart';
import 'widgets/app_update/app_update_gate.dart';
import 'widgets/cards/placeholder/use_placeholders.dart';
import 'widgets/search/history/search_history_status_monitor.dart';

class DinqApp extends StatelessWidget {
  DinqApp({
    super.key,
    required UserStore userStore,
    this.showFirstLaunchSplash = false,
  }) : _userStore = userStore {
    // 推送点击跳转 → 交给 go_router
    PushService.instance.onNavigate = (route) => _router.go(route);
    AppleIapService.instance.onSubscriptionChanged =
        _userStore.refreshSubscription;
    AppleIapService.instance.setUserIdProvider(() => _userStore.user?.user.id);
    unawaited(AppleIapService.instance.retryPendingTransactions());
    GooglePlayIapService.instance.onSubscriptionChanged =
        _userStore.refreshSubscription;
    GooglePlayIapService.instance.setUserIdProvider(
      () => _userStore.user?.user.id,
    );
    unawaited(GooglePlayIapService.instance.retryPendingTransactions());
  }

  final UserStore _userStore;
  final bool showFirstLaunchSplash;
  late final _router = AppRouter.create(
    _userStore,
    showFirstLaunchSplash: showFirstLaunchSplash,
  );

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
        ChangeNotifierProvider(create: (_) => ResumeStore()),
        ChangeNotifierProvider(create: (_) => DeepSearchEnrichStore()),
        ChangeNotifierProvider(create: (_) => PrivacyConsentStore()),
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

              final easyLoadingBuilder = EasyLoading.init();
              return MaterialApp.router(
                title: 'DINQ',
                routerConfig: _router,
                theme: AppTheme.lightTheme,
                debugShowCheckedModeBanner: false,
                builder: (context, child) {
                  // 路由/键盘变化后重新施加系统栏样式，避免被覆盖回默认黑底导航栏
                  return AnnotatedRegion<SystemUiOverlayStyle>(
                    value: AppTheme.pageSystemUiOverlayStyle,
                    child: ColoredBox(
                      color: AppTheme.brandPage,
                      child: easyLoadingBuilder(
                        context,
                        // 全局 privacy consent 弹窗（对齐 Web），覆盖所有路由
                        SearchHistoryStatusMonitor(
                          router: _router,
                          child: AppUpdateGate(
                            child: PrivacyConsentGate(
                              router: _router,
                              child: child ?? const SizedBox.shrink(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
