import 'package:dinq_app/models/user_models.dart';
import 'package:dinq_app/services/subscription_pricing_navigation.dart';
import 'package:dinq_app/stores/user_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('cross-channel subscription stays on the current page', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final userStore = UserStore();
    await userStore.ready;
    userStore.subscription = _subscription(channel: 'google_play');
    final router = _router();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: userStore,
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.tap(find.text('Upgrade'));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Pricing page'), findsNothing);
    expect(find.text('Subscription managed elsewhere'), findsOneWidget);
  });

  testWidgets('free users can open the pricing page', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final userStore = UserStore();
    await userStore.ready;
    userStore.subscription = _subscription(plan: 'free', channel: null);
    final router = _router();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: userStore,
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.tap(find.text('Upgrade'));
    await tester.pumpAndSettle();

    expect(find.text('Pricing page'), findsOneWidget);
  });
}

GoRouter _router() => GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => Scaffold(
        body: Column(
          children: [
            const Text('Home'),
            TextButton(
              onPressed: () => openSubscriptionPricing(context),
              child: const Text('Upgrade'),
            ),
          ],
        ),
      ),
    ),
    GoRoute(
      path: '/pricing',
      builder: (context, state) => const Scaffold(body: Text('Pricing page')),
    ),
  ],
);

Subscription _subscription({String plan = 'basic_monthly', String? channel}) =>
    Subscription(
      plan: plan,
      status: 'active',
      creditsBalance: 0,
      monthlyCredits: 0,
      cancelAtPeriodEnd: false,
      channel: channel,
    );
