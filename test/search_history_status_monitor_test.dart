import 'dart:async';

import 'package:dinq_app/models/user_models.dart';
import 'package:dinq_app/services/history_service.dart';
import 'package:dinq_app/stores/chat_history_store.dart';
import 'package:dinq_app/stores/search_store.dart';
import 'package:dinq_app/stores/user_store.dart';
import 'package:dinq_app/widgets/search/history/search_history_status_monitor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _QueuedHistoryService extends HistoryService {
  _QueuedHistoryService(this.responses);

  final List<Map<String, dynamic>> responses;
  int calls = 0;

  @override
  Future<Map<String, dynamic>> getConversations({
    String? keyword,
    int limit = 20,
    int offset = 0,
    String? type,
  }) async {
    final index = calls < responses.length ? calls : responses.length - 1;
    calls += 1;
    return responses[index];
  }
}

class _ControlledHistoryService extends HistoryService {
  final List<Completer<Map<String, dynamic>>> requests = [];
  int activeRequests = 0;
  int maxConcurrentRequests = 0;

  @override
  Future<Map<String, dynamic>> getConversations({
    String? keyword,
    int limit = 20,
    int offset = 0,
    String? type,
  }) {
    final completer = Completer<Map<String, dynamic>>();
    requests.add(completer);
    activeRequests += 1;
    if (activeRequests > maxConcurrentRequests) {
      maxConcurrentRequests = activeRequests;
    }
    return completer.future.whenComplete(() => activeRequests -= 1);
  }
}

Map<String, dynamic> _response(
  String state, {
  String id = 'background-session',
}) {
  return {
    'conversations': [
      {
        'id': id,
        'type': 'discover',
        'title': 'Background search',
        'record_count': state == 'running' ? 0 : 1,
        'created_at': '2026-08-05T08:00:00.000Z',
        'updated_at': state == 'running'
            ? '2026-08-05T08:00:00.000Z'
            : '2026-08-05T08:01:00.000Z',
        'is_running': state == 'running',
        'search_state': state,
      },
    ],
    'total': 1,
  };
}

Map<String, dynamic> _emptyResponse() {
  return {'conversations': <Map<String, dynamic>>[], 'total': 0};
}

UserProfile _userProfile() {
  return UserProfile(
    user: User(id: 'user-1', email: 'user@example.com', name: 'User'),
    userData: UserData(name: 'User', avatarUrl: '', bio: '', domain: ''),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'immediately confirms a newly discovered running search, then polls until completion',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final historyService = _QueuedHistoryService([
        _response('running'),
        _response('running'),
        _response('completed'),
      ]);
      final historyStore = ChatHistoryStore(historyService: historyService);
      final searchStore = SearchStore();
      final userStore = UserStore()..user = _userProfile();
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (context, state) => const SizedBox()),
        ],
      );
      addTearDown(historyStore.dispose);
      addTearDown(searchStore.dispose);
      addTearDown(userStore.dispose);
      addTearDown(router.dispose);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: historyStore),
            ChangeNotifierProvider.value(value: searchStore),
            ChangeNotifierProvider.value(value: userStore),
          ],
          child: MaterialApp(
            home: SearchHistoryStatusMonitor(
              router: router,
              child: const SizedBox(),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(
        historyService.calls,
        2,
        reason: 'Web immediately ticks once when running count changes 0 -> 1',
      );
      expect(
        historyStore.discoverServerSearchState('background-session'),
        'running',
      );

      await tester.pump(const Duration(milliseconds: 2500));
      await tester.pump();

      expect(historyService.calls, 3);
      expect(
        historyStore.discoverServerSearchState('background-session'),
        'completed',
      );

      await tester.pump(const Duration(seconds: 10));
      expect(historyService.calls, 3);
    },
  );

  testWidgets(
    'detach keeps polling when the first history snapshot does not contain the session',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final historyService = _QueuedHistoryService([
        _emptyResponse(),
        _emptyResponse(),
        _response('running'),
        _response('completed'),
      ]);
      final historyStore = ChatHistoryStore(historyService: historyService);
      final searchStore = SearchStore();
      final userStore = UserStore()..user = _userProfile();
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (context, state) => const SizedBox()),
        ],
      );
      addTearDown(historyStore.dispose);
      addTearDown(searchStore.dispose);
      addTearDown(userStore.dispose);
      addTearDown(router.dispose);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: historyStore),
            ChangeNotifierProvider.value(value: searchStore),
            ChangeNotifierProvider.value(value: userStore),
          ],
          child: MaterialApp(
            home: SearchHistoryStatusMonitor(
              router: router,
              child: const SizedBox(),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(historyService.calls, 1);
      expect(historyStore.conversations, isEmpty);

      searchStore.setDeepSearchSessionId('background-session');
      searchStore.setIsSearching(true);
      historyStore.upsertPendingDiscoverSession(
        sessionId: 'background-session',
        title: 'Background search',
      );

      // This mirrors the detach path: foreground SSE ends, but the local
      // placeholder remains until /history confirms the backend session.
      searchStore.setIsSearching(false);
      await tester.pump();
      await tester.pump();

      expect(historyService.calls, 2);
      expect(historyStore.conversations, hasLength(1));
      expect(historyStore.conversations.single.isLocalPending, isTrue);
      expect(
        historyStore.discoverServerSearchState('background-session'),
        isNull,
      );

      await tester.pump(const Duration(milliseconds: 2500));
      await tester.pump();

      expect(
        historyService.calls,
        3,
        reason: 'the unconfirmed pending row must keep status polling alive',
      );
      expect(
        historyStore.discoverServerSearchState('background-session'),
        'running',
      );
      expect(historyStore.conversations.single.isLocalPending, isFalse);

      await tester.pump(const Duration(milliseconds: 2500));
      await tester.pump();
      expect(historyService.calls, 4);
      expect(
        historyStore.discoverServerSearchState('background-session'),
        'completed',
      );

      await tester.pump(const Duration(seconds: 10));
      expect(historyService.calls, 4);
    },
  );

  testWidgets(
    'confirmed running dropped from raw top snapshot stops polling even if the merged row remains',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final historyService = _QueuedHistoryService([
        _emptyResponse(),
        _response('running'),
        _emptyResponse(),
        _response('completed'),
      ]);
      final historyStore = ChatHistoryStore(historyService: historyService);
      final searchStore = SearchStore();
      final userStore = UserStore()..user = _userProfile();
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (context, state) => const SizedBox()),
        ],
      );
      addTearDown(historyStore.dispose);
      addTearDown(searchStore.dispose);
      addTearDown(userStore.dispose);
      addTearDown(router.dispose);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: historyStore),
            ChangeNotifierProvider.value(value: searchStore),
            ChangeNotifierProvider.value(value: userStore),
          ],
          child: MaterialApp(
            home: SearchHistoryStatusMonitor(
              router: router,
              child: const SizedBox(),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(historyService.calls, 1);

      historyStore.upsertPendingDiscoverSession(
        sessionId: 'background-session',
        title: 'Background search',
      );
      await tester.pump();
      await tester.pump();

      expect(historyService.calls, 2);
      expect(historyStore.conversations.single.isLocalPending, isFalse);
      expect(
        historyStore.discoverServerSearchState('background-session'),
        'running',
      );

      await tester.pump(const Duration(milliseconds: 2500));
      await tester.pump();

      expect(historyService.calls, 3);
      expect(historyStore.latestTopConversations, isEmpty);
      expect(
        historyStore.discoverServerSearchState('background-session'),
        'running',
        reason: 'the merged history intentionally keeps rows beyond top 20',
      );

      await tester.pump(const Duration(seconds: 10));
      expect(
        historyService.calls,
        3,
        reason: 'tracking must follow the raw top snapshot, not the stale row',
      );
    },
  );

  testWidgets(
    'an externally loaded running item triggers an immediate refresh',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final historyService = _QueuedHistoryService([
        _emptyResponse(),
        _response('running'),
        _response('completed'),
      ]);
      final historyStore = ChatHistoryStore(historyService: historyService);
      final searchStore = SearchStore();
      final userStore = UserStore()..user = _userProfile();
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (context, state) => const SizedBox()),
        ],
      );
      addTearDown(historyStore.dispose);
      addTearDown(searchStore.dispose);
      addTearDown(userStore.dispose);
      addTearDown(router.dispose);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: historyStore),
            ChangeNotifierProvider.value(value: searchStore),
            ChangeNotifierProvider.value(value: userStore),
          ],
          child: MaterialApp(
            home: SearchHistoryStatusMonitor(
              router: router,
              child: const SizedBox(),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(historyService.calls, 1);

      await historyStore.loadConversations('');
      expect(historyService.calls, 2);
      expect(
        historyStore.discoverServerSearchState('background-session'),
        'running',
      );

      await tester.pump();
      await tester.pump();

      expect(
        historyService.calls,
        3,
        reason: 'the monitor must not wait for the first 2.5 second timer',
      );
      expect(
        historyStore.discoverServerSearchState('background-session'),
        'completed',
      );
    },
  );

  testWidgets('swapping running keys does not create a zero-delay poll chain', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final historyService = _QueuedHistoryService([
      _response('running', id: 'session-a'),
      _response('running', id: 'session-b'),
      _response('completed', id: 'session-b'),
    ]);
    final historyStore = ChatHistoryStore(historyService: historyService);
    final searchStore = SearchStore();
    final userStore = UserStore()..user = _userProfile();
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const SizedBox()),
      ],
    );
    addTearDown(historyStore.dispose);
    addTearDown(searchStore.dispose);
    addTearDown(userStore.dispose);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: historyStore),
          ChangeNotifierProvider.value(value: searchStore),
          ChangeNotifierProvider.value(value: userStore),
        ],
        child: MaterialApp(
          home: SearchHistoryStatusMonitor(
            router: router,
            child: const SizedBox(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(
      historyService.calls,
      2,
      reason: 'A -> B keeps running count at one and must enter the timer',
    );
    expect(historyStore.discoverServerSearchState('session-b'), 'running');

    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pump();
    expect(historyService.calls, 3);
    expect(historyStore.discoverServerSearchState('session-b'), 'completed');
  });

  testWidgets('history filtering cannot hide an unconfirmed pending poll', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final historyService = _QueuedHistoryService([
      _emptyResponse(),
      _emptyResponse(),
      _emptyResponse(),
      _emptyResponse(),
    ]);
    final historyStore = ChatHistoryStore(historyService: historyService);
    final searchStore = SearchStore();
    final userStore = UserStore()..user = _userProfile();
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const SizedBox()),
      ],
    );
    addTearDown(historyStore.dispose);
    addTearDown(searchStore.dispose);
    addTearDown(userStore.dispose);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: historyStore),
          ChangeNotifierProvider.value(value: searchStore),
          ChangeNotifierProvider.value(value: userStore),
        ],
        child: MaterialApp(
          home: SearchHistoryStatusMonitor(
            router: router,
            child: const SizedBox(),
          ),
        ),
      ),
    );
    await tester.pump();

    historyStore.upsertPendingDiscoverSession(
      sessionId: 'background-session',
      title: 'Background search',
    );
    await tester.pump();
    await tester.pump();
    expect(historyService.calls, 2);

    await historyStore.loadConversations('no-match');
    expect(historyService.calls, 3);
    expect(historyStore.conversations, isEmpty);
    expect(
      historyStore.pendingDiscoverRevision('background-session'),
      isNotNull,
    );
    expect(historyStore.pendingDiscoverConversations, hasLength(1));

    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pump();
    expect(
      historyService.calls,
      4,
      reason: 'pending polling must not depend on the filtered visible list',
    );
  });

  testWidgets(
    'current-route local pending keeps polling until server appears',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final historyService = _QueuedHistoryService([
        _emptyResponse(),
        _emptyResponse(),
      ]);
      final historyStore = ChatHistoryStore(historyService: historyService);
      historyStore.upsertPendingDiscoverSession(
        sessionId: 'background-session',
        title: 'Background search',
      );
      final searchStore = SearchStore();
      final userStore = UserStore()..user = _userProfile();
      final router = GoRouter(
        initialLocation: '/search/background-session',
        routes: [
          GoRoute(
            path: '/search/:id',
            builder: (context, state) => const SizedBox(),
          ),
        ],
      );
      addTearDown(historyStore.dispose);
      addTearDown(searchStore.dispose);
      addTearDown(userStore.dispose);
      addTearDown(router.dispose);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: historyStore),
            ChangeNotifierProvider.value(value: searchStore),
            ChangeNotifierProvider.value(value: userStore),
          ],
          child: MaterialApp(
            home: SearchHistoryStatusMonitor(
              router: router,
              child: const SizedBox(),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(historyService.calls, 1);

      await tester.pump(const Duration(milliseconds: 2500));
      await tester.pump();
      expect(historyService.calls, 2);
    },
  );

  testWidgets(
    'detach during an in-flight refresh queues one serial tail poll',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final historyService = _ControlledHistoryService();
      final historyStore = ChatHistoryStore(historyService: historyService);
      final searchStore = SearchStore();
      final userStore = UserStore()..user = _userProfile();
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (context, state) => const SizedBox()),
        ],
      );
      addTearDown(historyStore.dispose);
      addTearDown(searchStore.dispose);
      addTearDown(userStore.dispose);
      addTearDown(router.dispose);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: historyStore),
            ChangeNotifierProvider.value(value: searchStore),
            ChangeNotifierProvider.value(value: userStore),
          ],
          child: MaterialApp(
            home: SearchHistoryStatusMonitor(
              router: router,
              child: const SizedBox(),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(historyService.requests, hasLength(1));

      searchStore.setDeepSearchSessionId('background-session');
      searchStore.setIsSearching(true);
      historyStore.upsertPendingDiscoverSession(
        sessionId: 'background-session',
        title: 'Background search',
      );
      searchStore.setIsSearching(false);
      await tester.pump();
      await tester.pump();

      expect(historyService.requests, hasLength(1));
      expect(historyService.maxConcurrentRequests, 1);

      historyService.requests.first.complete(_emptyResponse());
      await tester.pump();
      await tester.pump();

      expect(historyService.requests, hasLength(2));
      expect(historyService.maxConcurrentRequests, 1);

      historyService.requests[1].complete(_emptyResponse());
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(historyService.requests, hasLength(2));
      expect(historyService.maxConcurrentRequests, 1);
    },
  );

  testWidgets(
    'old completed row does not confirm a newer pending round in the same session',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final completed = ConversationItem.fromJson(
        Map<String, dynamic>.from(
          (_response('completed')['conversations'] as List).single as Map,
        ),
      );
      final historyService = _QueuedHistoryService([
        _response('completed'),
        _response('running'),
        _response('completed'),
      ]);
      final historyStore = ChatHistoryStore(historyService: historyService)
        ..conversations = [completed];
      historyStore.upsertPendingDiscoverSession(
        sessionId: 'background-session',
        title: 'Follow-up round',
      );
      final searchStore = SearchStore();
      final userStore = UserStore()..user = _userProfile();
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (context, state) => const SizedBox()),
        ],
      );
      addTearDown(historyStore.dispose);
      addTearDown(searchStore.dispose);
      addTearDown(userStore.dispose);
      addTearDown(router.dispose);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: historyStore),
            ChangeNotifierProvider.value(value: searchStore),
            ChangeNotifierProvider.value(value: userStore),
          ],
          child: MaterialApp(
            home: SearchHistoryStatusMonitor(
              router: router,
              child: const SizedBox(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(historyService.calls, 1);
      expect(historyStore.conversations.single.isLocalPending, isTrue);

      await tester.pump(const Duration(milliseconds: 2500));
      await tester.pump();
      expect(historyService.calls, 2);
      expect(historyStore.conversations.single.isLocalPending, isFalse);
      expect(
        historyStore.discoverServerSearchState('background-session'),
        'running',
      );

      await tester.pump(const Duration(milliseconds: 2500));
      await tester.pump();
      expect(historyService.calls, 3);
      expect(
        historyStore.discoverServerSearchState('background-session'),
        'completed',
      );
    },
  );
}
