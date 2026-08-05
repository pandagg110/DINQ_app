import 'dart:async';

import 'package:dinq_app/pages/search/discover_page.dart';
import 'package:dinq_app/services/history_service.dart';
import 'package:dinq_app/stores/chat_history_store.dart';
import 'package:dinq_app/stores/deep_search_enrich_store.dart';
import 'package:dinq_app/stores/main_store.dart';
import 'package:dinq_app/stores/search_store.dart';
import 'package:dinq_app/stores/settings_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _DetailHistoryService extends HistoryService {
  _DetailHistoryService(this.onDetail);

  final Future<Map<String, dynamic>> Function(String type, Object id) onDetail;
  int detailCalls = 0;

  @override
  Future<Map<String, dynamic>> getConversationDetail(String type, Object id) {
    detailCalls += 1;
    return onDetail(type, id);
  }
}

class _SearchPageHarness {
  _SearchPageHarness({required this.router, required this.stores});

  final GoRouter router;
  final List<ChangeNotifier> stores;

  void dispose() {
    router.dispose();
    for (final store in stores) {
      store.dispose();
    }
  }
}

class _PendingConsumerProbe extends StatefulWidget {
  const _PendingConsumerProbe({required this.onConsumed});

  final void Function(String? sessionId, String submissionId) onConsumed;

  @override
  State<_PendingConsumerProbe> createState() => _PendingConsumerProbeState();
}

class _PendingConsumerProbeState extends State<_PendingConsumerProbe> {
  bool _scheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final store = context.read<SearchStore>();
      final pending = store.pendingDeepSearch;
      if (pending == null) return;
      widget.onConsumed(store.deepSearchSessionId, pending.submissionId);
      store.clearPendingDeepSearch();
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _ActiveSessionProbe extends StatefulWidget {
  const _ActiveSessionProbe(this.sessionId);

  final String sessionId;

  @override
  State<_ActiveSessionProbe> createState() => _ActiveSessionProbeState();
}

class _ActiveSessionProbeState extends State<_ActiveSessionProbe> {
  final Object _owner = Object();
  SearchStore? _store;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final store = context.read<SearchStore>();
    if (identical(_store, store)) return;
    _store?.unregisterActiveAgenticView(_owner);
    _store = store;
    store.registerActiveAgenticView(_owner, () => widget.sessionId);
  }

  @override
  void dispose() {
    _store?.unregisterActiveAgenticView(_owner);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

Future<_SearchPageHarness> _pumpSearchPage(
  WidgetTester tester, {
  required String initialLocation,
  required SearchStore searchStore,
  required ChatHistoryStore historyStore,
  Widget content = const SizedBox(key: ValueKey('search-content')),
}) async {
  final mainStore = MainStore();
  final enrichStore = DeepSearchEnrichStore();
  final settingsStore = SettingsStore();
  Page<void> searchPage(GoRouterState state) => CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: const Duration(seconds: 1),
    reverseTransitionDuration: const Duration(seconds: 1),
    child: SearchPage(contentOverride: content),
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(opacity: animation, child: child),
  );
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: '/', pageBuilder: (context, state) => searchPage(state)),
      GoRoute(
        path: '/search',
        pageBuilder: (context, state) => searchPage(state),
      ),
      GoRoute(
        path: '/search/:id',
        pageBuilder: (context, state) => searchPage(state),
      ),
    ],
  );

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: mainStore),
        ChangeNotifierProvider.value(value: enrichStore),
        ChangeNotifierProvider.value(value: settingsStore),
        ChangeNotifierProvider.value(value: searchStore),
        ChangeNotifierProvider.value(value: historyStore),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pump();
  await tester.pump();

  return _SearchPageHarness(
    router: router,
    stores: [mainStore, enrichStore, settingsStore, searchStore, historyStore],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'matching UUID handoff is consumed without a history detail request',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final service = _DetailHistoryService(
        (type, id) async => <String, dynamic>{'id': id, 'type': type},
      );
      final searchStore = SearchStore();
      final historyStore = ChatHistoryStore(historyService: service);
      final consumed = <(String?, String)>[];
      searchStore.setDeepSearchSessionId('session-a');
      searchStore.setPendingDeepSearch(
        const PendingDeepSearchRequest(
          submissionId: 'submission-a',
          query: 'Query for session A',
        ),
      );

      final harness = await _pumpSearchPage(
        tester,
        initialLocation: '/search/session-a',
        searchStore: searchStore,
        historyStore: historyStore,
        content: _PendingConsumerProbe(
          onConsumed: (sessionId, submissionId) {
            consumed.add((sessionId, submissionId));
          },
        ),
      );
      addTearDown(harness.dispose);

      expect(service.detailCalls, 0);
      expect(consumed, [('session-a', 'submission-a')]);
      expect(searchStore.pendingDeepSearch, isNull);
      expect(searchStore.deepSearchSessionId, 'session-a');
      expect(searchStore.isLoadingConversation, isFalse);
      expect(historyStore.activeConversationKey, 'discover-session-a');
    },
  );

  testWidgets(
    'stale global session id restores when the current chat view has no rounds',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final service = _DetailHistoryService(
        (type, id) async => <String, dynamic>{
          'id': id,
          'session_id': id,
          'type': type,
          'title': 'Restored session',
        },
      );
      final searchStore = SearchStore()..setDeepSearchSessionId('session-a');
      final historyStore = ChatHistoryStore(historyService: service);

      final harness = await _pumpSearchPage(
        tester,
        initialLocation: '/search/session-a',
        searchStore: searchStore,
        historyStore: historyStore,
      );
      addTearDown(harness.dispose);

      expect(service.detailCalls, 1);
      expect(searchStore.pendingConversation?['session_id'], 'session-a');
      expect(searchStore.isLoadingConversation, isFalse);
    },
  );

  testWidgets(
    'an active chat view with the same UUID skips duplicate restore',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final service = _DetailHistoryService(
        (type, id) async => <String, dynamic>{'id': id, 'type': type},
      );
      final searchStore = SearchStore()..setDeepSearchSessionId('session-a');
      final historyStore = ChatHistoryStore(historyService: service);

      final harness = await _pumpSearchPage(
        tester,
        initialLocation: '/search/session-a',
        searchStore: searchStore,
        historyStore: historyStore,
        content: const _ActiveSessionProbe('session-a'),
      );
      addTearDown(harness.dispose);

      expect(service.detailCalls, 0);
      expect(searchStore.isLoadingConversation, isFalse);
    },
  );

  testWidgets(
    'pending query for another UUID is discarded before restoring history route',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final service = _DetailHistoryService(
        (type, id) async => <String, dynamic>{
          'id': id,
          'session_id': id,
          'type': type,
          'title': 'Restored session',
        },
      );
      final searchStore = SearchStore();
      final historyStore = ChatHistoryStore(historyService: service);
      final consumed = <(String?, String)>[];
      searchStore.setDeepSearchSessionId('session-a');
      searchStore.setPendingDeepSearch(
        const PendingDeepSearchRequest(
          submissionId: 'submission-a',
          query: 'Query for session A',
        ),
      );

      final harness = await _pumpSearchPage(
        tester,
        initialLocation: '/search/session-b',
        searchStore: searchStore,
        historyStore: historyStore,
        content: _PendingConsumerProbe(
          onConsumed: (sessionId, submissionId) {
            consumed.add((sessionId, submissionId));
          },
        ),
      );
      addTearDown(harness.dispose);

      expect(service.detailCalls, 1);
      expect(consumed, isEmpty);
      expect(searchStore.pendingDeepSearch, isNull);
      expect(searchStore.deepSearchSessionId, 'session-b');
      expect(searchStore.pendingConversation?['session_id'], 'session-b');
      expect(searchStore.isLoadingConversation, isFalse);
      expect(historyStore.activeConversationKey, 'discover-session-b');
    },
  );

  testWidgets(
    'root search alias clears the previously active history session',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final service = _DetailHistoryService(
        (type, id) async => <String, dynamic>{
          'id': id,
          'session_id': id,
          'type': type,
          'title': 'Session A',
          'search_state': 'running',
        },
      );
      final searchStore = SearchStore();
      final historyStore = ChatHistoryStore(historyService: service);

      final harness = await _pumpSearchPage(
        tester,
        initialLocation: '/search/session-a',
        searchStore: searchStore,
        historyStore: historyStore,
      );
      addTearDown(harness.dispose);

      expect(historyStore.activeConversationKey, 'discover-session-a');
      expect(searchStore.deepSearchSessionId, 'session-a');

      harness.router.go('/');
      await tester.pump();
      await tester.pump();

      expect(historyStore.activeConversationKey, isNull);
      expect(searchStore.deepSearchSessionId, isNull);
      expect(searchStore.pendingConversation, isNull);
      expect(searchStore.isLoadingConversation, isFalse);
    },
  );

  testWidgets(
    'late detail from a still-mounted old route cannot overwrite new route',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final responses = <String, Completer<Map<String, dynamic>>>{
        'session-a': Completer<Map<String, dynamic>>(),
        'session-b': Completer<Map<String, dynamic>>(),
      };
      final service = _DetailHistoryService(
        (type, id) => responses[id.toString()]!.future,
      );
      final searchStore = SearchStore();
      final historyStore = ChatHistoryStore(historyService: service);

      final harness = await _pumpSearchPage(
        tester,
        initialLocation: '/search/session-b',
        searchStore: searchStore,
        historyStore: historyStore,
      );
      addTearDown(harness.dispose);
      expect(service.detailCalls, 1);

      harness.router.go('/search/session-a');
      await tester.pump();
      await tester.pump();
      expect(service.detailCalls, 2);

      responses['session-a']!.complete({
        'id': 'session-a',
        'session_id': 'session-a',
        'type': 'discover',
        'title': 'Session A',
      });
      await tester.pump();
      await tester.pump();
      expect(searchStore.pendingConversation?['session_id'], 'session-a');
      expect(searchStore.deepSearchSessionId, 'session-a');

      responses['session-b']!.complete({
        'id': 'session-b',
        'session_id': 'session-b',
        'type': 'discover',
        'title': 'Session B',
      });
      await tester.pump();
      await tester.pump();

      expect(searchStore.pendingConversation?['session_id'], 'session-a');
      expect(searchStore.deepSearchSessionId, 'session-a');
      expect(searchStore.isLoadingConversation, isFalse);
    },
  );
}
